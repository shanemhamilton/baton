---
name: baton
description: Pass the baton by writing one self-contained, evidence-backed operational entrypoint for a fresh session, then end with one exact "Read XXX.md and do YYY." sentence. Pause before finalizing when a small number of human-owned decisions would materially improve the next session, so the human can answer or explicitly defer. Select the lightest adequate execution mechanism—direct work, small native delegation, a structured orchestrator, or Metaswarm only when justified—and embed a right-sized adversarial review spine. Optimize for the longest safe one-shot run and maximum verified progress; for substantial product or feature work, establish a working architectural skeleton before filling in detailed parts. Use when ending or compacting a session, switching machines or sessions, wrapping up, or when the user asks to hand off, resume later, or continue in a new session. Project-agnostic.
---

# Baton — Handoff Skill

Pass the baton cleanly. Capture the operational truth and load-bearing decisions a **fresh agent with zero prior chat context** needs, then give it a continuation mission designed to make the maximum safe, verified progress in one uninterrupted session.

End with one unambiguous sentence:

> **Read `docs/handoffs/<file>.md` and do the continuation mission through its stop conditions, starting by `<the first concrete move as a gerund phrase>`.**

Treat the handoff as an evidence-backed launchpad, not a frozen transcript or an exhaustive prediction of every future edit.

## Core Rules

1. **Re-ground in live truth.** Verify repository, tracker, runtime, lock, and external state before recording it. Mark facts, inferences, volatile claims, and unknowns distinctly.
2. **Choose the lightest adequate execution shape.** The agent writing the handoff selects the receiving framework. Do not default to Metaswarm, any other orchestration skill, or maximum fan-out merely because it is installed.
3. **Keep an adversarial spine.** Use evidence checks, contradiction-seeking, and fresh independent challenge in proportion to risk. Never treat an agent's confidence as proof.
4. **Surface high-leverage human decisions before finalizing.** If a small number of human-owned choices would materially change the outcome, design, risk posture, or useful execution horizon, pause with concise options, a recommendation, and an explicit defer path. Do not ask the human to decide facts or reversible engineering details the agent can resolve.
5. **Optimize for a long one-shot run.** Give the receiving session a full safe execution horizon, milestone sequence, verification loop, and explicit stop conditions. Do not tell it to finish one small step and stop unless that step completes the task.
6. **Build structure before detail when the work warrants it.** For greenfield or substantial cross-cutting product work, establish a minimal working architectural or end-to-end skeleton, prove that the pieces connect, and then expand the highest-value parts. Do not create empty boilerplate for a narrow fix or mature code path.
7. **Preserve authority.** A handoff or delegation never expands user scope, permissions, budget, or approval. Keep destructive, irreversible, production, privacy-, security-, and cost-sensitive actions behind their existing gates.

## Output Contract

After the Human Leverage Gate is cleared, produce exactly two deliverables:

1. **One handoff document** at `docs/handoffs/handoff-<YYYY-MM-DD-HHmm>.md`. Create the directory when needed. Make the document compact enough to orient quickly and complete enough to operate without the prior chat.
2. **One closing sentence**, with nothing after it, using the literal path and an executable mission:

   ```text
   Read docs/handoffs/handoff-2026-06-17-1432.md and do the continuation mission through its stop conditions, starting by establishing the tested CLI walking skeleton described there.
   ```

Use a shorter `Read ... and do ...` form only when the entire remaining task is genuinely narrow. Never end with “continue the work,” “follow the plan,” or another vague theme.

An interim human-decision pause is **not a completed handoff** and is the only exception to the two-deliverable contract. Ask the decision questions and stop. Do not write or present the final handoff document or closing sentence until the human answers or explicitly defers each qualifying human-owned choice.

## Method

### Step 1 — Reconstruct the mission

State:

- **Objective and why** — what outcome the user wants and why settled decisions matter.
- **Definition of Done** — observable acceptance criteria, including external proof that local tests cannot establish.
- **Current execution horizon** — the largest coherent, safe body of work the next session can pursue without needing a new product decision or approval.
- **Hard stop conditions** — the exact events that require the user, an external-state change, a safety gate, or a new handoff.

Use the user's request, issue or tracker, approved design and plan artifacts, project instructions, and verified session work. Preserve uncertainty instead of filling gaps with plausible detail.

### Step 2 — Establish live state and an evidence ledger

Load project-native state only when it exists. Prefer built-in platform and project mechanisms before adding a framework. Examples:

```bash
rg --files docs .beads                         # discover, do not assume, persisted state
bd prime                                      # only when this project actually uses Beads
git status --short --branch
git rev-parse --show-toplevel
git rev-parse HEAD
git log --oneline -10
git diff --stat
git stash list
```

Also check the applicable upstream divergence, worktree, locks, active actors, deploy/store/runtime state, and recovery material when they affect the task. Do not suppress failed refreshes; record them as missing evidence.

For every load-bearing claim, record one of:

- **Observed** — directly re-read or executed now; cite the path, command, output, or external source.
- **Derived** — a conclusion from named observed facts; state the reasoning briefly.
- **Volatile** — observed now but likely to drift; require a boot-time refresh.
- **Unknown** — not verified; never convert it into a fact for narrative completeness.

### Step 3 — Run the Human Leverage Gate

Before selecting the execution shape or finalizing the handoff, identify unresolved choices that are genuinely owned by the human and would make the next session materially more productive if settled now. A choice qualifies only when all of these are true:

- Its answer is not discoverable or resolvable from current source, instructions, tracker state, prior decisions, or a safe in-scope investigation, existing test, or sandboxed probe.
- Plausible answers would materially change the outcome, priority, acceptance criteria, user experience, architecture or data ownership, risk tolerance, authorized budget or external action, or the useful one-shot execution horizon.
- It belongs to the human rather than ordinary reversible engineering judgment.
- Resolving it now avoids meaningful rework or unlocks more useful work than waiting until the decision is naturally encountered.

When one or more choices qualify:

1. Complete all safe read-only preparation that can sharpen the decision.
2. Ask only the one to three highest-leverage questions. For each, state why it matters, the practical effect of the viable options, the recommended default, and exactly what **defer** would mean.
3. Stop before writing or presenting the final handoff document or closing sentence. Let the human answer, revise the options, or explicitly defer.
4. Classify the response explicitly. An **answer** settles the choice for the stated one-shot horizon. “Use your recommendation” counts as an answer only when the recommended option and its horizon are explicit. A **defer** intentionally leaves the choice open and must name a safe boundary plus revisit trigger. Partial or ambiguous responses require a concise follow-up; silence is never a defer.
5. If answered, record the result as an **Observed human decision** and resume from the now-settled execution horizon.
6. If deferred, record who deferred it and the concrete revisit trigger. A recommendation is not authorization: use a recommended default only when existing authority permits it **and** it is option-preserving, low-cost to reverse, and does not prejudice the eventual outcome, architecture, or data ownership. Otherwise narrow the continuation mission to the safe work that ends before the decision boundary.
7. Re-run this gate after each response, whenever later framework, architecture, evidence, or adversarial analysis reveals a new qualifying choice, and immediately before finalizing the handoff. The gate is clear only when every qualifying choice is answered or explicitly deferred.

Use this compact interim form so the human can choose, give free-form feedback, or defer:

```text
Human decision needed before I finalize the handoff

1. <decision>
   Why now: <how it changes the next session's useful work>
   Options: <viable choices and practical effects>
   Recommendation: <default and why>
   If deferred: <safe default or boundary, plus revisit trigger>

Reply with a choice, feedback, or "defer." I will stop here and finalize the handoff after your response.
```

Do not pause for discoverable facts, ordinary implementation details, technical uncertainty resolvable through an existing test or safe in-scope probe, reversible choices with project-conforming defaults, routine test failures, or approvals that are needed later but do not affect useful preparation now. Selecting the receiving execution framework is the handoff author's responsibility unless the choice exposes a real human-owned budget, timing, policy, or governance tradeoff.

If no choice qualifies, record `Human decision state: none needed` and continue.

### Step 4 — Select the receiving execution shape

The handoff author must choose and justify the **lightest shape that can reliably complete the execution horizon**. The receiving agent validates availability and live assumptions at boot; it changes shape only when live evidence invalidates the choice, and records why.

| Shape | Select when | Minimum safety mechanism |
|---|---|---|
| **DIRECT** | Work is narrow, tightly coupled, or fastest in one main context. | Deterministic checks plus a separate contradiction pass; use a fresh read-only challenger when the task is nontrivial and one is available. |
| **LEAN** | One main agent plus roughly 1–3 independent native workers/reviewers materially improves speed or quality without persistent orchestration state. This is the normal choice for many nontrivial tasks. | Disjoint ownership, compact evidence returns, and one fresh independent review. |
| **STRUCTURED** | Several dependent phases, cross-cutting architecture, or multiple review waves benefit from an existing plan/orchestration skill, but full swarm machinery is unnecessary. | Explicit dependencies, single-writer boundaries, milestone gates, and fresh review at integration points. |
| **METASWARM** | Sustained parallel workstreams, multiple writers, formal governance gates, locks/ownership, or durable cross-session coordination make its setup and state machinery materially safer or faster than the lighter shapes. | Follow its verified project setup and native gates; retain central evidence checks and user authority. |

Choose execution shape and review tier independently. A narrow security repair may be `DIRECT` with high-risk review; a broad low-risk scaffold may be `STRUCTURED` with medium-risk review. Complexity determines coordination weight. Consequence and uncertainty determine adversarial depth.

Before selecting `METASWARM`, answer explicitly:

- What concrete coordination failure would `DIRECT`, `LEAN`, or `STRUCTURED` leave unmanaged?
- Which verified Metaswarm capability addresses that failure?
- Is Metaswarm already usable here, or is setup cost part of the justified horizon?
- Do the parallelism, duration, governance, and collision risks repay that overhead?

If those answers are weak, choose a lighter shape. Never run `/setup` just to make a handoff look complete.

Record the chosen framework or native mechanism, verified invocation if known, agent/runtime constraints that matter, and a graceful fallback. Do not inventory or pin every possible model. Name a specialist, tool, or model only when verified and consequential; otherwise state the required capability and let the receiving runtime resolve it.

### Step 5 — Design the longest safe one-shot run

Plan an **outcome ladder**, not a line-by-line script:

1. **Boot and re-ground** — refresh volatile state, instructions, permissions, dependencies, and the selected framework's availability.
2. **Establish or confirm structure** — understand the existing architecture. For greenfield or substantial feature work, create a minimal **walking skeleton**: real boundaries, interfaces/data flow, and the thinnest buildable or runnable end-to-end path.
3. **Expand by value and dependency** — implement the next highest-value slices on that proven structure, keeping changes small enough to verify.
4. **Verify and repair continuously** — run the relevant tests, builds, static checks, and evidence reads after each milestone; fix ordinary failures and continue.
5. **Challenge and integrate** — perform the planned independent review, resolve findings, rerun decisive checks, and continue while the mission remains safe and unblocked.
6. **Close or hand off honestly** — finish the Definition of Done, or create the next Baton only when a hard stop or genuine context boundary is reached.

Tell the receiving agent to proceed through ordinary ambiguity using reversible, evidence-backed assumptions and to record them. Do not make routine test failures, a completed subtask, or the end of a prewritten checklist an automatic stopping point.

Maximize coherent verified progress, not unchecked batch size. Preserve enough context and time to integrate results, rerun decisive checks, and write another evidence-backed Baton if a genuine session boundary arrives before Definition of Done.

For a bug fix, release operation, migration, or mature feature, work with the existing architecture and choose the appropriate first milestone. “Skeleton first” is a design heuristic for work that needs structure, not permission to add speculative layers or placeholder code.

### Step 6 — Build the adversarial evidence spine

Apply all four passes before handing off:

1. **Claim audit** — attach evidence to each load-bearing status, path, command, branch, dependency, and acceptance claim.
2. **Falsification pass** — actively search for the strongest contradiction: stale state, wrong worktree, hidden dirty changes, missing files, invalid line anchors, unverified external status, false completion, unsafe rollback, or a plan that cannot fit the architecture.
3. **Fresh challenge** — for every nontrivial handoff, use at least one fresh read-only challenger when the runtime supports it. Give the challenger the handoff and raw source artifacts, not the intended verdict. Ask it to find factual errors, missing constraints, unsafe assumptions, and a simpler execution shape. If no independent context is available, perform a clearly separated zero-assumption reread and disclose that limitation.
4. **Correction and replay** — correct supported findings, rerun decisive checks, and re-read the final artifact. Record unresolved disagreement as uncertainty or a blocker.

Scale the review without reaching automatically for an orchestration framework:

- **Low risk:** exact path/command checks, falsification pass, and one lightweight fresh challenge when available.
- **Medium risk:** independent truth/plan review before handoff and an independent implementation review at the relevant receiving-session milestone.
- **High risk:** separate truth and domain/safety reviewers; independently verify target, impact, and recovery immediately before destructive or consequential action; obtain required user approval.

Treat reviewer output as evidence, not a verdict. The main agent spot-checks decisive claims and remains responsible for synthesis. A native subagent or separate review pass is sufficient for most review work; Metaswarm is not required to be adversarial.

When the receiving session changes behavior or architecture, require a fresh reviewer distinct from the implementer whenever the runtime can provide one, regardless of execution shape. If that independence is unavailable, disclose the limitation and strengthen deterministic checks and central rereads.

### Step 7 — Write the handoff document

Choose document depth separately from execution shape:

- **COMPACT:** Use for narrow, low-uncertainty work. Aim for roughly 30–80 lines and use the compact template. Keep only load-bearing claims and checks.
- **STANDARD:** Use for a substantial feature, investigation, or multi-milestone session. Use the standard template, usually at outcome level rather than edit level.
- **GOVERNED:** Expand the standard template only for high-risk, regulated, destructive, multi-repository, or genuinely Metaswarm-scale work whose evidence and recovery needs require it.

A high-risk `DIRECT` repair may need `GOVERNED` evidence; a broad but reversible `STRUCTURED` scaffold may need only `STANDARD` detail. Do not repeat the same fact across sections. Link to durable native state instead of copying it. Do not precompute hypothetical hashes, outputs, commits, or artifacts and present them as future proof; specify the command and acceptance condition the receiving session must actually observe.

Keep delegation/framework detail proportional: a `DIRECT` handoff needs no deployment theater; a `LEAN` handoff may need a short ownership table; a `METASWARM` handoff should reference its verified native plan/state rather than duplicating it.

### Step 8 — Verify and emit the closing sentence

Run the self-check, re-read the written file, then emit exactly one closing sentence. Make the first move concrete, but make the mission horizon clear:

```text
Read docs/handoffs/<file>.md and do the continuation mission through its stop conditions, starting by <first concrete move as a gerund phrase>.
```

## Compact Handoff Template

Use this instead of the standard template for `COMPACT` depth. Omit empty optional bullets rather than expanding “None” into prose.

````markdown
# Handoff: <short outcome-oriented title>

**Date:** <YYYY-MM-DD HH:mm> · **Repo/branch:** `<absolute path>` / `<branch>`

## 0. Launch Contract
- **Execution:** <shape and native mechanism>; <one-sentence right-sizing reason>
- **Human decision state:** <none needed | one entry per choice: answered—decision, horizon, and source; deferred—decision, option-preserving default or safe boundary, and revisit trigger>
- **One-shot horizon:** <full remaining safe outcome>
- **Review:** <risk tier and falsification check; for nontrivial work, fresh challenge or disclosed fallback>
- **Boot refresh:** <only volatile facts that matter>
- **Hard stops / authority:** <real gates; no generic boilerplate beyond inherited limits>

## 1. Outcome and Done
<Objective and why in 1–3 sentences.>
- [ ] <observable acceptance criterion>
- [ ] <decisive verification criterion>

## 2. Live Truth
- **Status:** <done, in progress, and remaining in compact form>
- **Working state:** <HEAD/upstream/dirty/locks/external state only where relevant>
- **Evidence:** <2–5 load-bearing claim → current source pairs; mark volatile or unknown>
- **Read first:** <small set of real paths/issues with why>

## 3. Decisions and Structure
- <settled human or technical decision and rationale; mark answered human choices as observed and deferred choices with their revisit trigger>
- **Architecture/skeleton:** <first real structural milestone, or “Not applicable — existing path is sufficient.”>

## 4. Verification and Risks
```bash
<smallest decisive check set>
```
<What green proves, what it does not prove, and any real blocker/recovery note.>

## 5. Continuation Mission
- **Start by:** <one concrete move>
- **Continue through:** <short outcome ladder>
- **Keep going until:** <Definition of Done or named hard stop>
````

## Standard / Governed Handoff Template

````markdown
# Handoff: <short outcome-oriented title>

**Date:** <YYYY-MM-DD HH:mm> · **Branch:** `<branch>` · **Author session:** <agent/runtime>

## 0. Receiving Session Contract
> **Main directive:** Own this as the primary execution session. Re-ground in live evidence, use the selected right-sized mechanism, and keep working through the Continuation Mission until Definition of Done or a stated hard stop. Do not stop merely because one milestone or delegated lane finishes.

- **Selected execution shape:** <DIRECT | LEAN | STRUCTURED | METASWARM>
- **Document depth:** <STANDARD | GOVERNED; why COMPACT is insufficient>
- **Framework/native mechanism:** <verified invocation/tooling, or capability plus startup fallback>
- **Why this is the lightest adequate shape:** <dependency, collision, risk, duration, and coordination evidence>
- **Human decision state:** <none needed | one entry per choice: answered—decision, horizon, and source; deferred—decision, option-preserving default or safe boundary, and revisit trigger>
- **Boot checks:** <volatile state, instructions, repo/tracker/lock/runtime refreshes>
- **One-shot horizon:** <largest coherent safe outcome to pursue this session>
- **Review tier and fresh challenge:** <low/medium/high; who or what challenges which claims and when>
- **Upshift/downshift triggers:** <evidence that justifies changing the execution shape>
- **Hard stop conditions:** <approval, product decision, unsafe ambiguity, external blocker, or genuine context boundary>
- **Authority boundaries:** Delegation does not expand scope or permission. No secrets in packets. Preserve all destructive, production, privacy, security, cost, and external-action gates. <Task-specific limits.>

### Optional execution/delegation map
<Use only for LEAN, STRUCTURED, or METASWARM when it adds operational value. For DIRECT write “None — direct execution is the lightest adequate shape.”>

| Lane / milestone | Trigger and dependency | Owner or required capability | Scope / single-writer boundary | Evidence return and review |
|---|---|---|---|---|
| <lane> | <when ready> | <verified role/tool or startup-resolved capability> | <bounded files/area> | <compact result, commands, findings> |

## 1. Objective and Why
<Outcome, user value, and rationale that should not be re-litigated.>

## 2. Definition of Done
- [ ] <observable acceptance criterion>
- [ ] <external proof, when local green is insufficient>

## 3. Current Status

**Done and verified**
- <claim> — evidence: <command/path/commit/source>

**Done, not verified**
- <claim and missing proof>

**In progress / stopped here**
- <exact boundary and why>

**Not started**
- <remaining outcome>

### Working state
- Repo/worktree: `<absolute path>`; branch/upstream: `<values>`
- HEAD/base and ahead/behind: `<values>`; pushed state: <value>
- Dirty files/diff/stashes/recovery: <exact scope or none>
- Active locks/actors/single-writer surfaces: <live evidence or unknown>
- Relevant external state: <observed timestamp/source, volatile refresh, or unknown>

## 4. Truth Ledger and Required Reading

### Load-bearing claims
| Claim | Class | Evidence | Checked | Startup refresh? |
|---|---|---|---|---|
| <claim> | <Observed/Derived/Volatile/Unknown> | <path, command, output, source> | <time> | <yes/no and how> |

### Read before acting
| # | Path / reference | Why it matters | What to inspect |
|---|---|---|---|
| 1 | `<real path:line or issue>` | <reason> | <specific constraint> |

## 5. Key Decisions and Rationale
- **<decision>** — <why; rejected alternatives and tradeoff>. For a human answer, mark it **Observed human decision** and cite the current exchange or durable source. For a deferral, record the safe default or boundary and exact revisit trigger. Revisit only when that trigger or contrary live evidence occurs.

## 6. Architecture / Walking Skeleton Map
- **Existing structure:** <load-bearing boundaries and patterns to preserve>
- **Skeleton or first structural milestone:** <smallest real buildable/runnable end-to-end path, or “not applicable” with reason>
- **Expansion order:** <2–5 outcome-level slices ordered by dependency and value>
- **Avoid:** <speculative abstractions, parallel write collisions, or task-specific traps>

## 7. Verification Loop
```bash
<focused test/check command>
<broader test/build/lint command>
<external readback command when authorized>
```
Expected: <what each command proves and what it does not prove>.

## 8. Open Questions, Risks, and Hard Stops
- <item, owner, evidence needed, and whether it blocks now; do not hide a qualifying Human Leverage Gate decision here after finalization> — or “None known.”

## 9. Continuation Mission
- **Target outcome for this one-shot:** <full safe horizon, not merely the first edit>
- **Start with:** <one concrete action naming the relevant artifact/file/system>
- **Then continue through:** <short outcome ladder; working skeleton or structural proof before detailed expansion when applicable>
- **Keep-going rule:** After each green milestone, select the next unblocked slice, implement, verify, challenge, and continue. Resolve ordinary failures; do not stop for a recap.
- **Completion/stop rule:** Stop only at Definition of Done or a hard stop from Sections 0/8. If context becomes the only limit, write the next Baton from freshly verified state.

## 10. Later Horizons
<Work intentionally outside this one-shot horizon. Keep this outcome-level, not an exhaustive speculative checklist.>
````

## Final Self-Check

- [ ] Could a fresh agent operate from this document without the prior chat?
- [ ] Was the Human Leverage Gate re-run after responses, on later discoveries, and immediately before finalization, with no unnecessary pause for discoverable facts or agent-resolvable engineering uncertainty?
- [ ] Is every answered or deferred human decision recorded separately with its horizon or option-preserving safe boundary, source, and revisit trigger, with no ambiguity or silence treated as deferral?
- [ ] Did the handoff author choose and justify the lightest adequate execution shape?
- [ ] Is the document itself compact, standard, or governed at the lightest adequate depth, without repeated claims or hypothetical future proof?
- [ ] If Metaswarm was selected, is its concrete advantage over lighter shapes evidence-backed and its availability/setup honest?
- [ ] Does the Continuation Mission define the longest coherent safe run, rather than a micro-task that ends after one milestone?
- [ ] For substantial product/feature work, is there a real walking skeleton or structural milestone before detailed expansion? For narrow work, did the handoff avoid needless scaffolding?
- [ ] Are load-bearing claims classified and tied to current evidence, with volatile items scheduled for boot refresh?
- [ ] Did a falsification pass and fresh challenge occur at the right review tier, and were supported findings corrected?
- [ ] Are all paths, issue references, commands, line anchors, and named runtime capabilities real or explicitly unresolved?
- [ ] Are local proof, external proof, uncertainty, rollback/recovery, dirty state, locks, and active actors represented honestly?
- [ ] Are dependencies, write ownership, review points, authority boundaries, and hard stops clear without excessive dispatch boilerplate?
- [ ] Does the closing sentence name the exact file, full continuation mission, and concrete starting move?

## Anti-Patterns

1. **Framework by habit** — selecting Metaswarm, `$efficient-frontier`, or another orchestrator because it exists rather than because the work needs it.
2. **Decision burial** — finalizing the handoff while a qualifying human-owned choice remains unresolved in an open-questions section.
3. **Question theater** — pausing to ask the human for facts or reversible technical choices the agent can verify or decide safely.
4. **Setup-driven planning** — running framework setup before proving that its coordination value repays the overhead.
5. **Orchestration theater** — inventories of agents, models, packets, and waves that do not change execution safety or speed.
6. **Micro-handoff** — defining one small next edit as the whole receiving session when more safe work is already knowable.
7. **Crystal-ball plan** — prescribing every future implementation step before the walking skeleton or live code can teach the next decision.
8. **Empty scaffolding** — generating placeholder layers without a buildable/runnable end-to-end proof.
9. **Self-certification** — accepting the author's or implementer's confidence without contradiction-seeking, independent challenge, and decisive checks.
10. **Snapshot as truth** — presenting a stale commit, tracker, deploy, store, lock, or runtime observation as current without a refresh rule.
11. **Maximum fan-out** — launching overlapping or unready lanes; parallelize only independent work with explicit ownership.
12. **Authority expansion** — using handoff or delegation to bypass approval, sandbox, privacy, security, cost, production, or destructive-action gates.
13. **Vague launch** — “continue the work” or “follow the plan” without a concrete starting move, outcome ladder, verification loop, and stop conditions.
14. **Transcript dump** — copying chat history instead of synthesizing operational truth and decisions.

## Relationship to Other Tools

- Baton serializes task state **out of** a session; project-native “prime” or context-loading mechanisms load state **into** the next one.
- Reference existing plan, tracker, or framework state instead of duplicating it. Live repository and external state outrank persisted summaries.
- Use native platform delegation and project tooling before adding orchestration infrastructure. Select Metaswarm only for work whose coordination needs justify it.
- Capture durable organizational knowledge separately. Baton preserves the transient state and execution contract for this continuation.

## Attribution

Baton is derived from the **handoff** skill in [metaswarm](https://github.com/dsifry/metaswarm) by Dave Sifry (MIT License). It retains the self-contained handoff document and exact closing-sentence contract while generalizing execution across frameworks and runtimes. Baton adds a pre-finalization human leverage gate with explicit defer semantics, a lightest-adequate execution ladder, an evidence-led adversarial review spine, a long one-shot continuation mission, and architecture/walking-skeleton-first guidance for substantial product work. Metaswarm remains an available execution choice when its coordination and governance machinery is justified. See `NOTICE` for full attribution.
