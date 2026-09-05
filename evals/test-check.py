#!/usr/bin/env python3
"""Dependency-free synthetic regression checks; never calls a model/provider."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import shlex
import subprocess
import tempfile
import unittest

EVALS = Path(__file__).resolve().parent


def handoff(path, start="inspect `src.py`", truth="Unknown"):
    return f"""# Handoff: finish the recovery
## 0. Launch Contract
- **Document depth:** COMPACT
- **Human decision state:** none needed
- **Objective:** Recover the interrupted change and verify it.
- **Start by:** {start}
- **Hard stops and authority:** Local inspection only; request approval before publication.
## 2. Live Truth
| Claim | Class | Evidence | Refresh |
|---|---|---|---|
| Earlier outcome is not retained | {truth} | Context unavailable; inspect the local artifact | Read source |
## 6. Continuation Mission
- **Continue through:** Reconcile the source and record remaining work.
- **Keep going until:** The local state is documented or an actual authority gate is reached.
Read {path} and do the continuation mission through its stop conditions, starting by inspecting the source.
"""


class Checks(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="baton checks ")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.file = self.root / "docs/handoffs/handoff-new.md"
        self.file.parent.mkdir(parents=True)
        (self.root / "src.py").write_text("value = 1\n")
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
        inline = inline.replace("r='<absolute repository root or non-Git working directory>'", "r=" + shlex.quote(str(self.root)))
        inline = inline.replace("f='<absolute handoff file>'", "f=" + shlex.quote(str(self.file)))
        installed = subprocess.run(["bash", "-c", inline], cwd="/", capture_output=True, text=True)
        self.assertEqual(installed.returncode, expected, "inline block: " + installed.stdout + installed.stderr)
        return result.stdout

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
        self.assertEqual(result["schema_version"], 2)

    def test_stale_artifact_is_rejected(self):
        old = self.run / "repo/docs/handoffs/handoff-old.md"
        self.message.write_text(old.read_text().splitlines()[-1] + "\n")
        self.assertIn("unchanged preexisting", " ".join(self.result(1)["errors"]))

    def test_noncanonical_preexisting_artifact_is_rejected(self):
        old = self.run / "repo/handoff.md"
        self.message.write_text(old.read_text().splitlines()[-1] + "\n")
        result = self.result(1)
        self.assertIn("owning checkout docs/handoffs", " ".join(result["errors"]))
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
