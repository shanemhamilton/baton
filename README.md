# 🏃‍♂️➡️🏃 Baton

**Pass the baton cleanly.** Baton is a portable, harness- and project-agnostic AI **session-handoff skill**: it preserves every important result, decision, work-in-progress boundary, and next move in one evidence-backed operational entrypoint so a fresh session resumes without relying on the prior chat or losing momentum.

> **Website:** https://shanemhamilton.github.io/baton/

- **Two deliverables, always** — the handoff file and one exact closing sentence, in non-interactive, scheduled, and subagent runs too. The file exists before any question is asked (`Status: DRAFT` while one is open); the closing sentence is the file's last line and the session's last output, with nothing after it.
- **Four evidence classes** — every load-bearing claim is classified exactly `Observed`, `Derived`, `Volatile`, or `Unknown` (no synonyms), and every path resolves from the repository root or is given as an absolute path.
- **Durable by default** — nothing load-bearing lives only in chat; a gated draft goes to a named, untracked local file, never left unrecorded.
- **Momentum checkpoint** — the exact stop point, next concrete move, active or background lanes, and a do-not-redo boundary, so the receiving session resumes instead of re-investigating.
- **Least-sufficient tier routing** — every lane routes to FAST, BALANCED, or FRONTIER by model family, not model ID, unless a real catalog is cited (`~/.codex/models_cache.json` for Codex; Claude Code exposes none).
- **One human round, then finish** — at most one round of one to three qualifying questions. An unanswered choice is recorded as deferred by absence, with its option-preserving default and revisit trigger, so scheduled and subagent runs never stall.
- **Capability discovery, not installation** — Baton enumerates skills from `~/.claude/skills` and `.claude/skills` (Claude Code) or `~/.agents/skills` and `.agents/skills` (Codex), ranks access paths, and recommends a missing option for the human to approve. It never installs or authorizes anything itself.
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

Codex discovers skills under `$HOME/.agents/skills` and a repo's own `.agents/skills`. Or per-project: put the file at `.agents/skills/baton/SKILL.md` inside the repo.

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
2. **Establish live state** — refresh git (or file-level state in a non-git tree), worktrees, locks, and runtime state. On low context, write the Section 0 spine and Live Truth from live state alone, mark the rest `Unknown`, and finish.
3. **Human Leverage Gate** — write the file first, with `Status: DRAFT — awaiting human answer` while a question is open; ask at most one round of one to three qualifying questions; then finish. An unanswered choice becomes deferred by absence with its option-preserving default and revisit trigger.
4. **Capabilities and shape** — enumerate the receiving runtime's actual skills, tools, subagents, and connectors; rank access paths; recommend a missing option and ask, never install it; choose `DIRECT` (one context) or `LEAN` (a capable main model plus one to three bounded workers).
5. **Design the longest safe one-shot run** — an outcome ladder (boot, confirm structure, expand, verify, challenge, close), not a script.
6. **Challenge** — audit every load-bearing claim, hunt for the strongest contradiction, and send nontrivial work to a fresh read-only challenger.
7. **Write the document** — one template, one of three depth labels.
8. **Check, then emit** — run the inline check block, or `evals/check.sh` when present, fix every FAIL, then emit the closing sentence as the only output.

---

## The handoff template

One template, one of three soft-ceiling depths: `COMPACT` (80 lines, for narrow low-uncertainty work), `STANDARD` (200 lines), or `GOVERNED` (320 lines).

| Section | Contents |
|---|---|
| **0. Launch Contract** | Main directive · document depth · status · execution (`DIRECT`/`LEAN`) · capability activation · recommended install/connect · model routing · human decision state · one-shot horizon · review tier and challenge · boot refresh · hard stops and authority · owning repository |
| 1. Outcome and Done | Objective and why · observable acceptance criteria |
| 2. Live Truth | Status · momentum checkpoint · working state · claim table (`Observed`/`Derived`/`Volatile`/`Unknown`) · read first |
| 3. Decisions and Structure | Settled and deferred decisions · first structural milestone |
| 4. Verification | Smallest decisive check set, and what it does and doesn't prove |
| 5. Risks and Hard Stops | Blocker, owner, evidence needed, whether it blocks now |
| 6. Continuation Mission | Start by · continue through · keep going until |

`STANDARD` adds a delegation map, per-decision detail with rejected alternatives, and a later-horizons section. `GOVERNED` adds separate truth and domain reviewers with their findings, plus recovery or rollback evidence.

---

## Evals

`evals/check.sh` runs the nine mechanical checks in Step 8 — file present, no leftover `DRAFT` line, required fields, exactly one evidence class per claim, cited paths resolve, closing sentence present, depth ceiling, model-identifier provenance, and secrets — against any handoff file. Flags: `--root <repo-root>` resolves relative paths against a different repository, and `--baseline` replays the looser profile used for documents written before the checker existed.

`evals/replay.sh`, `evals/dedupe-corpus.sh`, and `evals/run-scenario.sh` support Baton's own regression suite over a corpus of real handoffs and generated scenarios.

To check any handoff in any repo, either copy the Step 8 block from `skills/baton/SKILL.md` and run it directly, or run:

```bash
bash /path/to/baton/evals/check.sh --root <repo-root> <handoff.md>
```

### Results (v2.0.0, 2026-09-01)

Eight eval scenarios (non-interactive human choice, subagent author, low-context compaction, trivial one-file fix, multi-repo worktree, money-path high risk, non-git directory, background lanes), each run with the author model reading only the skill file.

| Author model | Runs | Both deliverables | Checker failures |
|---|---|---|---|
| Claude Sonnet, all eight scenarios | 8 | 8 | 0 |
| Claude Opus and Claude Fable, two scenarios each | 4 | 4 | 0 |
| Codex gpt-5.6-luna, gpt-5.6-terra, gpt-5.6-sol, two scenarios each | 6 | 6 | 0 |

v1.1 on the same 18 runs produced both deliverables 17 times and passed 83% of the generic assertions. Fresh Sonnet receivers with no skill loaded completed the first milestone with green tests on 3 of 3 v2 handoffs. Trigger accuracy against near-miss requests: 59 of 60 (v1.1: 55 of 60).

---

## Attribution

Baton is a derivative of the **handoff** skill from [**metaswarm**](https://github.com/dsifry/metaswarm) by **Dave Sifry** (MIT License). The core self-contained handoff structure and exact closing-sentence contract come from metaswarm; Baton adds a human leverage gate with deferred-by-absence, four evidence classes with root-resolved paths, least-sufficient tier routing, capability activation with recommend-and-ask, one template with three depth labels, `DIRECT`/`LEAN` execution shapes, a mechanical Step 8 check, and harness-agnostic generalization tested on Claude Code and Codex. Full detail in [`NOTICE`](./NOTICE). Grateful thanks to Dave and the metaswarm project.

## License

[MIT](./LICENSE) — © 2026 Shane Hamilton, with portions © 2026 Dave Sifry (metaswarm).
