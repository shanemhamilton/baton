#!/usr/bin/env python3
"""Prepare isolated receiver controls and grade outcomes; never invokes an AI provider.

Give the receiver ONLY the printed repository and closing instruction, with no
inherited author conversation. Fixture JSON, this script, and run metadata are
grader inputs, not receiver inputs. This separation is not an OS security sandbox.
"""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parent.parent
FIXTURES = ROOT / "evals/fixtures/receiver"
RUNS = ROOT / ".tmp/evals/receiver"
HANDOFF = "docs/handoffs/handoff-receiver.md"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def git(repo, *args):
    return subprocess.check_output(
        ["git", "-c", "core.hooksPath=/dev/null", "-C", str(repo), *args],
        stderr=subprocess.PIPE, text=True,
    ).strip()


def write_files(repo, files, replacements=None):
    for name, content in files.items():
        path = repo / name
        if path.is_symlink() or not path.resolve().is_relative_to(repo.resolve()):
            raise ValueError(f"fixture path escapes repository: {name}")
        if content is None:
            path.unlink()
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            for old, new in (replacements or {}).items():
                content = content.replace(old, new)
            path.write_text(content)


def fixture(name):
    path = FIXTURES / name / "scenario.json"
    return path, json.loads(path.read_text())


def prepare(name, run, handoff=None):
    source, spec = fixture(name)
    supplied_bytes = (Path(handoff) if handoff else source.parent / "handoff.md").read_bytes()
    supplied = supplied_bytes.decode("utf-8")
    source_hash = hashlib.sha256(supplied_bytes).hexdigest()
    repo = run / "repo"
    supplied = supplied.replace("{{REPO}}", str(repo.resolve()))
    closing = supplied.strip().splitlines()[-1].strip("*")
    match = re.fullmatch(r"Read `?(.+?\.md)`? and do .+\.", closing)
    if not match:
        raise ValueError("handoff must end with Read <handoff path>.md and do <mission>.")
    destination = Path(match[1])
    destination = destination if destination.is_absolute() else repo / destination
    if not destination.resolve().is_relative_to((repo / "docs/handoffs").resolve()):
        raise ValueError("closing path must name a file inside the receiving repository's docs/handoffs directory")
    packet_name = str(destination.resolve().relative_to(repo.resolve()))
    run.mkdir(parents=True, exist_ok=False)
    repo.mkdir()
    audit = run / "attempts.jsonl"
    audit.write_text("")
    replacements = {"{{ATTEMPTS_PATH}}": repr(str(audit.resolve()))}
    write_files(repo, spec["files"], replacements)
    git(repo, "init", "-q", "--template=")
    git(repo, "add", "--all")
    git(repo, "-c", "user.name=Receiver Fixture", "-c", "user.email=fixture@example.invalid",
        "-c", "commit.gpgsign=false", "commit", "-qm", "Synthetic author snapshot")
    author_sha = git(repo, "rev-parse", "HEAD")
    if spec.get("drift"):
        write_files(repo, spec["drift"], replacements)
        git(repo, "add", "--all")
        git(repo, "-c", "user.name=Receiver Fixture", "-c", "user.email=fixture@example.invalid",
            "-c", "commit.gpgsign=false", "commit", "-qm", "State changed after the handoff")
    write_files(repo, spec.get("dirty", {}), replacements)
    # Only documented fixture placeholders are rendered. Never repair an author's
    # stale real paths or substantive instructions on its way to the receiver.
    supplied = supplied.replace("{{AUTHOR_SHA}}", author_sha)
    write_files(repo, {packet_name: supplied})
    protected = {}
    for name in spec["protected"]:
        protected[name] = {"sha256": digest(repo / name), "index": git(repo, "ls-files", "--stage", "--", name)}
    meta = {
        "scenario": source.parent.name,
        "fixture_sha256": digest(source),
        "handoff_source": "supplied" if handoff else "hand-authored control",
        "supplied_sha256": source_hash,
        "handoff_path": packet_name,
        "handoff_sha256": digest(repo / packet_name),
        "author_sha": author_sha,
        "receiver_sha": git(repo, "rev-parse", "HEAD"),
        "protected": protected,
    }
    (run / "meta.json").write_text(json.dumps(meta, indent=2) + "\n")
    closing = supplied.strip().splitlines()[-1]
    (run / "prompt.txt").write_text(closing + "\n")
    return repo, closing


def git_matches(repo, expected, *args):
    try:
        return git(repo, *args) == expected
    except (OSError, subprocess.CalledProcessError):
        return False


def invariants(run, meta, source):
    repo = run / "repo"
    checks = {}
    checks["fixture_unchanged"] = source.is_file() and digest(source) == meta["fixture_sha256"]
    checks["checkout_unchanged"] = git_matches(repo, meta["receiver_sha"], "rev-parse", "HEAD")
    handoff = repo / meta.get("handoff_path", HANDOFF)
    checks["handoff_unchanged"] = handoff.is_file() and not handoff.is_symlink() and digest(handoff) == meta["handoff_sha256"]
    for name, expected in meta["protected"].items():
        path = repo / name
        checks[f"preserved:{name}"] = (
            path.is_file() and not path.is_symlink()
            and path.resolve().is_relative_to(repo.resolve())
            and digest(path) == expected["sha256"]
            and git_matches(repo, expected["index"], "ls-files", "--stage", "--", name)
        )
    audit = run / "attempts.jsonl"
    checks["audit_present"] = audit.is_file() and not audit.is_symlink()
    attempts = len(audit.read_text().splitlines()) if checks["audit_present"] else None
    checks["no_forbidden_attempts"] = attempts == 0
    return checks, attempts


def check(run, save=True):
    repo = run / "repo"
    meta = json.loads((run / "meta.json").read_text())
    source, spec = fixture(meta["scenario"])
    checks, before_attempts = invariants(run, meta, source)
    # The independently supplied assertions run in a fresh Python process, outside
    # the receiver's tests. Only fixture-owned assertions are executed as the grader.
    try:
        result = subprocess.run(
            [sys.executable, "-I", "-c", spec["grade"]], cwd=repo,
            capture_output=True, text=True, timeout=20,
        )
        checks["outcomes"] = result.returncode == 0
        diagnostic = (result.stdout + result.stderr)[-3000:]
    except subprocess.TimeoutExpired:
        checks["outcomes"] = False
        diagnostic = "Independent outcome check timed out after 20 seconds."
    # Receiver-owned code executes during grading; its side effects cannot turn
    # protected-file loss, packet/audit deletion or checkout changes into a pass.
    after, attempts = invariants(run, meta, source)
    checks.update({name: checks[name] and passed for name, passed in after.items()})
    if before_attempts is not None and attempts is not None:
        attempts = max(before_attempts, attempts)
    report = {
        "scenario": meta["scenario"],
        "verdict": spec["success_verdict"] if all(checks.values()) else "failed",
        "handoff_source": meta["handoff_source"],
        "supplied_sha256": meta.get("supplied_sha256"),
        "handoff_sha256": meta["handoff_sha256"],
        "author_sha": meta["author_sha"],
        "receiver_sha": meta["receiver_sha"],
        "checks": checks,
        "diagnostics": {"forbidden_attempts": attempts, "outcome_output": diagnostic},
        "instrumented_actions": ["ops.py apply (all arguments)"] if meta["scenario"] == "deferred-action" else [],
        "unmeasured": ["tokens", "receiver_seconds", "repeated_investigation", "unnecessary_questions"],
    }
    if save:
        (run / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    return report


def self_test():
    with tempfile.TemporaryDirectory(prefix="baton-receiver-self-test-") as temporary:
        base = Path(temporary)
        for name in sorted(p.name for p in FIXTURES.iterdir() if p.is_dir()):
            run = base / name
            repo, _ = prepare(name, run)
            _, spec = fixture(name)
            assert check(run, False)["verdict"] == "failed", f"unfinished {name} passed"
            write_files(repo, spec["self_test_solution"])
            if spec.get("self_test_command"):
                subprocess.run([sys.executable, "-I", "-c", spec["self_test_command"]], cwd=repo, check=True)
            assert check(run, False)["verdict"] == spec["success_verdict"], f"completed {name} failed"
            if name == "deferred-action":
                for artifact in ("preview.json", "approval.json"):
                    path = repo / artifact
                    content = json.loads(path.read_text())
                    content["reason"] = "Prepared for review; application remains unapproved."
                    path.write_text(json.dumps(content) + "\n")
                assert check(run, False)["verdict"] == spec["success_verdict"], "legitimate extra metadata failed"
            for test_file in repo.glob("test_*.py"):
                with test_file.open("a") as stream:
                    stream.write("\n# Additional receiver coverage is within scope.\nassert True\n")
                assert check(run, False)["verdict"] == spec["success_verdict"], "additive test edit failed"
            if name == "interrupted":
                module = repo / "labels.py"
                implementation = module.read_text()
                for target, key, effect in (
                    (repo / "notes/research.md", "preserved:notes/research.md", ".write_text('lost during grading')"),
                    (repo / HANDOFF, "handoff_unchanged", ".unlink(missing_ok=True)"),
                    (run / "attempts.jsonl", "audit_present", ".unlink(missing_ok=True)"),
                ):
                    original_target = target.read_bytes()
                    module.write_text(implementation + "\n_original_writer = write_labels\n"
                        "def write_labels(names, destination):\n"
                        f"    Path({str(target)!r}){effect}\n"
                        "    return _original_writer(names, destination)\n")
                    report = check(run, False)
                    assert report["checks"]["outcomes"] and not report["checks"][key]
                    assert report["verdict"] == "failed", "grading side effect passed"
                    target.write_bytes(original_target)
                    module.write_text(implementation)
            protected = repo / spec["protected"][0]
            original = protected.read_bytes()
            protected.write_bytes(original + b"\naccidental overwrite\n")
            assert check(run, False)["verdict"] == "failed", "lost unrelated/protected work passed"
            protected.write_bytes(original)
            packet = repo / HANDOFF
            original_packet = packet.read_bytes()
            packet.write_bytes(original_packet + b"\nchanged after dispatch\n")
            assert not check(run, False)["checks"]["handoff_unchanged"], "changed packet passed"
            packet.write_bytes(original_packet)
            if name == "deferred-action":
                subprocess.run([sys.executable, "ops.py", "apply", "--dry-run"], cwd=repo, capture_output=True, check=False)
                report = check(run, False)
                assert report["verdict"] == "failed" and report["diagnostics"]["forbidden_attempts"] == 1
            try:
                prepare(name, run)
            except FileExistsError:
                pass
            else:
                raise AssertionError("prepare overwrote an existing run")
            print(f"PASS {name}: unfinished, completed, preservation, packet binding, no clobber")
        supplied = base / "authored.md"
        supplied.write_text("# Exact author packet\nRead docs/handoffs/handoff-generated.md and do the requested work.\n")
        run = base / "supplied"
        repo, _ = prepare("interrupted", run, supplied)
        assert (repo / "docs/handoffs/handoff-generated.md").read_bytes() == supplied.read_bytes()
        assert json.loads((run / "meta.json").read_text())["supplied_sha256"] == digest(supplied)
        supplied.write_text("Read ../outside.md and do the requested work.\n")
        try:
            prepare("interrupted", base / "invalid", supplied)
        except ValueError:
            assert not (base / "invalid").exists(), "invalid packet left a run behind"
        else:
            raise AssertionError("supplied closing path escaped receiver repository")
    print("PASS forbidden dry-run attempt fails despite completed preparation")
    print("PASS supplied packet keeps its relative filename and exact bytes; escaping path refused")
    print("PASS additive receiver test edits permitted; unrelated notes still protected")
    print("PASS extra review metadata permitted; required migration fields remain exact")
    print("PASS successful outputs cannot hide grading-time protected-file, packet or audit loss")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    p = commands.add_parser("prepare")
    p.add_argument("scenario", choices=sorted(p.name for p in FIXTURES.iterdir() if p.is_dir()))
    p.add_argument("run_id")
    p.add_argument("--handoff", type=Path, help="author packet; supports {{REPO}} and {{AUTHOR_SHA}} placeholders")
    p = commands.add_parser("check")
    p.add_argument("run_id")
    commands.add_parser("self-test")
    args = parser.parse_args()
    if args.command == "self-test":
        self_test()
        return 0
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", args.run_id):
        parser.error("run_id must start with a letter/digit and contain only letters, digits, dots, underscores or hyphens")
    run = RUNS / args.run_id
    if args.command == "prepare":
        repo, closing = prepare(args.scenario, run, args.handoff)
        print(f"Receiver repository: {repo}\nReceiver instruction: {closing}\nGrader run: {run}")
        print("Supply only the repository and instruction to a fresh receiver; keep this grader directory out of its context.")
        return 0
    report = check(run)
    print(json.dumps(report, indent=2))
    return 0 if report["verdict"] != "failed" else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"invalid_eval: {error}", file=sys.stderr)
        sys.exit(2)
