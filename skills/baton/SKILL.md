---
name: baton
description: Pass the baton — write one self-contained operational entrypoint so a fresh session resumes without relying on the prior chat, and end with one "Read XXX.md and do YYY." sentence. The handoff normally appoints the main agent as the session orchestrator following `$efficient-frontier`, preplans the highest-value subagent waves, selects verified or startup-resolved specialized agent types and fit-for-purpose Claude, Codex, or other available models, defines authority/ownership/review gates, and leaves copy-ready dispatch packets. Use when a session is ending, context is about to compact, switching sessions or machines, running low on context, wrapping up, or the user asks to hand off, resume later, or continue in a new session. Project-agnostic.
---

# Baton — Handoff Skill

Pass the baton cleanly: capture the operational state and every load-bearing decision a **fresh agent with zero prior context** needs, write one self-contained entrypoint to the work, and hand it off with a single unambiguous sentence:

> **Read `docs/handoffs/<file>.md` and do `<the next concrete action>`.**

Use this when a session is ending, when context is about to be compacted, when switching machines or sessions, or when the user explicitly asks for a handoff. The receiving agent should act correctly from this single entrypoint without the prior conversation, while still reading any source artifacts it explicitly lists as prerequisites.

This skill is project-agnostic. It strongly prefers the `efficient-frontier` skill for the receiving orchestrator. If that named skill is unavailable, embed its core orchestration contract in Section 0 so the session follows the same behavior without stalling. References to beads, metaswarm, Codex roles, Claude models, or coverage files are examples; use only what the actual project and receiving runtime expose.

---

## Output Contract

This skill produces exactly two things:

1. **A handoff document** at `docs/handoffs/handoff-<YYYY-MM-DD-HHmm>.md` (created if the directory does not exist). A comprehensive operational entrypoint that embeds load-bearing decisions and links to or quotes every prerequisite artifact.
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

If the project persists state — a plan doc, task tracker, orchestration context, locks, or active-agent state — read and fold in whatever exists. Do **not** duplicate it blindly; summarize and link. Common examples (run only those that apply):

```bash
rg --files docs/plans .beads/plans         # discover plan files if these directories exist
bd prime                                   # beads state reload only when beads is installed and used
```

Do not suppress errors from state-refresh commands. Record an unavailable tool or failed refresh as unresolved evidence. If an active plan exists, point to it explicitly and state which unit/phase is in progress.

### Step 3 — Establish current status

Be honest and specific. Distinguish clearly between:

- **Done & verified** — with evidence (tests passing, build green, commit SHAs).
- **Done but unverified** — written but not yet tested/run.
- **In progress** — the exact thing being worked on now, and where it stopped.
- **Not started** — remaining work.

Capture the working-tree reality so the next agent is not surprised:

```bash
git branch --show-current
git rev-parse --show-toplevel
git rev-parse HEAD
git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}'
git rev-list --left-right --count 'HEAD...@{upstream}'
git status --short
git stash list
git log --oneline -10
git diff --stat
```

Record the absolute repo/worktree, branch and upstream, HEAD and relevant base, ahead/behind counts, uncommitted diff scope, stashes, pushed state, recovery/rollback state, and any active locks or parallel actors. Distinguish live evidence from remembered or persisted claims.

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

### Step 5b — Design the receiving session and dispatch plan

Make the next session's operating model executable before handoff:

1. **Appoint the main agent.** In almost all handoffs, state: **"You are the main session orchestrator. Invoke and follow `$efficient-frontier` before acting."** Use the receiving platform's verified invocation syntax (`$efficient-frontier`, `/efficient-frontier`, or an explicit skill path). If the skill is not verified as installed, say so and include the fallback contract from the template. The main agent retains architecture, prioritization, ambiguity resolution, risk decisions, synthesis, integration, and final review. Use `SOLO` only when the next action is trivial, tightly coupled, or the immediate blocker cannot usefully be delegated; record the reason.
2. **Discover the real runtime and agent catalog.** Name the expected receiving platform/provider and whether it is inspectable now. Inspect applicable instruction files, project/global agent configuration, installed skills, callable agent roles/native identifiers, model overrides, effort controls, concurrency, and nesting limits. Prefer a verified domain specialist, then the platform's read-heavy explorer or execution worker, then its general-purpose fallback. Never invent a name or assume a Codex launch field exists in Claude Code (or vice versa). If the future runtime cannot be inspected, record capability requirements plus `resolve at startup`, not fictional verification.
3. **Separate judgment from delegated work.** Keep frontier-only decisions with the main agent. Identify independent research, repository mapping, test/log reduction, bounded coding, mechanical edits, browser/device passes, and specialist review that can leave the main context clean.
4. **Plan waves, not blanket fan-out.** Determine the smallest high-value batch that saturates useful independent work within the runtime's known or startup-resolved concurrency cap. Reserve the main-agent slot, map dependency and collision surfaces first, and serialize shared-file, single-writer, immediate-blocker, destructive, or externally gated work. Parallelize read-heavy lanes freely; parallelize writes only with disjoint ownership. Do not permit nested fan-out unless the handoff explicitly budgets and scopes it.
5. **Select a model per lane.** Be provider-neutral. Resolve current availability at handoff time and record an exact preferred model, reasoning/effort setting where supported, and same-runtime fallback. Treat these model families as routing guidance, not guaranteed availability:

   | Lane shape | Preferred current class | Reasoning | Use when |
   |---|---|---|---|
   | Main orchestration, architecture, ambiguous implementation, safety/security review, final synthesis | strongest available frontier model (for example OpenAI `gpt-5.6-sol` or the latest verified Claude Opus) | high–xhigh or provider equivalent | Judgment quality matters more than latency |
   | Bounded implementation, exploration, large-file review, test/log reduction, documentation | fast balanced agentic model (for example OpenAI `gpt-5.6-terra` or the latest verified Claude Sonnet) | low–high or provider equivalent, matched to complexity | Scope and acceptance criteria are clear |
   | Tight edit/check loops or small mechanical coding steps | fastest suitable coding model the runtime exposes; in Codex, consider Codex-Spark (for example `gpt-5.3-codex-spark`) when available; in Claude, prefer the verified Sonnet option when its capability/latency fits | low–medium or provider equivalent | Fast iteration matters more than broader capability; never use a latency-first model as the sole high-risk reviewer |
   | Custom specialist with a configured model | inherit the specialist configuration unless the task requires a stronger verified override | configured | The specialist's domain instructions are the main source of value |

   Do not write an unsupported model slug or silently substitute a model from another provider. If availability cannot be verified, specify the capability class plus `inherit`, and tell the orchestrator to resolve the best available same-runtime match at startup.
6. **Prewrite the deployment.** For every likely subagent, record its wave, launch trigger, native agent role/identifier (or capability requirement to resolve), preferred model/settings, objective, file/area ownership, dependencies, verification, expected compact return, and fallback. Include a copy-ready self-contained prompt with repo path, scope, out-of-scope areas, required evidence, and stop conditions.
7. **Preplan independent review.** The implementer never self-certifies. Name a separate reviewer or specialist, select a model strong enough for the risk, and state the evidence the main orchestrator must personally spot-check before completion.
8. **Preserve authority and safety.** Delegation never expands user scope, permissions, or approval. Keep destructive, irreversible, production, privacy-, security-, and cost-sensitive actions with the main agent; complete safe preparation and fresh independent verification, then obtain required user approval. Never put secrets in packets. Record hard thread/nesting/cost limits and inherited sandbox/tool constraints.

Use `SWARM` by default when at least one independent lane materially improves speed or quality enough to justify its coordination cost. The point is **optimal useful concurrency**, not the largest possible agent count. A small task may use one bounded worker plus one fresh reviewer; a cross-cutting feature may use several first-wave scouts, collision-safe implementation lanes, and a final specialist/QC wave.

### Step 6 — Write the document

Create `docs/handoffs/handoff-<YYYY-MM-DD-HHmm>.md` using the template below. Fill every numbered section. In a justified `SOLO` handoff, write "None — SOLO because ..." for the deployment table/packets instead of expanding empty orchestration boilerplate.

### Step 7 — Emit the handoff sentence

After writing the file, verify it (Step 8), then output the single sentence — exactly one line, the literal file path, and the concrete action. Do not add commentary after it.

### Step 8 — Self-check before handing off

Confirm, as if you were the receiving agent who knows nothing:

- [ ] Does Section 0 explicitly appoint the main agent as orchestrator following `$efficient-frontier`, or justify the rare `SOLO` exception?
- [ ] Is `$efficient-frontier` verified available, or is its provider-neutral fallback contract embedded?
- [ ] Is the receiving runtime named, and is each agent/model choice either evidence-backed or explicitly marked `resolve at startup` with a capability requirement?
- [ ] Does the deployment table choose specialized agents and model/effort by lane rather than one generic subagent profile?
- [ ] Are concurrency, dependencies, collision surfaces, single-writer files, and launch triggers explicit?
- [ ] Is each planned subagent prompt self-contained and copy-ready, with ownership, verification, expected evidence, and stop conditions?
- [ ] Is fresh review independent from implementation, with the main orchestrator retaining final judgment?
- [ ] Do packets preserve user authority, sandbox/tool limits, secrets, hard caps, and approval gates without nested unplanned fan-out?
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

## 0. Receiving Session Orchestration
> **Main-agent directive:** You are the session orchestrator. Invoke and follow `$efficient-frontier` using the verified invocation below. If it is unavailable, follow the embedded fallback contract. Keep architecture, prioritization, risk decisions, synthesis, integration, and final review in the main session; delegate only the bounded lanes below.
- **Receiving runtime/provider:** <Codex app/CLI, Claude Code, other; version/surface if known; verified now or expected>
- **Efficient Frontier availability:** <verified invocation/path  |  unavailable or unknown — use embedded contract and resolve at startup>
- **Main-agent provider/model/settings:** <verified strongest available frontier choice; e.g. OpenAI `gpt-5.6-sol`, high, or latest verified Claude Opus with supported settings; otherwise capability class + `resolve at startup`>
- **Mode:** <SWARM by default  |  SOLO with one-line justification>
- **Runtime budget:** <hard thread cap; usable subagent slots after reserving main; nesting cap; cost/time cap; or unresolved startup check>
- **Review depth:** <light: [single gate]  |  full adversarial flow → review-gate marker (e.g. `.adversarial-review-passed`)>
- **Boot sequence:** <reload live tracker/repo/runtime state; verify agent/model availability; then dispatch Wave 1>
- **Why this shape:** <why these lanes, models, dependencies, and review depth fit this task>
- **Authority boundaries:** Delegation does not expand scope or approval. No secrets in packets. Keep destructive, production, privacy-, security-, and cost-sensitive actions with the main agent behind fresh independent verification and required user approval. <Add task-specific boundaries.>

### Efficient Frontier fallback contract
<Include when the named skill is unavailable or unverified; otherwise write the verified path/invocation and "not needed".>
- Keep architecture, prioritization, ambiguity, risk, synthesis, integration, and final review with the strongest main model.
- Delegate bounded, repeatable, token-heavy work to the cheapest/fastest capable agents with disjoint ownership and compact evidence returns.
- Treat subagent output as evidence, not a verdict; inspect high-risk diffs and rerun or spot-check decisive verification centrally.
- Stop delegation on live-state contradiction, repeated verification failure, scope expansion, or missing evidence.

### Runtime/catalog evidence
| Item | Value or required capability | Source / command | Checked |
|---|---|---|---|
| Runtime and version | <value> | <evidence> | <timestamp or `resolve at startup`> |
| Agent roles / native identifiers | <exact values or requirements> | <evidence> | <timestamp or `resolve at startup`> |
| Models and provider settings | <exact values or capability classes> | <evidence> | <timestamp or `resolve at startup`> |
| Thread/nesting limits | <hard limits> | <evidence> | <timestamp or `resolve at startup`> |

### Frontier-only decisions
- <decision the main orchestrator must retain>

### Preplanned deployment
| Packet | Wave / trigger | Agent role / native identifier | Provider/model/settings | Objective and ownership | Required return / verification | Same-runtime fallback |
|---|---|---|---|---|---|---|
| P1 | 1 / immediately after boot | `<verified native ID or capability to resolve>` | `<verified exact model/settings or class + inherit>` | <read-only scope or disjoint files> | <compact findings, commands, evidence> | <verified fallback or startup rule> |
| P2 | 2 / after <dependency> | `<worker/specialist>` | `<model/settings>` | <bounded implementation ownership> | <changed files, tests, residual risk> | <fallback> |
| PR | Review / after implementation | `<independent reviewer>` | `<strong-enough model/settings>` | <risk-focused fresh review; no edits unless asked> | <findings with file anchors and gate verdict> | <fallback> |

### Copy-ready dispatch packets
#### <Lane name> — Wave <N>
```text
Repo: <absolute path>
Objective: <one bounded objective>
Scope/ownership: <files, modules, or read-only search surface>
Out of scope: <explicit exclusions and single-writer surfaces>
Use agent role/model: <verified native identifier or capability to resolve>; <preferred provider/model/settings>; same-runtime fallback <...>
Authority: Stay within the user's scope and inherited permissions. Do not expose secrets or spawn nested agents. Complete safe preparation for destructive, production, privacy-, security-, cost-sensitive, or other consequential external actions, then return control to the main orchestrator for its required gate and execution.
Return: findings; changed files; exact commands and results; residual risk; stop condition hit; decisions needed from the orchestrator.
Verify: <exact commands or evidence>
Stop if: live code contradicts this packet; verification fails twice after one reasonable fix/retry; work requires files outside scope; or concrete evidence is unavailable.
```

<Repeat for each likely lane. If no useful lane exists, write "None" and justify SOLO above.>

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
- Repo/worktree: `<absolute path>`; branch `<branch>`; upstream `<upstream or none>`
- HEAD/base: `<HEAD sha>` / `<relevant base sha>`; ahead/behind `<counts>`; <pushed/not pushed>
- Uncommitted changes and diff scope: <git status/diff summary, or "clean">
- Stashes/recovery state: <stash list, rollback material, or "None">
- Active locks/parallel actors/single-writer surfaces: <live evidence or "None found; checked ...">
- Recent commits:
  - `<sha>` <subject>

## 4. Required Reading (external prerequisites after this entrypoint)
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
8. **Confusing a skill with a model** — `$efficient-frontier` is the main agent's orchestration workflow; select the actual model separately for each lane.
9. **One model for every agent** — routing all work to the same frontier profile wastes latency and cost. Match capability and reasoning effort to the lane.
10. **Speculative or cross-provider agents/models** — never name an agent type or model that was not verified in the receiving runtime, and never assume a Codex option exists in Claude Code or vice versa; include a same-runtime fallback.
11. **Maximum fan-out by default** — unused or overlapping agents add cost and coordination. Choose optimal useful concurrency after mapping dependencies and collision surfaces.
12. **Parallel write collisions** — assign disjoint ownership and preserve single-writer files, integration surfaces, and external gates.
13. **Unready delegation** — do not delegate the immediate blocker or launch a lane before its dependency/trigger is satisfied.
14. **Self-certification** — implementation evidence is not independent review; use a fresh reviewer and central spot-check.
15. **Authority expansion by delegation** — subagents inherit the task's scope and safety gates; never use delegation to bypass approval, sandbox, secrets, cost, privacy, security, production, or destructive-action boundaries.
16. **Unplanned recursive fan-out** — do not let subagents spawn more agents unless the handoff explicitly scopes, budgets, and justifies that nesting.
17. **False runtime certainty** — when the receiving environment is not inspectable, write capability requirements and `resolve at startup`; do not label guessed catalogs as verified.

---

## Relationship to Other Tools

- Baton serializes context **out of** a session for the next one — the mirror of any "prime" / "load context" step that loads knowledge **into** a session.
- For mid-execution work under an orchestration framework, reference its plan/state files (e.g. `.beads/plans/active-plan.md`) rather than restating them, so the next agent can reload native state and then read this doc for the human-readable narrative.
- Capturing durable *learnings* (patterns, lessons) is a separate job from Baton — Baton captures *this task's* transient state to resume it, not long-lived knowledge.

---

## Attribution

Baton is derived from the **handoff** skill in [metaswarm](https://github.com/dsifry/metaswarm) by Dave Sifry (MIT License). It adds **Section 0 "Receiving Session Orchestration"**: an `$efficient-frontier` main-agent directive, verified specialist/model routing, collision-aware deployment waves, copy-ready subagent packets, and independent review planning. It also generalizes the workflow across orchestration frameworks, issue trackers, and agent runtimes. See `NOTICE` for full attribution.
