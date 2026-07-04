---
name: baton
description: Pass the baton — write a single self-contained handoff document so a fresh session resumes with zero context loss, and end with one "Read XXX.md and do YYY." sentence. The handoff also tells the next session its own shape — which model tier (latest Sonnet vs latest Opus), SOLO vs SWARM mode, and review depth — and in SWARM mode directs the orchestrator to front-load a wide parallel subagent fan-out for both comprehensiveness and speed. Use when a session is ending, context is about to compact, switching sessions or machines, running low on context, wrapping up, or the user asks to hand off / resume later / continue in a new session. Project-agnostic.
---

# Baton — Handoff Skill

Pass the baton cleanly: capture everything a **fresh agent with zero prior context** needs to resume the current work, write it to one self-contained markdown document, and hand it off with a single unambiguous sentence:

> **Read `docs/handoffs/<file>.md` and do `<the next concrete action>`.**

Use this when a session is ending, when context is about to be compacted, when switching machines or sessions, or when the user explicitly asks for a handoff. The goal is **zero context loss**: the receiving agent should act correctly after reading exactly one file.

This skill is project-agnostic. It has no hard dependency on any orchestration framework, issue tracker, or plugin — where it mentions beads, metaswarm, or a coverage-thresholds file, those are *examples*; fold in whatever the current project actually uses, and write "None" where a thing does not apply.

---

## Output Contract

This skill produces exactly two things:

1. **A handoff document** at `docs/handoffs/handoff-<YYYY-MM-DD-HHmm>.md` (created if the directory does not exist). Comprehensive, self-contained, and links to — or quotes — every artifact the next agent must read.
2. **A single closing sentence**, and nothing else after the document is written, of the exact form:

   ```text
   Read docs/handoffs/handoff-2026-06-17-1432.md and do <YYY>.
   ```

   Where `<YYY>` is one concrete, actionable next step (an imperative, not a vague theme). Good: "implement the `parseConfig` validation in `src/config.ts:84` and make `tests/config.test.ts` pass". Bad: "continue the work" / "look into the config stuff".

The sentence is the deliverable the user hands to the next agent. The document is what makes that sentence safe to follow.

---

## Method

### Step 1 — Reconstruct what we are working on

Review the session to date and answer, concretely:

- **Objective**: What is the user actually trying to accomplish? One or two sentences.
- **Definition of Done**: What does "finished" look like? Enumerate verifiable acceptance criteria if any exist.
- **Why**: The motivation behind the task, so the next agent does not re-litigate settled decisions.

Pull from: the user's original request, any tracked issue (`gh issue view <n>` if GitHub), design/plan docs, and the arc of the conversation.

### Step 2 — Load any persisted project state (optional)

If the project persists state — a plan doc, a task tracker, an orchestration framework's context files — read and fold in whatever exists. Do **not** duplicate it blindly; summarize and link. Common examples (skip any that don't apply):

```bash
ls docs/plans/*-plan.md 2>/dev/null        # an approved plan, if mid-execution
ls .beads/plans/active-plan.md 2>/dev/null # beads/metaswarm plan, if present
bd prime --work-type recovery 2>/dev/null  # beads state reload, if beads is used
```

If an active plan exists, the handoff must point to it explicitly and state which unit/phase is in progress.

### Step 3 — Establish current status

Be honest and specific. Distinguish clearly between:

- **Done & verified** — with evidence (tests passing, build green, commit SHAs).
- **Done but unverified** — written but not yet tested/run.
- **In progress** — the exact thing being worked on now, and where it stopped.
- **Not started** — remaining work.

Capture the working-tree reality so the next agent is not surprised:

```bash
git branch --show-current
git status --short
git log --oneline -10
git diff --stat
```

Note uncommitted changes, stashes, and whether the branch is pushed.

### Step 4 — Identify required reading

List every artifact the next agent must read **before acting**, and for each say *why* and *what to look for*. Categories to sweep:

- **Specs / Issues** — the requirements source of truth.
- **Design docs** — any approved design.
- **Plans** — the active plan, if mid-execution.
- **Code** — the specific files and `file:line` anchors at the focus of the work, plus any pattern files to imitate.
- **Tests** — the tests that define correctness (failing tests are the spec under TDD).
- **Config / gates** — coverage thresholds, project instruction files (CLAUDE.md / AGENTS.md), CI config the change must satisfy.

Prefer precise pointers (`src/foo.ts:120-145`) over whole-file references. If something is short and load-bearing, quote it directly into the handoff so the next agent does not have to hunt.

### Step 5 — Decide the single next action (`YYY`)

Pick the one most important, concrete next step. It must be:

- **Actionable** — an imperative the agent can start immediately.
- **Specific** — names files, functions, or DoD items.
- **Bounded** — the immediate next move, not the entire roadmap (the rest goes in "Remaining Work").

### Step 5b — Specify the receiving session

Decide *who* resumes this work — a fresh session needs to know its own shape before it starts:

- **Model / tier** — default to the latest **Sonnet** for a clear, bounded task; the latest **Opus** when the work needs an orchestrator driving many subagents or deeper reasoning. **Never pin a version number** — write "Sonnet (latest)" / "Opus (latest)" so the handoff can't go stale as new models ship.
- **Mode** — `SOLO` (one agent does the whole thing) vs `SWARM` (an orchestrator decomposes it across subagents and drives the review flow — e.g. metaswarm, smokejumper, or a lead/coordinator agent).
- **Parallelism (SWARM only)** — tell the Opus orchestrator to treat the **opening phase as investment**: spend real time up front mapping the work into independent units, then dispatch the **maximum safe number of subagents at once** (batched in a single message so they run concurrently, never one-at-a-time). Wide fan-out is what buys *both* comprehensiveness (more ground covered) and speed (wall-clock = the slowest single agent, not the sum). Serialize only where a genuine dependency forces it. Guardrails that still hold: each subagent gets an explicit, scoped file list; safety-critical logic routes to a guardian/reviewer; no subagent self-certifies its own gate.
- **Review depth** — a single gate for a small change; the full adversarial review flow for user-facing or safety-critical work.

Record these in **Section 0** of the document. Match depth to the task: a bounded fix is `SOLO` + latest Sonnet + one gate; a multi-file feature is a latest-Opus orchestrator + Sonnet subagents + full review.

### Step 6 — Write the document

Create `docs/handoffs/handoff-<YYYY-MM-DD-HHmm>.md` using the template below. Fill every section; write "None" where a section genuinely does not apply rather than deleting it.

### Step 7 — Emit the handoff sentence

After writing the file, verify it (Step 8), then output the single sentence — exactly one line, the literal file path, and the concrete action. Do not add commentary after it.

### Step 8 — Self-check before handing off

Confirm, as if you were the receiving agent who knows nothing:

- [ ] Does Section 0 name the model tier (as "latest", unpinned), mode, and review depth so the receiver knows its own shape?
- [ ] In SWARM mode, does Section 0 carry the front-load-and-fan-out orchestration directive?
- [ ] Could I start work from this document alone, without the prior conversation?
- [ ] Are all referenced files/paths/issues real and correct (spot-check with `ls`/`git`)?
- [ ] Is the next action unambiguous and immediately startable?
- [ ] Are decisions and their rationale captured so I won't undo them?
- [ ] Are the quality gates (tests, coverage, lint, build commands) stated?
- [ ] Does the closing sentence name the exact file and a concrete action?

---

## Handoff Document Template

````markdown
# Handoff: <short title of the work>

**Date**: <YYYY-MM-DD HH:mm> · **Branch**: `<branch>` · **Author session**: <model/agent>

## 0. Receiving Session Config
> Who should pick this up. The first thing the next session reads — it sets model tier, orchestration mode, and review depth before any work begins. Use "latest" for the model, never a pinned version.
- **Model / tier:** <Sonnet (latest)  |  Opus (latest) orchestrator>
- **Mode:** <SOLO single agent  |  SWARM: orchestrator + subagents (e.g. metaswarm / smokejumper / lead agent)>
- **Subagents:** <none  |  N× Sonnet (latest): [decomposition list]>
- **Review depth:** <light: [single gate]  |  full adversarial flow → review-gate marker (e.g. `.adversarial-review-passed`)>
- **Boot command:** <e.g. `bd prime --work-type recovery`, then read this doc — or just "read this doc">
- **Orchestration directive (SWARM only):** Front-load the session — spend the opening phase decomposing the work, then launch the **maximum safe number of subagents in parallel** (all in one batched dispatch) to get it done both comprehensively and fast. Serialize only on real dependencies. Each subagent stays scoped to its file list; safety-critical logic goes to a guardian/reviewer; no subagent self-certifies.

## 1. Objective
<1–2 sentences: what we are trying to accomplish and why.>

## 2. Definition of Done
- [ ] <verifiable acceptance criterion>
- [ ] <…>

## 3. Current Status
**Done & verified:**
- <item> (evidence: <tests/commit>)

**Done, not yet verified:**
- <item>

**In progress (stopped here):**
- <the exact thing being worked on, and where/why it paused>

**Not started:**
- <remaining item>

### Working tree
- Branch `<branch>`, <pushed/not pushed>
- Uncommitted changes: <git status --short summary, or "clean">
- Recent commits:
  - `<sha>` <subject>

## 4. Required Reading (read these before acting)
| # | Path / reference | Why it matters | What to look for |
|---|---|---|---|
| 1 | `<path-or-issue>` | <reason> | <specific thing> |
| 2 | `<path:line>` | <reason> | <specific thing> |

## 5. Key Decisions & Rationale
- **<decision>** — <why; what alternatives were rejected and why>. Do not undo without reason.

## 6. Code Map
- `<file:line>` — <what lives here / its role in this task>
- Pattern to imitate: `<file>` — <why>

## 7. How to Verify
```bash
<test command>           # e.g., npm test
<coverage command>       # e.g., reads .coverage-thresholds.json
<lint/build command>
```
Expected: <what green looks like>.

## 8. Open Questions / Blockers
- <question needing the user, or external dependency>  — or "None"

## 9. Next Action
<The single concrete next step — the YYY — expanded with any detail the one-liner can't hold.>

## 10. Remaining Work (after the next action)
1. <subsequent step>
2. <…>
````

---

## Anti-Patterns

1. **Vague next action** — "continue where we left off" is useless. Name the file and the change.
2. **Assuming shared memory** — the next agent has none. If it matters and isn't in the doc, it's lost.
3. **Dumping the transcript** — synthesize. A 40-line oriented summary beats a 4,000-line paste.
4. **Stale pointers** — verify paths and line numbers exist before citing them; code may have moved.
5. **Hiding uncommitted state** — always disclose dirty working tree, stashes, and unpushed commits.
6. **Multiple "final" sentences** — emit exactly one `Read <file> and do <action>.` line.
7. **Silent decision loss** — if a choice was made and settled, record it with rationale so it isn't reopened.
8. **Pinned model versions** — write "Sonnet (latest)" / "Opus (latest)", never a version string that ages out.

---

## Relationship to Other Tools

- Baton serializes context **out of** a session for the next one — the mirror of any "prime" / "load context" step that loads knowledge **into** a session.
- For mid-execution work under an orchestration framework, reference its plan/state files (e.g. `.beads/plans/active-plan.md`) rather than restating them, so the next agent can reload native state and then read this doc for the human-readable narrative.
- Capturing durable *learnings* (patterns, lessons) is a separate job from Baton — Baton captures *this task's* transient state to resume it, not long-lived knowledge.

---

## Attribution

Baton is derived from the **handoff** skill in [metaswarm](https://github.com/dsifry/metaswarm) by Dave Sifry (MIT License). It adds the **Section 0 "Receiving Session Config"** (model tier, `SOLO`/`SWARM` mode, review depth), the **`SWARM` parallel-fan-out orchestration directive** (front-load, then dispatch the maximum safe number of subagents concurrently), the "latest, never pinned" model rule, and a framework-agnostic generalization. See `NOTICE` for full attribution.
