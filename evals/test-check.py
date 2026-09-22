#!/usr/bin/env python3
"""Dependency-free synthetic regression checks; never calls a model/provider."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import shlex
import subprocess
import tempfile
import unittest

EVALS = Path(__file__).resolve().parent


def handoff(path, start="inspect `src.py`", truth="Unknown"):
    receiver_start = f"Read {path} and do the continuation mission through its stop conditions, starting by inspecting the source."
    return f"""# Continuation: finish the recovery
## 0. Launch Contract
- **Continuation record:** `{path}`
- **Continuation policy:** `AGENTS.md` permits this local continuation record.
- **Task identity:** synthetic-recovery
- **Continuation lifecycle:** ACTIVE
- **Continuation lineage:** none
- **Revalidation triggers:** Re-read checkout state before changing source.
- **Document depth:** COMPACT
- **Human decision state:** none needed
- **Objective:** Recover the interrupted change and verify it.
- **Cleanup authority:** No destructive cleanup authorized
- **Worktree lifecycle action:** NONE
- **Start by:** {start}
- **Receiver start:** {receiver_start}
- **Hard stops and authority:** Local inspection only; request approval before publication.
## 2. Live Truth
| Claim | Class | Evidence | Refresh |
|---|---|---|---|
| Earlier outcome is not retained | {truth} | Context unavailable; inspect the local artifact | Read source |
## 6. Continuation Mission
- **Continue through:** Reconcile the source and record remaining work.
- **Keep going until:** The local state is documented or an actual authority gate is reached.
{receiver_start}
"""


class Checks(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="baton checks ")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.file = self.root / "docs/handoffs/handoff-new.md"
        self.file.parent.mkdir(parents=True)
        (self.root / "src.py").write_text("value = 1\n")
        (self.root / "AGENTS.md").write_text("Synthetic repository policy.\n")
        self.valid = handoff(self.file)
        self.file.write_text(self.valid)

    def check(self, text=None, expected=0):
        if text is not None:
            self.file.write_text(text)
        result = subprocess.run(["bash", str(EVALS / "check.sh"), "--root", str(self.root), str(self.file)],
                                cwd="/", capture_output=True, text=True)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        skill = (EVALS.parent / "skills/baton/SKILL.md").read_text()
        inline = skill.split("### Step 8", 1)[1].split("```bash\n", 1)[1].split("\n```", 1)[0]
        inline = re.sub(r"r='<[^']*>'", "r=" + shlex.quote(str(self.root)), inline, count=1)
        inline = re.sub(r"f='<[^']*>'", "f=" + shlex.quote(str(self.file)), inline, count=1)
        installed = subprocess.run(["bash", "-c", inline], cwd="/", capture_output=True, text=True)
        self.assertEqual(installed.returncode, expected, "inline block: " + installed.stdout + installed.stderr)
        return result.stdout

    def check_checker(self, text=None, expected=0):
        """Exercise checker-only Git rules that the portable inline block cannot inspect."""
        if text is not None:
            self.file.write_text(text)
        result = subprocess.run(["bash", str(EVALS / "check.sh"), "--root", str(self.root), str(self.file)],
                                cwd="/", capture_output=True, text=True)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result.stdout

    def git(self, *args):
        return subprocess.run(["git", "-C", str(self.root), *args], check=True,
                              capture_output=True, text=True).stdout.strip()

    def git_record(self):
        self.git("init", "-q")
        self.git("config", "user.name", "Baton Tests")
        self.git("config", "user.email", "baton-tests@example.invalid")
        self.git("add", "src.py", "AGENTS.md")
        self.git("commit", "-qm", "initial state")
        self.git("remote", "add", "origin", "https://example.invalid/baton.git")

        # The continuation record remains untracked on purpose. Its path appears
        # in status, but later edits do not change the recorded porcelain digest.
        self.file.write_text(handoff(self.file))
        physical_root = self.root.resolve()
        common_raw = self.git("rev-parse", "--git-common-dir")
        common = (self.root / common_raw).resolve() if not Path(common_raw).is_absolute() else Path(common_raw).resolve()
        head = self.git("rev-parse", "HEAD")
        branch = self.git("symbolic-ref", "--short", "HEAD")
        upstream = self.git("status", "--short", "--branch", "--untracked-files=all").splitlines()[0]
        porcelain_v2 = self.git("status", "--porcelain=v2", "--untracked-files=all")
        # subprocess text mode strips the final newline; restore Git's line-based
        # stream form so this matches the checker's pipeline exactly.
        dirty_digest = hashlib.sha256((porcelain_v2 + "\n").encode()).hexdigest()
        identity = self.git("remote", "get-url", "origin")
        checkout = f"""- **Repository identity:** {identity}
- **Repository root:** `{physical_root}`
- **Execution worktree:** `{physical_root}`
- **Git common directory:** `{common}`
- **Author HEAD:** {head}
- **Author branch:** {branch}
- **Truth ref:** HEAD @ {head}
- **Upstream state:** {upstream}
- **Dirty-state digest:** sha256:{dirty_digest}
- **Checkout observed at:** 2026-09-21T20:30:00Z
- **Checkout refresh command:** `git rev-parse --show-toplevel && git status --short --branch && git status --porcelain=v2 --untracked-files=all`
- **Checkout mismatch disposition:** Perform read-only reconciliation before writing.
"""
        record = self.file.read_text().replace("- **Cleanup authority:**", checkout + "- **Cleanup authority:**")
        self.file.write_text(record)
        return record

    def test_non_git_unknown_and_relative_closing(self):
        self.check()
        self.check(self.valid.replace(str(self.file), "docs/handoffs/handoff-new.md"))

    def test_content_empty_fields(self):
        for label in ("Human decision state", "Objective", "Start by", "Keep going until"):
            with self.subTest(label=label):
                lines = [f"- **{label}:**" if line.startswith(f"- **{label}:**") else line
                         for line in self.valid.splitlines()]
                self.check("\n".join(lines) + "\n", expected=1)
        self.check(self.valid.replace("COMPACT", "TBD"), expected=1)
        self.check(self.valid.replace("Recover the interrupted change and verify it.", "<objective>"), expected=1)
        self.check(self.valid.replace("- **Objective:** Recover the interrupted change and verify it.\n", "").replace(
            "## 2. Live Truth", "## 1. Outcome and Done\n- [ ] <acceptance criterion>\n## 2. Live Truth"), expected=1)

    def test_empty_truth_and_invalid_class(self):
        row = "| Earlier outcome is not retained | Unknown | Context unavailable; inspect the local artifact | Read source |"
        for replacement in ("", row + "\n| claim | Unknown | | later |", "| <claim> | Unknown | <evidence> | later |",
                            "| claim | | evidence | later |", "| claim | Observed/Derived | evidence | later |"):
            with self.subTest(replacement=replacement):
                self.check(self.valid.replace(row, replacement), expected=1)

    def test_draft_and_missing_path(self):
        self.check(self.valid.replace("## 0.", "**Status:** DRAFT\n## 0."), expected=1)
        self.check(self.valid.replace("`src.py`", "`src/missing.py`"), expected=1)
        self.check(self.valid.replace("`src.py`", "`docs/handoffs/missing.md`"), expected=1)
        self.file.unlink()
        self.check(expected=1)

    def test_nested_launch_section_paths_stay_checked(self):
        self.check(self.valid.replace("- **Start by:** inspect `src.py`", "### First action\n- **Start by:** inspect `src/missing.py`"), expected=1)

    def test_same_basename_other_target(self):
        other = self.root / "other" / self.file.name
        other.parent.mkdir()
        other.write_text(self.valid)
        self.check(self.valid.replace(str(self.file), str(other)), expected=1)

    def test_secret_warning_does_not_echo_value(self):
        secret = "ghp_" + "a" * 30
        output = self.check(self.valid.replace("## 6.", f"Example credential shape: {secret}\n## 6."))
        self.assertIn("WARN C9", output)
        self.assertNotIn(secret, output)

    def test_start_in_original_continuation_section(self):
        line = "- **Start by:** inspect `src.py`\n"
        self.check(self.valid.replace(line, "").replace("## 6. Continuation Mission\n",
                                                       "## 6. Continuation Mission\n" + line))

    def test_git_tuple_rejects_false_repository_root(self):
        record = self.git_record()
        self.check_checker(record)
        false_root = self.root.resolve() / "not-the-checkout"
        self.check_checker(record.replace(f"**Repository root:** `{self.root.resolve()}`", f"**Repository root:** `{false_root}`"), expected=1)

    def test_git_rejects_symlinked_continuation_record(self):
        record = self.git_record()
        external = self.root.parent / "external-continuation.md"
        external.write_text(record)
        self.file.unlink()
        self.file.symlink_to(external)
        output = self.check_checker(expected=1)
        self.assertIn("must not be a symlink", output)

    def test_git_rejects_source_only_cross_checkout_transfer(self):
        record = self.git_record()
        destination = Path(tempfile.mkdtemp(prefix="baton receiver "))
        self.addCleanup(shutil.rmtree, destination)
        receiver_copy = destination / "docs/handoffs/receiver-copy.md"
        receiver_copy.parent.mkdir(parents=True)
        receiver_copy.write_text(record)
        transfer = f"""- **Transfer source root:** `{self.root}`
- **Transfer destination root:** `{destination}`
- **Handoff source:** `{self.file}`
- **Handoff destination:** `{receiver_copy}`
- **Transfer availability:** Unknown — no receiver readback yet
- **Receiver readback SHA-256:** Unknown — destination copy is absent
"""
        output = self.check_checker(record.replace("- **Worktree lifecycle action:**", transfer + "- **Worktree lifecycle action:"), expected=1)
        self.assertIn("cross-checkout transfer", output)

    def test_git_accepts_verified_cross_checkout_transfer(self):
        record = self.git_record()
        destination = Path(tempfile.mkdtemp(prefix="baton receiver "))
        self.addCleanup(shutil.rmtree, destination)
        receiver_copy = destination / "docs/handoffs/receiver-copy.md"
        receiver_copy.parent.mkdir(parents=True)
        transfer = f"""- **Transfer source root:** `{self.root}`
- **Transfer destination root:** `{destination}`
- **Handoff source:** `{self.file}`
- **Handoff destination:** `{receiver_copy}`
- **Transfer availability:** verified receiver readback
- **Receiver readback SHA-256:** sha256:<attested-content-hash>
"""
        record = record.replace("- **Worktree lifecycle action:**", transfer + "- **Worktree lifecycle action:")
        canonical = re.sub(
            r"^([ \t>*-]*\*{0,2}Receiver readback SHA-256:\*{0,2}[ \t]*).*",
            r"\1<attested-content-hash>", record, flags=re.MULTILINE,
        )
        readback = hashlib.sha256(canonical.encode()).hexdigest()
        record = record.replace("sha256:<attested-content-hash>", f"sha256:{readback}")
        self.file.write_text(record)
        receiver_copy.write_text(record)
        self.check_checker(record)

    def test_git_rejects_cleanup_without_authority_or_ledgers(self):
        record = self.git_record().replace("**Worktree lifecycle action:** NONE", "**Worktree lifecycle action:** REMOVE")
        output = self.check_checker(record, expected=1)
        self.assertIn("requires explicit cleanup authority", output)
        self.assertIn("Worktree ledger", output)

    def test_git_rejects_unknown_lifecycle_action(self):
        record = self.git_record().replace("**Worktree lifecycle action:** NONE", "**Worktree lifecycle action:** MOVE,PRUNE")
        output = self.check_checker(record, expected=1)
        self.assertIn("must contain only", output)

    def test_git_rejects_unsafe_worktree_and_branch_retirement(self):
        record = self.git_record()
        native_retire = self.root / "tools/retire-worktree.py"
        native_retire.parent.mkdir()
        native_retire.write_text("#!/usr/bin/env python3\n")
        head = self.git("rev-parse", "HEAD")
        lifecycle = f"""- **Cleanup authority:** authorized; source: issue BATON-1; scope: exact ledger targets; conditions: inventory and recovery verified
- **Worktree lifecycle action:** REMOVE

### Worktree ledger
| Target path | Source path | Destination path | Repository | HEAD | Branch | Registry state | Dirty state | Untracked paths | Stash dependency | Unique commits | Integration evidence | Active process or lease | Owner/task | Recovery ref | Pre-action inventory | Post-action verification | Disposition | Retirement command | Action owner |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `{self.root / 'feature-lane'}` | `{self.root / 'feature-lane'}` | none | `{self.root}` | {head} | feature/gone | registered | clean | none | none | 1 | PR absent | no lease | baton-test | refs/heads/feature/gone | status captured | pending recheck | REMOVE-CANDIDATE | `tools/retire-worktree.py` | baton-test |

### Branch ledger
| Branch | Tip SHA | Upstream state | Attached worktree | Owner/task | Integration evidence | Unique commits | Recovery ref | Disposition | Action owner |
|---|---|---|---|---|---|---|---|---|---|
| feature/gone | {head} | gone | `{self.root / 'feature-lane'}` | baton-test | squash merge unproven | 1 | refs/heads/feature/gone | REMOVE-CANDIDATE | baton-test |
"""
        record = record.replace("- **Cleanup authority:** No destructive cleanup authorized\n- **Worktree lifecycle action:** NONE\n", lifecycle)
        output = self.check_checker(record, expected=1)
        self.assertIn("gone-upstream branch with unique commits must be retained", output)


class Scenarios(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="baton scenarios ")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / "evals").mkdir()
        for name in ("run-scenario.sh", "check.sh"):
            shutil.copy2(EVALS / name, self.root / "evals" / name)
        self.runner = self.root / "evals/run-scenario.sh"
        self.scenario = self.root / ".tmp/evals/scenarios/synthetic"
        self.repo = self.scenario / "repo"
        self.repo.mkdir(parents=True)
        (self.repo / "src.py").write_text("value = 1\n")
        old = self.repo / "docs/handoffs/handoff-old.md"
        old.parent.mkdir(parents=True)
        old.write_text(handoff("docs/handoffs/handoff-old.md"))
        native_plan = self.repo / "docs/plans/continuation-old.md"
        native_plan.parent.mkdir(parents=True)
        native_plan.write_text(handoff("docs/plans/continuation-old.md"))
        (self.repo / "handoff.md").write_text(handoff("handoff.md"))
        (self.scenario / "prompt.txt").write_text(f"Continue the session in {self.repo}. Your memory is in SESSION.md. Read <SKILL_PATH>.\n")
        skill = self.root / "skill"
        skill.mkdir()
        (skill / "SKILL.md").write_text("Synthetic skill, no model invocation.\n")
        self.call("prepare", "synthetic", str(skill), "test")
        self.run = self.root / ".tmp/evals/runs/test"
        self.artifact = self.run / "repo/docs/handoffs/handoff-new.md"
        self.artifact.write_text(handoff("docs/handoffs/handoff-new.md"))
        self.message = self.run / "last-message.txt"
        self.message.write_text(self.artifact.read_text().splitlines()[-1] + "\n")

    def call(self, *args, expected=0, env=None):
        result = subprocess.run(["bash", str(self.runner), *args], cwd="/", env=env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def result(self, expected=0):
        self.call("check", "test", expected=expected)
        result = json.loads((self.run / "result.json").read_text())
        self.assertEqual(result["verdict"], "pass" if expected == 0 else "fail")
        return result

    def test_success_binds_skill_and_exact_artifact(self):
        result = self.result()
        self.assertEqual(result["handoff_file"], str(self.artifact.resolve()))
        self.assertEqual(result["handoff_sha256"], hashlib.sha256(self.artifact.read_bytes()).hexdigest())
        self.assertIn("starting_repo", result)
        self.assertEqual(result["schema_version"], 3)

    def test_new_repository_native_plan_record_is_accepted(self):
        plan = self.run / "repo/docs/plans/continuation-plan.md"
        plan.parent.mkdir(parents=True, exist_ok=True)
        plan.write_text(handoff("docs/plans/continuation-plan.md"))
        self.message.write_text(plan.read_text().splitlines()[-1] + "\n")
        result = self.result()
        self.assertEqual(result["handoff_file"], str(plan.resolve()))

    def test_stale_artifact_is_rejected(self):
        old = self.run / "repo/docs/handoffs/handoff-old.md"
        self.message.write_text(old.read_text().splitlines()[-1] + "\n")
        self.assertIn("unchanged preexisting", " ".join(self.result(1)["errors"]))

    def test_unchanged_preexisting_record_is_rejected(self):
        old = self.run / "repo/docs/plans/continuation-old.md"
        self.message.write_text(old.read_text().splitlines()[-1] + "\n")
        result = self.result(1)
        self.assertIn("unchanged preexisting continuation record", " ".join(result["errors"]))
        self.assertEqual(result["check_fail"], 0)  # valid contents cannot bypass freshness scope

    def test_missing_final_never_selects_existing_file(self):
        self.message.unlink()
        self.assertFalse(self.result(1)["handoff_found"])

    def test_mismatched_closing_and_missing_target(self):
        self.message.write_text(self.message.read_text().replace("inspecting the source", "doing unrelated work"))
        self.assertIn("quote", " ".join(self.result(1)["errors"]))
        self.message.write_text("Read docs/handoffs/missing.md and do the continuation.\n")
        self.assertIn("missing handoff", " ".join(self.result(1)["errors"]))

    def test_validation_failure_and_failed_author(self):
        self.artifact.write_text(self.artifact.read_text().replace("COMPACT", "INVALID"))
        self.assertIn("validation failed", " ".join(self.result(1)["errors"]))
        meta_path = self.run / "meta.json"
        meta = json.loads(meta_path.read_text())
        meta.update(harness="codex", exit_code="42")
        meta_path.write_text(json.dumps(meta))
        self.assertIn("author exited", " ".join(self.result(1)["errors"]))

    def test_codex_propagates_exit_without_stale_message(self):
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        stub = bin_dir / "codex"
        stub.write_text("#!/bin/sh\nexit 42\n")
        stub.chmod(0o755)
        self.call("codex", "test", "synthetic", expected=42,
                  env={**os.environ, "PATH": str(bin_dir) + os.pathsep + os.environ["PATH"]})
        self.assertEqual(self.message.read_text(), "")
        self.result(1)

    def test_codex_retry_does_not_reuse_a_previous_artifact(self):
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        stub = bin_dir / "codex"
        stub.write_text('#!/bin/sh\nwhile [ "$1" != "-o" ]; do shift; done\ncp "$BATON_FAKE_MESSAGE" "$2"\n')
        stub.chmod(0o755)
        saved = self.run / "saved-message.txt"
        saved.write_text(self.message.read_text())
        self.call("codex", "test", "synthetic", env={**os.environ,
                  "PATH": str(bin_dir) + os.pathsep + os.environ["PATH"], "BATON_FAKE_MESSAGE": str(saved)})
        self.assertIn("unchanged preexisting", " ".join(self.result(1)["errors"]))

    def test_final_message_extra_output_fails(self):
        self.message.write_text("A handoff is ready.\n" + self.message.read_text())
        self.assertIn("only the closing", " ".join(self.result(1)["errors"]))

    def test_skill_drift_and_legacy_metadata_fail(self):
        meta_path = self.run / "meta.json"
        meta = json.loads(meta_path.read_text())
        Path(meta["skill_path"]).write_text("changed skill")
        self.assertIn("skill hash", " ".join(self.result(1)["errors"]))
        del meta["schema_version"]
        meta_path.write_text(json.dumps(meta))
        self.assertIn("prepare a new run", " ".join(self.result(1)["errors"]))


if __name__ == "__main__":
    unittest.main()
