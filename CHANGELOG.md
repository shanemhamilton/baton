# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.0] - 2026-09-05

### Added

- Explicit **Baton checkpoint** requests preserve irreplaceable task context without ending the session. Final handoffs recover essential checkpoint facts and refresh current state.
- Conditional transfer-readiness guidance records essential local artifacts, repository and checkout mappings, verified receiver access, and pending prerequisites.
- Public synthetic receiver scenarios for interrupted work, state drift, and deferred consequential actions, with independent outcome and boundary checks.

### Changed

- Receiver boot reconciles current instructions, workspace state, action preconditions, and scoped approvals, revisiting only affected decisions.
- The first action moves into Section 0 with its expected observation and safe fallback. Intent, boundaries, unfinished work, and decision rationale take priority over optional capability and model advice.
- Independent challengers reconstruct a safe first action from the handoff and available artifacts.

### Fixed

- Both document checkers reject empty required content, absent truth evidence, and a closing citation that points to another file with the same basename. The inline checker returns a real failure status and scans first-action paths in Section 0.
- Scenario scoring binds the emitted handoff to its actual contents, final message, skill hash and artifact baseline. Failed authors, unchanged preexisting artifacts, retry reuse and file/message mismatches return failure instead of a successful report command.
- Receiver grading permits legitimate test extensions and additional explanatory metadata, and checks protected state after executing receiver code.

### Verification

- All 18 local regression tests pass across the repository checker, installed inline checker, and author runner. Receiver-grader self-tests cover valid outcomes, preservation failures, and attempted prohibited actions.
- A fresh-agent synthetic sequence passed through an explicit checkpoint, final handoff, implementation, second handoff, and verification without repeating completed work or changing protected files.
- Skill validation, shell syntax, site JavaScript syntax, and whitespace checks pass. Independent reviews were completed and their findings resolved.
- These checks do not establish comparative model performance, cross-harness parity, or real cross-machine transfer reliability.

## [2.0.1] - 2026-09-02

### Fixed

- Low-context handoffs now record each open question as its own claim row with Class `Unknown`; two authors had left them untagged.
- The path check no longer flags URL routes such as `/v1/report` or `/api/users` as missing files, in both the inline Step 8 block and `evals/check.sh`.

### Changed

- The description now names "saving where work stands for later" as a trigger and states the precedence rule explicitly: when another handoff skill is installed, including metaswarm's handoff, use baton. On Codex, metaswarm's handoff had won 2 of 20 should-trigger requests.

### Added

- `evals/trigger-eval.sh` runs a request through `claude -p` (six turns) or `codex exec` in a read-only sandbox from a seeded scratch repo that is reset before every run, and records whether the harness invoked baton on its own, with no API key or SDK.

### Verification

- Extended cross-model matrix on the released skill: 31 of 31 author runs (Sonnet, Opus, Fable, and Codex gpt-5.6-luna, terra, and sol across the six scenarios that had only run on Sonnet) produced both deliverables; 30 had zero checker failures; 274 of 275 generic assertions passed.
- Money-path receiver replay against the final template: 2 of 2 fresh Sonnet receivers stopped at the migration gate with green tests.
- Harness-native trigger eval (20 requests, 2 reps each, no API key): Claude Code invoked baton in 15 of 18 should-trigger runs and in none of the 20 should-not runs; the two literal `/baton` runs are excluded because `claude -p` does not expand slash commands. Codex invoked baton in 15 of 20 should-trigger runs and, in substance, in none of the should-not runs (six flagged rows were Codex reading baton's file to answer questions about baton, or log contamination from an unconfined read-only sandbox). Metaswarm's `handoff` skill won 3 of the 5 Codex misses, so on Codex invoke `$baton` explicitly when the choice matters.

## [2.0.0] - 2026-09-01

A rewrite of the skill file from 475 lines down to 210.

### Added

- Rewrite the skill as one 210-line file: seven rules, eight steps, and a single template with three depth labels (COMPACT, STANDARD, GOVERNED).
- Write the handoff file before asking the human anything, and never end a session without both deliverables — the file and the closing sentence — even on non-interactive, scheduled, and subagent runs. An unanswered question is recorded as deferred by absence instead of blocking the handoff.
- Make the closing sentence the file's last line, so it's captured on disk, not only in chat.
- Classify every claim with one of four evidence classes, with no synonyms allowed, and resolve every cited path from the repository root, so a handoff can't point a receiver to a file that doesn't exist.
- Add a mechanical Step 8 check (an inline bash block, or `evals/check.sh` when present) that verifies depth ceilings, evidence-class wording, path resolution, the closing sentence, leftover DRAFT markers, model-identifier provenance, and secrets before a handoff is finalized.
- Replace the four execution shapes with two — DIRECT or LEAN — plus a named-failure escalation for anything heavier.
- Discover skills per harness: `~/.claude/skills` and `.claude/skills` for Claude Code, `~/.agents/skills` and `.agents/skills` for Codex, and flag when the receiving session runs on a different machine.
- Add a "Recommended install/connect" field to Section 0 for a missing capability the human should approve.
- Rewrite the skill description to lead with its trigger conditions, and add a precedence clause for when another handoff skill is installed.
- Handle low-context sessions and non-git working directories explicitly.
- State retention and secrets rules directly in the contract: keep `docs/handoffs/` untracked by default, and never write credentials or auth state into a handoff.
- Add a rule for the author to delegate its own state sweep and challenger to a cheaper subagent when the harness supports one.

### Removed

- The four execution shapes (STRUCTURED and METASWARM), used in under 4% of real handoffs.
- The six-column model-assignment matrix and the capability-activation table.
- The five-tier connector ladder.
- The 27-item self-check and the 23-item anti-pattern list.
- The second template.
- The Codex-only `$`-prefixed skill syntax.

### Changed

- Rewrite the README, NOTICE, and project site to describe what v2 actually does, and state the tested harness roster as Claude Code and Codex.

### Verification

- 36 author runs across eight eval scenarios: every v2 run produced both deliverables and passed all checker assertions on Claude Sonnet, Opus, and Fable and on Codex gpt-5.6-luna, terra, and sol. v1.1 passed 83% of the same assertions and missed the closing sentence in one run.
- Receiver replay: fresh Sonnet sessions with no skill loaded completed the first milestone with green tests on all three v2 handoffs. One receiver exercised a migration's mutating code path against scratch data despite a hard stop, so the template now asks each hard stop to name the exact forbidden action and the nearest allowed one.
- Description trigger eval: 59 of 60 decisions correct against near-miss requests (v1.1: 55 of 60).

## [1.2.0] - 2026-09-01

### Fixed

- Write the handoff file before the Human Leverage Gate, marked `Status: DRAFT — awaiting human answer`, so a non-interactive, scheduled, or subagent session no longer ends with neither deliverable when it hits an unanswered question.
- Limit the human gate to one round of questions; record anything still unanswered as deferred by absence, with its option-preserving default and revisit trigger.
- Add a Step 8 checker block that validates a written handoff before it's finalized.
- Make the closing sentence the template's last line, instead of only a chat message.
- Give the Compact template the same "own this as the primary execution session" directive the Standard template already had.
- Reference skills by their bare name, dropping the Codex-only `$`-prefixed syntax.
- Require a citable source for any model-route assignment.
- Require every deliverable and capability substitution to land in a durable location: disk, tracker, or a commit or PR body.
- Add a rule excluding secrets from the handoff file.

### Added

- Add `evals/` tooling: `dedupe-corpus.sh` deduplicates the handoff corpus, `check.sh` runs the checker against any handoff, `replay.sh` runs the checker across a corpus, and `run-scenario.sh` prepares, runs, and scores eval scenarios.

## [1.1.0] - 2026-09-01

### Added

- Add a Model Efficiency Gate to every nontrivial handoff: each lane routes to the least expensive reliable tier — fast models for deterministic legwork, balanced models for bounded coding and analysis, and frontier models reserved for judgment calls — with a written justification required wherever a lane uses a frontier model.
- Require a boot-time refresh of available model routes instead of trusting a stale model ID.

### Changed

- Escalate a lane's model tier only one step at a time, and only after an observed failure or a confirmed capability gap.

## [1.0.0] - 2026-09-01

### Added

- Initial release of Baton, a portable, harness-agnostic AI session-handoff skill for Claude Code and Codex.
- Preserve every material result, decision, work-in-progress boundary, recovery state, and next move without dumping the full transcript.
- End every handoff with an exact stop point, a do-not-redo boundary, and an executable continuation mission, so a fresh session resumes without losing momentum.
- Rank a receiving session's installed and installable capabilities, prefer authoritative connectors, and require provider-primary research before falling back to manual steps.
- Recommend a missing connector through a human install-or-defer gate, with setup and fallback paths for both Claude and Codex.
- Route bounded research, mechanical coding, and test execution to cheaper models, while reserving orchestration, synthesis, and review for capable models.

[Unreleased]: https://github.com/shanemhamilton/baton/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/shanemhamilton/baton/compare/v2.0.1...v2.1.0
[2.0.1]: https://github.com/shanemhamilton/baton/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/shanemhamilton/baton/compare/v1.2.0...v2.0.0
[1.2.0]: https://github.com/shanemhamilton/baton/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/shanemhamilton/baton/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/shanemhamilton/baton/releases/tag/v1.0.0
