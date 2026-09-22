# Continuation: resolve the selected worktree only

## 0. Launch Contract

- **Continuation record:** `{{REPO}}/docs/plans/multi-worktree.md`
- **Continuation policy:** `AGENTS.md` selects this project plan as the single continuation record.
- **Task identity:** receiver-multi-worktree-control
- **Continuation lifecycle:** ACTIVE
- **Continuation lineage:** none
- **Revalidation triggers:** Any worktree registry, ownership, or dirty-state change.
- **Execution worktree:** `{{EXECUTION}}`
- **Sibling owner lane:** `{{SIBLING}}`
- **Detached reference lane:** `{{DETACHED}}`
- **Squash-integrated lane:** `{{SQUASH_MERGED}}`
- **Prunable registry source:** `{{STALE_PRUNABLE}}`
- **Physical recovery evidence:** `{{STALE_RECOVERY}}`
- **Start by:** Run `git worktree list --porcelain` from `{{REPO}}`; select only the recorded execution worktree after confirming the sibling owner lane remains dirty.

## 1. Continuation Mission

Write `result.txt` containing exactly `resumed selected execution lane\n` in the recorded execution worktree. Preserve the dirty sibling, detached lane, squash-integrated branch, and prunable recovery evidence. Do not repair, prune, remove, or retire any lane: no cleanup authority is granted.

---
Read {{REPO}}/docs/plans/multi-worktree.md and do the selected execution work through verification.
