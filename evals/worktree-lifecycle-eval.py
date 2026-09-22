#!/usr/bin/env python3
"""Exercise the Git facts behind Baton worktree-lifecycle safety controls.

This is an isolated regression suite, not a repository-cleanup tool. Every
case creates a temporary repository and removes it after the assertion. It
does not inspect, prune, move, or remove a worktree belonging to this checkout.

The evaluator makes the contract executable while the skill and document
checker decide how authors must record it:

* a receiver selects the recorded execution worktree and leaves dirty siblings
  untouched;
* a planned linked-worktree relocation uses ``git worktree move``;
* a manual relocation is detected as prunable and must be repaired before the
  lane is considered usable;
* a gone upstream with unique local commits is retained;
* a detached worktree gets a durable recovery ref before it is removable; and
* an untracked source-only handoff is not a verified transfer.

Run ``python3 evals/worktree-lifecycle-eval.py self-test`` from the Baton
checkout. No network, model, or third-party package is required.
"""

import argparse
import hashlib
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


def git(repo, *args):
    """Run Git without repository hooks and return stdout.

    The caller supplies only a synthetic temporary repository. Keeping the
    subprocess wrapper here makes that boundary visible in every scenario.
    """

    result = subprocess.run(
        ["git", "-c", "core.hooksPath=/dev/null", "-C", str(repo), *args],
        capture_output=True,
        text=True,
    )
    if result.returncode:
        raise AssertionError(
            f"git -C {repo} {' '.join(args)} failed ({result.returncode}):\n"
            f"stdout: {result.stdout}\nstderr: {result.stderr}"
        )
    return result.stdout.strip()


def write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


def initialise_repo(path):
    path.mkdir()
    git(path, "init", "-q", "--initial-branch=main")
    git(path, "config", "user.name", "Baton lifecycle fixture")
    git(path, "config", "user.email", "fixture@example.invalid")
    write(path / "README.md", "synthetic Baton lifecycle fixture\n")
    git(path, "add", "README.md")
    git(path, "-c", "commit.gpgsign=false", "commit", "-qm", "Initial fixture")


def worktree_registry(repo):
    """Return ``git worktree list --porcelain`` as stable, inspectable records."""

    records = []
    record = {}
    for line in git(repo, "worktree", "list", "--porcelain").splitlines():
        if not line:
            if record:
                records.append(record)
                record = {}
            continue
        key, _, value = line.partition(" ")
        if key == "worktree":
            record["path"] = Path(value).resolve()
        elif key == "HEAD":
            record["head"] = value
        elif key == "branch":
            record["branch"] = value
        elif key == "detached":
            record["detached"] = True
        elif key == "prunable":
            record["prunable"] = value or True
    if record:
        records.append(record)
    return records


def record_for(records, path):
    expected = Path(path).resolve()
    matches = [record for record in records if record["path"] == expected]
    if len(matches) != 1:
        raise AssertionError(f"expected one registered worktree at {expected}, found {matches}")
    return matches[0]


def registered_paths(records):
    return {record["path"] for record in records}


def select_execution_worktree(records, intended_path):
    """Model the minimum safe receiver choice from a recorded path.

    This evaluator-local control deliberately does not guess from branch names,
    recency, or a clean status. A future handoff/checker integration must
    supply the intended absolute path and reject prunable registration before
    any write is authorized.
    """

    record = record_for(records, intended_path)
    if record.get("prunable"):
        raise ValueError(f"execution worktree needs reconciliation: {record['path']}")
    return record


def unique_commits(repo, base_ref, branch):
    return int(git(repo, "rev-list", "--count", f"{base_ref}..{branch}"))


def cleanup_disposition(*, upstream_exists, unique_commit_count, merge_proof, authority):
    """Return the conservative branch-retirement disposition used by the eval."""

    if not authority or not merge_proof:
        return "RETAIN"
    if not upstream_exists and unique_commit_count:
        return "RETAIN"
    return "REMOVE-CANDIDATE"


def durable_refs_containing(repo, revision):
    refs = git(
        repo,
        "for-each-ref",
        "--contains",
        revision,
        "--format=%(refname)",
        "refs/heads",
        "refs/tags",
    )
    return {line for line in refs.splitlines() if line}


def require_recovery_ref(repo, revision):
    refs = durable_refs_containing(repo, revision)
    if not refs:
        raise ValueError(f"detached revision {revision} has no durable recovery ref")
    return refs


def content_hash(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verified_transfer(source, destination):
    """Require a receiver copy and byte-for-byte readback, never source existence."""

    return (
        source.is_file()
        and destination.is_file()
        and content_hash(source) == content_hash(destination)
    )


class WorktreeLifecycleControls(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="baton-worktree-lifecycle-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.repo = self.root / "repo"
        initialise_repo(self.repo)

    def assert_no_prunable(self):
        prunable = [record for record in worktree_registry(self.repo) if record.get("prunable")]
        self.assertEqual(prunable, [], f"unexpected prunable registrations: {prunable}")

    def test_dirty_linked_worktree_moves_with_git_and_receiver_keeps_other_lane(self):
        execution = self.root / "execution"
        unrelated = self.root / "unrelated"
        git(self.repo, "worktree", "add", "-q", "-b", "execution", str(execution))
        git(self.repo, "worktree", "add", "-q", "-b", "unrelated", str(unrelated))
        write(execution / "implementation.txt", "uncommitted execution work\n")
        write(unrelated / "other-owner.txt", "do not alter this lane\n")

        before = worktree_registry(self.repo)
        unrelated_status = git(unrelated, "status", "--porcelain=v1")
        selected = select_execution_worktree(before, execution)
        self.assertEqual(selected["branch"], "refs/heads/execution")

        moved = self.root / "execution-moved"
        git(self.repo, "worktree", "move", str(execution), str(moved))

        after = worktree_registry(self.repo)
        self.assertEqual(
            registered_paths(after),
            (registered_paths(before) - {execution.resolve()}) | {moved.resolve()},
        )
        moved_record = record_for(after, moved)
        self.assertEqual(moved_record["branch"], "refs/heads/execution")
        self.assertEqual(git(moved, "status", "--porcelain=v1"), "?? implementation.txt")
        self.assertEqual(git(unrelated, "status", "--porcelain=v1"), unrelated_status)
        self.assertEqual((unrelated / "other-owner.txt").read_text(), "do not alter this lane\n")
        self.assertFalse(execution.exists(), "Git relocation left the old execution path behind")
        self.assert_no_prunable()

    def test_manual_move_is_prunable_until_repaired_and_preserves_dirty_work(self):
        source = self.root / "manual-source"
        git(self.repo, "worktree", "add", "-q", "-b", "manual-source", str(source))
        write(source / "unfinished.txt", "recover this exact dirty work\n")
        before = worktree_registry(self.repo)

        # This is intentionally a filesystem move to reproduce the failure mode.
        # It is not a supported lifecycle operation.
        destination = self.root / "manual-destination"
        shutil.move(str(source), str(destination))
        stale = worktree_registry(self.repo)
        stale_record = record_for(stale, source)
        self.assertIn("prunable", stale_record)
        with self.assertRaises(ValueError):
            select_execution_worktree(stale, source)

        # `repair` establishes a new registry mapping before work may resume.
        git(self.repo, "worktree", "repair", str(destination))
        after = worktree_registry(self.repo)
        self.assertEqual(
            registered_paths(after),
            (registered_paths(before) - {source.resolve()}) | {destination.resolve()},
        )
        repaired = select_execution_worktree(after, destination)
        self.assertEqual(repaired["branch"], "refs/heads/manual-source")
        self.assertEqual(git(destination, "status", "--porcelain=v1"), "?? unfinished.txt")
        self.assertEqual((destination / "unfinished.txt").read_text(), "recover this exact dirty work\n")
        self.assert_no_prunable()

    def test_gone_upstream_with_unique_commits_is_retained_without_cleanup(self):
        remote = self.root / "remote.git"
        subprocess.run(["git", "init", "-q", "--bare", str(remote)], check=True)
        git(self.repo, "remote", "add", "origin", str(remote))
        git(self.repo, "push", "-qu", "origin", "main")

        lane = self.root / "gone-upstream"
        git(self.repo, "worktree", "add", "-q", "-b", "gone-upstream", str(lane), "main")
        write(lane / "unique.txt", "only this branch has this work\n")
        git(lane, "add", "unique.txt")
        git(lane, "-c", "commit.gpgsign=false", "commit", "-qm", "Keep unique work")
        git(lane, "push", "-qu", "origin", "gone-upstream")
        git(self.repo, "push", "origin", "--delete", "gone-upstream")
        git(self.repo, "fetch", "--prune", "origin")

        before = worktree_registry(self.repo)
        self.assertEqual(git(self.repo, "for-each-ref", "--format=%(refname)", "refs/remotes/origin/gone-upstream"), "")
        unique = unique_commits(self.repo, "origin/main", "gone-upstream")
        self.assertGreater(unique, 0)
        self.assertEqual(
            cleanup_disposition(
                upstream_exists=False,
                unique_commit_count=unique,
                merge_proof=True,
                authority=True,
            ),
            "RETAIN",
        )
        # The test performs no delete: absence of an upstream is not merge proof.
        self.assertEqual(git(self.repo, "rev-parse", "--verify", "refs/heads/gone-upstream"), git(lane, "rev-parse", "HEAD"))
        self.assertEqual(worktree_registry(self.repo), before)
        self.assertEqual((lane / "unique.txt").read_text(), "only this branch has this work\n")
        self.assert_no_prunable()

    def test_detached_worktree_requires_recovery_ref_before_removal(self):
        git(self.repo, "checkout", "-qb", "recovery-source")
        write(self.repo / "detached-only.txt", "preserve before retirement\n")
        git(self.repo, "add", "detached-only.txt")
        git(self.repo, "-c", "commit.gpgsign=false", "commit", "-qm", "Detached-only revision")
        detached_revision = git(self.repo, "rev-parse", "HEAD")
        git(self.repo, "checkout", "-q", "main")

        detached = self.root / "detached"
        git(self.repo, "worktree", "add", "-q", "--detach", str(detached), detached_revision)
        git(self.repo, "branch", "-D", "recovery-source")
        before = worktree_registry(self.repo)
        record = record_for(before, detached)
        self.assertTrue(record.get("detached"), record)
        self.assertEqual(durable_refs_containing(self.repo, detached_revision), set())
        with self.assertRaises(ValueError):
            require_recovery_ref(self.repo, detached_revision)

        git(self.repo, "branch", "recovery/detached-lane", detached_revision)
        self.assertIn("refs/heads/recovery/detached-lane", require_recovery_ref(self.repo, detached_revision))
        git(self.repo, "worktree", "remove", str(detached))

        after = worktree_registry(self.repo)
        self.assertEqual(registered_paths(after), registered_paths(before) - {detached.resolve()})
        self.assertFalse(detached.exists(), "removed detached checkout left filesystem residue")
        self.assertEqual(git(self.repo, "rev-parse", "recovery/detached-lane"), detached_revision)
        self.assert_no_prunable()

    def test_source_only_untracked_handoff_is_not_a_verified_transfer(self):
        receiver = self.root / "receiver"
        git(self.repo, "worktree", "add", "-q", "-b", "receiver", str(receiver))
        source_handoff = self.repo / "docs/handoffs/handoff-transfer.md"
        receiver_handoff = receiver / "docs/handoffs/handoff-transfer.md"
        write(source_handoff, "untracked source-only continuity packet\n")
        before = worktree_registry(self.repo)

        self.assertEqual(git(self.repo, "status", "--porcelain=v1"), "?? docs/")
        self.assertFalse(receiver_handoff.exists())
        self.assertFalse(
            verified_transfer(source_handoff, receiver_handoff),
            "author-side existence must not satisfy receiver availability",
        )
        # Rejecting the transfer leaves the intended receiver checkout and its
        # registry untouched; no implicit copy, clean, prune, or removal occurs.
        self.assertEqual(worktree_registry(self.repo), before)
        self.assertFalse(receiver_handoff.exists())
        write(receiver_handoff, source_handoff.read_text())
        self.assertTrue(verified_transfer(source_handoff, receiver_handoff))
        self.assertEqual(content_hash(receiver_handoff), content_hash(source_handoff))
        self.assert_no_prunable()


def self_test():
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(WorktreeLifecycleControls)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    return 0 if result.wasSuccessful() else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", nargs="?", default="self-test", choices=("self-test",))
    args = parser.parse_args()
    if args.command == "self-test":
        return self_test()
    raise AssertionError(f"unhandled command: {args.command}")


if __name__ == "__main__":
    sys.exit(main())
