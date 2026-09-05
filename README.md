# 🏃‍♂️➡️🏃 Baton

**Pass the baton cleanly.** Baton is a portable, harness- and project-agnostic AI **session-handoff skill**: it preserves every important result, decision, work-in-progress boundary, and next move in one evidence-backed operational entrypoint so a fresh session resumes without relying on the prior chat or losing momentum.

> **Website:** https://shanemhamilton.github.io/baton/

- **Two deliverables for every final handoff** — the handoff file and one exact closing sentence, in non-interactive, scheduled, and subagent runs too. The file exists before any question is asked (`Status: DRAFT` while one is open); the closing sentence is the file's last line and the session's last output, with nothing after it.
- **Four evidence classes** — every load-bearing claim is classified exactly `Observed`, `Derived`, `Volatile`, or `Unknown` (no synonyms), and every path resolves from the repository root or is given as an absolute path.
- **Checkpoint without ending the session** — an explicit **Baton checkpoint** request saves essential intent, corrections, approval scope, failed approaches, and the next move in an existing task note or an untracked checkpoint. It reads the note back and continues working; there is no automatic checkpoint hook.
- **Resume against current facts** — preserve unfinished work and decisions, then verify the next action's preconditions. Changed facts reopen only affected steps. Keep still-valid approval and do-not-redo boundaries with their supporting evidence.
- **Least-sufficient tier routing** — consequential model and delegation choices route to FAST, BALANCED, or FRONTIER by family, with provenance for model IDs. Routine choices stay with the receiving runtime and do not displace intent, boundaries, or unfinished work.
- **One human round, then finish** — at most one round of one to three qualifying questions. An unanswered choice is recorded as deferred by absence, with its option-preserving default and revisit trigger, so scheduled and subagent runs never stall.
- **Relevant capability discovery** — Baton verifies tools and access paths that affect continuation, and recommends material missing options through the existing human decision gate. It never installs or authorizes anything itself.
- **Transfer readiness** — a move records essential local artifacts, repository identity, source/destination locations, and verified access or pending prerequisites. A local file or Git clone alone does not prove the receiver has the handoff or uncommitted work.
- **`DIRECT` or `LEAN`, never heavier by default** — one context, or a capable main model plus one to three bounded workers. Escalating past that requires naming a concrete coordination failure neither shape can manage.
- **A mechanical check before every emit** — Step 8 runs an inline `bash` block, or `evals/check.sh` when the repo has it, against the written file and fixes every FAIL before the closing sentence goes out.

Every handoff ends with one unambiguous sentence:

> **Read `docs/handoffs/handoff-<timestamp>.md` and do the continuation mission through its stop conditions, starting by `<the first concrete move as a gerund phrase>`.**

---

## Install

Baton is a single Markdown skill file. Install the same file globally for Codex, Claude Code, or both. Baton is tested on Claude Code and OpenAI Codex CLI; other agents that read a skills directory may work, since the file is plain Markdown with YAML frontmatter, but they're untested.

### Codex (global — every project)

```bash
mkdir -p ~/.agents/skills/baton
curl -fsSL https://raw.githubusercontent.com/shanemhamilton/baton/main/skills/baton/SKILL.md \
  -o ~/.agents/skills/baton/SKILL.md
```

Codex discovers skills under `$HOME/.agents/skills` and a repo's own `.agents/skills`. Or per-project: put the file at `.agents/skills/baton/SKILL.md` inside the repo. If the metaswarm plugin is enabled in Codex, its `handoff` skill competes with baton on handoff-shaped requests; invoke `$baton` explicitly when the choice matters.

### Claude Code (global — every project)

```bash
mkdir -p ~/.claude/skills/baton
curl -fsSL https://raw.githubusercontent.com/shanemhamilton/baton/main/skills/baton/SKILL.md \
  -o ~/.claude/skills/baton/SKILL.md
```

Or per-project: put it at `.claude/skills/baton/SKILL.md` inside the repo.

### Clone

```bash
git clone https://github.com/shanemhamilton/baton.git
mkdir -p ~/.agents/skills ~/.claude/skills
cp -r baton/skills/baton ~/.agents/skills/
cp -r baton/skills/baton ~/.claude/skills/
```

Run either copy command or both.

---

## Method

Invoke the installed skill at the end of a session, when context is about to compact, or when switching machines:

- **Codex:** `$baton`
- **Claude Code:** `/baton`

Or say "hand this off" / "I'm running low on context, write a handoff." Baton runs eight steps:

1. **Reconstruct the mission** — the objective and why settled decisions matter, the Definition of Done as observable criteria, the execution horizon, and the hard stops.
2. **Establish live state** — refresh git (or file-level state in a non-git tree), relevant worktrees, locks, and runtime state. Recover surviving task notes when context is low; retain intent, authority, unfinished work, and the next safe move, marking unrecoverable facts `Unknown`. For moves, record essential artifact availability and pending transfer prerequisites.
3. **Human Leverage Gate** — write the file first, with `Status: DRAFT — awaiting human answer` while a question is open; ask at most one round of one to three qualifying questions; then finish. An unanswered choice becomes deferred by absence with its option-preserving default and revisit trigger.
4. **Capabilities and shape** — verify capabilities and routing choices that materially affect continuation; use `DIRECT` or `LEAN` when coordination needs to be specified, leaving routine choices to the receiver.
5. **Design the longest safe one-shot run** — reconcile the next action's preconditions with current instructions and state; revise affected steps, then continue through the permitted outcome ladder.
6. **Challenge** — a fresh read-only challenger reconstructs the first safe action, expected result, invalidating conditions, and missing information from the handoff and permitted artifacts alone.
7. **Write the document** — one template with three depth labels; prioritize intent, boundaries, unfinished work, action preconditions, and irreplaceable rationale before optional tool advice.
8. **Check, then emit** — run the inline check block, or `evals/check.sh` when present, fix every FAIL, then emit the closing sentence as the only output.

To save a material decision while work continues, explicitly request **Baton checkpoint**. This skips the final handoff workflow and closing sentence. A later final handoff consolidates essential checkpoint facts so the receiver does not need the earlier note.

---

## The handoff template

One template, one of three soft-ceiling depths: `COMPACT` (80 lines, for narrow low-uncertainty work), `STANDARD` (200 lines), or `GOVERNED` (320 lines).

| Section | Contents |
|---|---|
| **0. Launch Contract** | Main directive · depth/status · human decision state · permitted horizon · authority · first action and expected result/fallback · boot reconciliation · owning repository/transfer readiness when relevant · challenge findings · optional capability and routing choices |
| 1. Outcome and Done | Objective and why · observable acceptance criteria |
| 2. Live Truth | Status · momentum checkpoint · working state · claim table (`Observed`/`Derived`/`Volatile`/`Unknown`) · read first |
| 3. Decisions and Structure | Settled/deferred decisions · relevant failed approaches and revisit conditions · first structural milestone |
| 4. Verification | Smallest decisive check set, and what it does and doesn't prove |
| 5. Risks and Hard Stops | Blocker, owner, evidence needed, whether it blocks now |
| 6. Continuation Mission | Continue through · keep going until (first action is in Section 0) |

`STANDARD` adds a delegation map when needed, relevant rejected alternatives, and later horizons that guide continuation. `GOVERNED` adds separate truth and domain reviewers with their findings, plus recovery or rollback evidence.

---

## Evals

`evals/check.sh` checks file presence, draft status, populated objective/action/stop fields, evidence rows, cited paths, closing-file identity, depth, model provenance, and secret-like patterns. These are mechanical checks, not proof that claims are true or the receiver will succeed. Flags: `--root <repo-root>` resolves relative paths against a different repository, and `--baseline` replays a looser historical profile.

`evals/replay.sh`, `evals/dedupe-corpus.sh`, and `evals/run-scenario.sh` support Baton's own regression suite over a corpus of real handoffs and generated scenarios.

The committed `evals/fixtures/receiver/` scenarios and `evals/receiver-eval.py` separately evaluate resulting work, preservation of unrelated files, and attempts to cross a simulated approval boundary. Give a fresh receiver only the prepared repository and its closing instruction. Hand-authored controls test the mechanism; supplied author packets support evaluation of skill changes. See [evaluation instructions](evals/README.md) for commands and limitations.

Run the local regression checks without provider calls:

```bash
python3 evals/test-check.py
python3 evals/receiver-eval.py self-test
```

To check any handoff in any repo, either copy the Step 8 block from `skills/baton/SKILL.md` and run it directly, or run:

```bash
bash /path/to/baton/evals/check.sh --root <repo-root> <handoff.md>
```

### Historical results (v2.0.0–v2.0.1, 2026-09-01–02)

These results apply to v2.0.0–v2.0.1 and their original checks. See the [v2.1.0 changelog](CHANGELOG.md#210---2026-09-05) for verification of the continuation changes above.

Eight eval scenarios (non-interactive human choice, subagent author, low-context compaction, trivial one-file fix, multi-repo worktree, money-path high risk, non-git directory, background lanes), each run with the author model reading only the skill file.

| Author model | Runs | Both deliverables | Checker failures |
|---|---|---|---|
| Claude Sonnet, all eight scenarios | 8 | 8 | 0 |
| Claude Opus and Claude Fable, two scenarios each | 4 | 4 | 0 |
| Codex gpt-5.6-luna, gpt-5.6-terra, gpt-5.6-sol, two scenarios each | 6 | 6 | 0 |
| v2.0.1 follow-up: Opus and Fable on the six remaining scenarios | 12 | 12 | 0 |
| v2.0.1 follow-up: Codex luna, terra, sol on the six remaining scenarios | 18 | 18 | 1 (a URL route read as a path; fixed) |

v1.1 on the same 18 runs produced both deliverables 17 times and passed 83% of the generic assertions. Fresh Sonnet receivers with no skill loaded completed the first milestone with green tests on 3 of 3 v2 handoffs. Trigger accuracy against near-miss requests, judged by a Sonnet simulation of skill selection: 59 of 60 (v1.1: 55 of 60). Harness-native trigger eval through `claude -p` and `codex exec` (20 requests, 2 reps, no API key): Claude Code invoked baton in 15 of 18 should-trigger runs and never for a should-not request; Codex invoked it in 15 of 20 should-trigger runs and, in substance, never for a should-not request. On Codex, metaswarm's `handoff` skill won 3 of the 5 misses.

---

## Attribution

Baton is a derivative of the **handoff** skill from [**metaswarm**](https://github.com/dsifry/metaswarm) by **Dave Sifry** (MIT License). The core self-contained handoff structure and exact closing-sentence contract come from metaswarm; Baton adds a human leverage gate with deferred-by-absence, four evidence classes with root-resolved paths, least-sufficient tier routing, capability activation with recommend-and-ask, one template with three depth labels, `DIRECT`/`LEAN` execution shapes, a mechanical Step 8 check, and harness-agnostic generalization tested on Claude Code and Codex. Full detail in [`NOTICE`](./NOTICE). Grateful thanks to Dave and the metaswarm project.

## License

[MIT](./LICENSE) — © 2026 Shane Hamilton, with portions © 2026 Dave Sifry (metaswarm).
