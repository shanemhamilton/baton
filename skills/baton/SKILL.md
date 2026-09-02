---
name: baton
license: MIT
description: Write one self-contained, evidence-backed handoff that preserves every important result, decision, work-in-progress boundary, and next move, then end with one exact "Read XXX.md and do YYY." sentence. Refresh live truth; surface human-owned decisions; rank the receiving Claude or Codex runtime's skills, plugins, tools, subagents, MCP connectors, and model routes; recommend superior missing options; and queue exact activation and task-to-model plans. Prefer authoritative MCP and capable-model orchestration through efficient-frontier, ponytail, and applicable specialists. Assign every task to the least expensive and fastest reliable model tier; never spend a frontier model on legwork Haiku, Sonnet, or an equivalent efficient route can own. Use when ending or compacting a session, switching machines or sessions, wrapping up, or handing work to a fresh session. Harness- and project-agnostic; preserve all scope and approval gates.
---

# Baton — Handoff Skill

Pass the baton cleanly. Capture the complete operational truth, all important progress, and every load-bearing decision a **fresh agent with zero prior chat context** needs, then give it a capability-aware continuation mission designed to resume at the exact stopping point and make the maximum safe, verified progress in one uninterrupted session.

End with one unambiguous sentence:

> **Read `docs/handoffs/<file>.md` and do the continuation mission through its stop conditions, starting by `<the first concrete move as a gerund phrase>`.**

Treat the handoff as an evidence-backed launchpad, not a frozen transcript or an exhaustive prediction of every future edit. The guarantees below apply across Claude, Codex, other compatible harnesses, and all projects; implement them with the capabilities the current environment actually exposes without weakening higher-priority permissions or safety rules. Never assume that a capability installed or authenticated in one harness is available in another.

## Core Rules

1. **Re-ground in live truth.** Verify repository, tracker, runtime, lock, and external state before recording it. Mark facts, inferences, volatile claims, and unknowns distinctly.
2. **Leave no important work behind.** Sweep the full session, working state, delegated work, and relevant external systems. Capture every material completed result, unverified result, work in progress, pending change, decision and rationale, failed approach worth not repeating, artifact, blocker, and remaining obligation. Summarize operationally; do not dump the transcript. Anything the handoff calls done or delivered exists on disk, in a tracker, or in a commit or PR body; a chat-only mention is not a record. When publication is gated, write the draft to a local untracked file and name that path.
3. **Preserve momentum exactly.** Record the exact stopping point, safest next concrete move, active processes or actors, dirty/recovery state, and what must not be rediscovered or redone. The receiving session refreshes volatile facts, then continues from that boundary instead of restarting the investigation or re-litigating settled decisions.
4. **Discover, rank, and queue the best capabilities.** Inspect the actual Claude, Codex, or other receiving runtime for relevant skills, plugins, tools, subagents, apps, and connectors instead of relying only on project settings or remembered inventories. Rank usable and installable paths by end-to-end efficiency, task coverage, provenance, reliability, permissions, auditability, and context overhead. Prefer an available, authenticated, authoritative MCP connector for the system it exposes. If the best relevant option is not installed or connected, research current availability and ask the human to install or authorize it; if deferred, preserve the best verified fallback. Queue exact startup use and fallbacks in the handoff, with special attention to `efficient-frontier`, `ponytail`, and any more specific efficiency or domain skill that is available and applicable.
5. **Right-size every model assignment.** Assign each task or lane to the least expensive, fastest available model tier that can complete it reliably. Keep frontier models on architecture, prioritization, ambiguity, consequential risk, integration, synthesis, and final review. Never use a frontier model for search, inventory, extraction, summarization, log reduction, test execution, formatting, or bounded mechanical coding that an efficient route such as Claude Haiku/Sonnet or the equivalent Codex fast/balanced tier can perform. Every frontier execution assignment requires a written exception explaining why a lower tier is insufficient.
6. **Choose the most efficient adequate execution shape.** Account for coordination overhead, main-model opportunity cost, dependency structure, risk, and available native mechanisms. Do not default to maximum fan-out or heavy framework state merely because it is installed.
7. **Keep an adversarial spine.** Use evidence checks, contradiction-seeking, and fresh independent challenge in proportion to risk. Never treat an agent's confidence as proof.
8. **Surface high-leverage human decisions before finalizing.** If a small number of human-owned choices would materially change the outcome, design, risk posture, or useful execution horizon, pause with concise options, a recommendation, and an explicit defer path. Do not ask the human to decide facts or reversible engineering details the agent can resolve.
9. **Optimize for a long one-shot run.** Give the receiving session a full safe execution horizon, milestone sequence, verification loop, and explicit stop conditions. Do not tell it to finish one small step and stop unless that step completes the task.
10. **Build structure before detail when the work warrants it.** For greenfield or substantial cross-cutting product work, establish a minimal working architectural or end-to-end skeleton, prove that the pieces connect, and then expand the highest-value parts. Do not create empty boilerplate for a narrow fix or mature code path.
11. **Preserve authority.** A handoff, connector, plugin, or delegation never expands user scope, permissions, budget, or approval. Keep destructive, irreversible, production, privacy-, security-, and cost-sensitive actions behind their existing gates.

## Output Contract

Produce exactly two deliverables. A session never ends without both, including non-interactive, scheduled, and subagent runs.

1. **One handoff document** at `docs/handoffs/handoff-<YYYY-MM-DD-HHmm>.md`. Create the directory when needed. Write the file **before** asking the human anything; a pending question changes what the file says, never whether it exists. Make the document compact enough to orient quickly and complete enough to operate without the prior chat. The document's last line is the closing sentence itself, so the mission survives even if the chat does not.
2. **One closing sentence**, with nothing after it, quoting the last line of the file:

   ```text
   Read docs/handoffs/handoff-2026-06-17-1432.md and do the continuation mission through its stop conditions, starting by establishing the tested CLI walking skeleton described there.
   ```

Use a shorter `Read ... and do ...` form only when the entire remaining task is genuinely narrow. Never end with “continue the work,” “follow the plan,” or another vague theme. In a multi-repository or worktree session, use the absolute path and name the owning repository in Section 0.

Never put credentials, tokens, session cookies, or authentication state into the file. Cite absolute paths only where the receiver needs them.

An interim human-decision pause (Step 3) delays finalizing, not writing. While a question is open the file carries the line `Status: DRAFT — awaiting human answer` in Section 0; finalizing removes it. If no answer can arrive, Step 3's terminator applies and both deliverables are still produced.

## Method

### Step 1 — Reconstruct the mission

State:

- **Objective and why** — what outcome the user wants and why settled decisions matter.
- **Definition of Done** — observable acceptance criteria, including external proof that local tests cannot establish.
- **Current execution horizon** — the largest coherent, safe body of work the next session can pursue without needing a new product decision or approval.
- **Hard stop conditions** — the exact events that require the user, an external-state change, a safety gate, or a new handoff.
- **Continuity boundary** — the exact point where useful work stopped, the next concrete move, and the investigation, decision, or completed work the receiver must not repeat.

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

Sweep beyond the main happy path before declaring the inventory complete: review session-visible changes and outputs, delegated or background work, test and build results, failed approaches whose lesson matters, temporary or uncommitted artifacts, pending external actions, and adjacent obligations the user placed in scope. Record only material continuity facts, but omit none merely because they do not fit the latest subtask.

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

A verified superior connector, plugin, or MCP path that is relevant but not installed or authorized is a human-owned setup choice. If Step 4 discovers one, immediately re-run this gate to recommend the optimal option and ask the human to install/connect it before the final handoff. If the human defers, record the best currently usable fallback and the exact point at which the missing integration should be reconsidered.

When one or more choices qualify:

1. Complete all safe read-only preparation that can sharpen the decision.
2. Ask only the one to three highest-leverage questions. For each, state why it matters, the practical effect of the viable options, the recommended default, and exactly what **defer** would mean.
3. Write the handoff file first with `Status: DRAFT — awaiting human answer` in Section 0, then ask. Present nothing as final until the human answers, revises the options, or explicitly defers.
4. Classify the response explicitly. An **answer** settles the choice for the stated one-shot horizon. “Use your recommendation” counts as an answer only when the recommended option and its horizon are explicit. A **defer** intentionally leaves the choice open and must name a safe boundary plus revisit trigger. Partial or ambiguous responses get one concise follow-up within the same round. Silence is not an answer; the terminator below handles it.
5. If answered, record the result as an **Observed human decision** and resume from the now-settled execution horizon.
6. If deferred, record who deferred it and the concrete revisit trigger. A recommendation is not authorization: use a recommended default only when existing authority permits it **and** it is option-preserving, low-cost to reverse, and does not prejudice the eventual outcome, architecture, or data ownership. Otherwise narrow the continuation mission to the safe work that ends before the decision boundary.
7. Re-run this gate whenever later capability research, framework, architecture, evidence, or adversarial analysis reveals a new qualifying choice, and once immediately before finalizing the handoff, but never open a second question round; a choice discovered after the round is recorded as deferred by absence. The gate is clear when every qualifying choice is answered, explicitly deferred, or deferred by absence.

**Terminator.** Ask at most one round of one to three questions, once. If the session is non-interactive (`claude -p`, `codex exec`, a scheduled run), if you are running as a subagent with no channel to the human, or if the round produces no answer, record every unresolved choice in Section 0 as **deferred by absence** with its option-preserving default and revisit trigger, remove the DRAFT line, and finalize both deliverables. A blocked handoff is a failed handoff.

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

### Step 4 — Discover capabilities and select the receiving execution shape

Inventory the capabilities relevant to the continuation across the whole receiving runtime, not only the repository: Claude or Codex skill catalogs, installed plugins, native tools, subagent and model routes, apps, MCP servers/connectors, project-native commands, and specialized review or domain workflows. Use that harness's actual discovery and connection mechanisms. Do not infer availability or authentication from a remembered path, a different harness, a previous session, or a plugin recommendation.

Rank each relevant system-access path from most to least efficient for the actual mission. This is a default ladder, not a substitute for checking operation coverage and permissions:

1. **Authoritative structured connector** — an official or otherwise authoritative MCP server, native app, or plugin that supports the needed operation with scoped authentication and structured results.
2. **Maintained specialized connector** — a trusted, actively maintained MCP server, app, or plugin with strong task coverage when no authoritative option fits.
3. **Vendor-native CLI, SDK, or API** — supported structured access that is already available or can be used without creating custom integration code.
4. **Browser or desktop UI automation** — use the product interface when structured access is unavailable or cannot perform the operation.
5. **Manual transfer or custom glue** — pasted exports, hand-transcribed state, scraping, or new integration code only when higher tiers are unavailable or materially unfit.

Within a tier, prefer the option that is already authenticated and has the least setup, permission, token/context, and operational overhead. A higher tier does not win when it lacks the required operation, requests unjustified access, has weak provenance or maintenance, or is less reliable for the task. Record that evidence rather than assuming “MCP” alone makes an option optimal.

Before settling for tiers 3–5 or declaring a connector unavailable, research current options in the receiving harness's plugin/connector catalog, the provider's official documentation and integration directory, and then a trusted registry or maintained third-party source if needed. Prefer primary sources. Record the checked date, provider/maintainer, supported operations, required permissions, install/connect method for Claude or Codex as applicable, and source. Do not ask the human to paste data or accept a manual workaround until this search is complete.

If a higher-ranked relevant option exists but is not installed or connected, **always recommend the optimal option** and route the installation/authorization through the Human Leverage Gate. Explain the concrete efficiency gain, permissions and trust implications, exact supported setup path for the receiving harness, currently usable fallback, and what deferral costs. Never install, connect, or broaden permissions without user authority. Continue safe preparation while waiting; finalize with the fallback only after the human explicitly defers.

Use an available, authenticated MCP connector as the default path to the external system it owns when it provides the required read or action. This usually avoids browser choreography, lossy copy/paste, and custom API glue. Fall back to the next most direct verified mechanism when the connector lacks the needed operation, is unauthenticated, or would cross an authority boundary. During handoff creation, use relevant read-only connectors to refresh load-bearing external state when permitted.

Build a **capability activation plan** for the receiving session. For each consequential capability, record its rank, verified name and source, installed/authenticated state in the receiving harness, what it will do, the first milestone that uses it, the exact invocation or selection mechanism when known, and a graceful fallback. Explicitly evaluate `efficient-frontier` for capable-model orchestration, `ponytail` for the smallest correct implementation, and any more specific installed skill or connector that improves the mission. Name skills by bare name; record an invocation only for the receiving harness and only after verifying it there (`/name` or the Skill tool in Claude Code, `$name` in Codex, plugin-namespaced forms such as `ponytail:ponytail` where the harness lists them). Queue them when applicable; do not list them decoratively. The receiver must activate the queued skills before task work and use each planned connector at its first relevant operation unless boot-time evidence invalidates it, in which case it records the substitution in the handoff or the commit message and continues.

Run the **Model Efficiency Gate** before selecting the execution shape:

1. Name a model route only from a mechanism you can point at. Codex exposes its catalog in `~/.codex/models_cache.json` (slug, display name, description). Claude Code exposes no route catalog, so name the model family (Haiku-class, Sonnet-class, frontier) and let the receiver resolve it. Record the source next to every route and tag the row `Volatile`. If no mechanism exists, write `route: unknown` rather than a plausible-looking ID. Treat IDs, prices, and availability as volatile and require a boot-time refresh.
2. Classify every execution lane by the lowest capability tier that can meet its accuracy, context, tool-use, and risk requirements:
   - **FAST / ECONOMY** — deterministic or easily checked legwork: repository and web search, inventory, document extraction, classification, formatting, test execution, log reduction, and simple low-risk transformations. Prefer the current Claude Haiku-class or Codex fast/economy route.
   - **BALANCED / WORKHORSE** — bounded implementation, refactors, debugging from a known reproduction, focused analysis, test repair, and ordinary review. Prefer the current Claude Sonnet-class or Codex balanced coding route.
   - **FRONTIER / JUDGMENT** — architecture, genuinely ambiguous planning, consequential security/money/privacy decisions, cross-lane conflict resolution, integration, synthesis, and final adversarial review. Use the strongest available model only for these judgment-bearing parts.
3. Assign a concrete tier and available model route to every lane. The frontier orchestrator owns decomposition, dependencies, acceptance criteria, integration, and review; efficient workers own the execution legwork.
4. For every `FRONTIER` execution assignment, record **why FAST and BALANCED are insufficient**. If that field is empty or only says “quality,” down-route the lane. Existing use of a frontier main session is not itself justification.
5. Escalate one tier only after concrete evidence shows the assigned tier is insufficient: a failed stop condition, missing capability, repeated incorrect output, or unresolved ambiguity. Do not jump from FAST to FRONTIER, and do not silently promote work because a preferred lower-tier model is unavailable; select an equivalent route or record the constraint.

This gate is mandatory for every nontrivial handoff. If the harness cannot select or delegate to lower-cost models, record that limitation and the desired route so the human or receiving environment can enable it. Do not disguise unavailable routing as an efficiency decision.

The handoff author must then choose and justify the **most efficient shape that can reliably complete the execution horizon**. When a high-capability main model can delegate independent bounded lanes, prefer `LEAN` or `STRUCTURED`: reserve its context for planning, architecture, synthesis, integration, and final review while appropriate workers perform token-heavy research, inventory, mechanical coding, and test execution. Use `DIRECT` when the mission is genuinely tiny, inseparable, or faster and safer in one context, but run that direct context on the lowest sufficient model tier. A DIRECT shape is never a frontier-legwork exception. The receiving agent validates availability and live assumptions at boot; it changes shape only when live evidence invalidates the choice, and records why.

| Shape | Select when | Minimum safety mechanism |
|---|---|---|
| **DIRECT** | Work is tiny, tightly coupled, immediate-blocker-bound, or demonstrably fastest and safest in one context running the lowest sufficient model tier. | Deterministic checks plus a separate contradiction pass; use a fresh read-only challenger when the task is nontrivial and one is available. |
| **LEAN** | A capable main model plus roughly 1–3 independent native workers/reviewers improves speed, cost, or quality without persistent orchestration state. This is the normal choice for delegable nontrivial work. | Disjoint ownership, compact evidence returns, central integration, and one fresh independent review. |
| **STRUCTURED** | Several dependent phases, cross-cutting architecture, or multiple review waves benefit from an existing plan/orchestration skill and a capable central orchestrator, but full swarm machinery is unnecessary. | Explicit dependencies, single-writer boundaries, milestone gates, central synthesis, and fresh review at integration points. |
| **METASWARM** | Sustained parallel workstreams, multiple writers, formal governance gates, locks/ownership, or durable cross-session coordination make its setup and state machinery materially safer or faster than the lighter shapes. | Follow its verified project setup and native gates; retain central evidence checks and user authority. |

Choose execution shape and review tier independently. A narrow security repair may be `DIRECT` with high-risk review; a broad low-risk scaffold may be `STRUCTURED` with medium-risk review. Complexity determines coordination weight. Consequence and uncertainty determine adversarial depth.

Before selecting `DIRECT` for nontrivial work with a capable main model, state why delegation would lose more context, time, or reliability than it saves and name the lower-tier direct route. Before selecting `METASWARM`, answer explicitly:

- What concrete coordination failure would `DIRECT`, `LEAN`, or `STRUCTURED` leave unmanaged?
- Which verified Metaswarm capability addresses that failure?
- Is Metaswarm already usable here, or is setup cost part of the justified horizon?
- Do the parallelism, duration, governance, and collision risks repay that overhead?

If those answers are weak, choose `LEAN` or `STRUCTURED`. Never run Metaswarm's setup (`/metaswarm:setup` in Claude Code, or its Codex equivalent) just to make a handoff look complete.

Record the chosen framework or native mechanism, verified invocation if known, agent/runtime constraints that matter, and a graceful fallback. Keep the inventory task-relevant: do not pin every possible model or list tools with no planned use. Name a specialist, connector, tool, skill, or model only when verified and consequential; otherwise state the required capability and let the receiving runtime resolve it.

### Step 5 — Design the longest safe one-shot run

Plan an **outcome ladder**, not a line-by-line script:

1. **Boot, activate, and re-ground** — load every queued skill, verify planned MCP/connectors, worker routes, and model assignments, refresh volatile state, instructions, permissions, dependencies, and the selected framework's availability. Down-route any lane assigned above its lowest sufficient current tier. Start from the recorded continuity boundary; do not redo settled discovery.
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

### Step 8 — Check the file, then emit the closing sentence

Run these checks against the written file before emitting anything, and fix every FAIL first. If the project ships `evals/check.sh` from the Baton repository, run `bash evals/check.sh --root <repo-root> <file>` instead. When no shell is available, perform each check by reading and say so in Section 0.

```bash
f=docs/handoffs/handoff-<YYYY-MM-DD-HHmm>.md
test -s "$f" || echo "FAIL missing file"
grep -qi 'Status: DRAFT' "$f" && echo "FAIL draft line still present"
for k in 'Document depth:' 'Human decision state:' 'Continuation Mission'; do grep -q "$k" "$f" || echo "FAIL missing $k"; done
grep -oE '`[^` ]+`' "$f" | tr -d '`' | grep -E '/|\.[a-z]+$' | grep -vE '^(<|https?:|docs/handoffs/|origin/|upstream/|refs/)' \
  | sed -E 's/:[0-9]+(-[0-9]+)?$//' | sort -u | while read -r p; do test -e "${p/#\~/$HOME}" || echo "FAIL path not found: $p"; done
tail -n 1 "$f" | grep -qE "^\**Read .*$(basename "$f").* and do .+\.\**$" || echo "FAIL last line is not the closing sentence naming this file"
grep -nE '\|[[:space:]]*(Believed|Stale|Assumed|Inferred)[[:space:]]*\|' "$f" && echo "FAIL class word outside Observed/Derived/Volatile/Unknown"
```

Then re-read the file once as the receiver would, and emit the last line of the file as the only output, with nothing after it. Make the first move concrete and the mission horizon clear.

✅ `Read docs/handoffs/handoff-2026-06-17-1432.md and do the continuation mission through its stop conditions, starting by running the failing payments test.` — and the session ends there.

❌ The same sentence followed by “I've written the handoff covering…” — trailing text breaks the contract even when the sentence itself is correct.

## Compact Handoff Template

Use this instead of the standard template for `COMPACT` depth. Omit empty optional bullets rather than expanding “None” into prose.

````markdown
# Handoff: <short outcome-oriented title>

**Date:** <YYYY-MM-DD HH:mm> · **Repo/branch:** `<absolute path>` / `<branch>`

## 0. Launch Contract
> **Main directive:** Own this as the primary execution session. Re-ground volatile facts without repeating settled work, then keep working through the Continuation Mission until Definition of Done or a stated hard stop. Do not stop because one step finishes.

- **Document depth:** COMPACT
- **Execution:** <shape and native mechanism>; <one-sentence right-sizing reason>
- **Capability activation:** <ranked skills/plugins/tools/MCP connectors to load or use at boot, first use, and fallback; include efficient-frontier and ponytail when available/applicable>
- **Model routing:** <each lane → FAST/Haiku-class, BALANCED/Sonnet-class, or FRONTIER; exact available route, escalation trigger, and any justified frontier exception>
- **Recommended install/connect:** <highest-ranked relevant missing option, research source, Claude/Codex setup path, permissions, and human answer; or none>
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
- **Momentum checkpoint:** <exact stop point, next move, active work, and what not to redo>
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

---
Read docs/handoffs/handoff-<YYYY-MM-DD-HHmm>.md and do <the continuation mission>, starting by <first concrete move as a gerund phrase>.
````

## Standard / Governed Handoff Template

````markdown
# Handoff: <short outcome-oriented title>

**Date:** <YYYY-MM-DD HH:mm> · **Branch:** `<branch>` · **Author session:** <agent/runtime>

## 0. Receiving Session Contract
> **Main directive:** Own this as the primary execution session. Activate the queued capability plan, re-ground volatile facts without repeating settled work, use the selected efficient mechanism, and keep working through the Continuation Mission until Definition of Done or a stated hard stop. Do not stop merely because one milestone or delegated lane finishes.

- **Selected execution shape:** <DIRECT | LEAN | STRUCTURED | METASWARM>
- **Status:** <omit when final; while a human question is open: Status: DRAFT — awaiting human answer>
- **Document depth:** <STANDARD | GOVERNED; why COMPACT is insufficient>
- **Owning repository:** <absolute path when the session spans repositories or worktrees; omit otherwise>
- **Framework/native mechanism:** <verified invocation/tooling, or capability plus startup fallback>
- **Why this is the most efficient adequate shape:** <dependency, collision, risk, duration, coordination overhead, and main-model opportunity-cost evidence>
- **Human decision state:** <none needed | one entry per choice: answered—decision, horizon, and source; deferred—decision, option-preserving default or safe boundary, and revisit trigger>
- **Boot checks:** <volatile state, instructions, repo/tracker/lock/runtime refreshes>
- **One-shot horizon:** <largest coherent safe outcome to pursue this session>
- **Review tier and fresh challenge:** <low/medium/high; who or what challenges which claims and when>
- **Upshift/downshift triggers:** <evidence that justifies changing the execution shape>
- **Hard stop conditions:** <approval, product decision, unsafe ambiguity, external blocker, or genuine context boundary>
- **Authority boundaries:** Delegation does not expand scope or permission. No secrets in packets. Preserve all destructive, production, privacy, security, cost, and external-action gates. <Task-specific limits.>

### Capability activation plan

| Rank / capability | Source and receiving-harness state | Purpose and first use | Startup action | Fallback |
|---|---|---|---|---|
| <tier; MCP connector, skill, plugin, tool, worker/model route> | <provider/source/date; installed/authenticated state in Claude or Codex> | <specific role and milestone> | <exact invocation, install/connect decision, or selection> | <next direct verified mechanism> |

Include only capabilities with a real job. Rank and queue authoritative MCP connectors first, capable-model orchestration through `efficient-frontier` when available/applicable, `ponytail` for minimum correct implementation, and more specific installed skills before generic or custom work. If the optimal relevant path is missing, record the researched Claude/Codex install recommendation, human answer, and fallback.

### Model assignment matrix

<Required for every nontrivial handoff. Resolve exact available routes at boot; use family names such as Haiku or Sonnet only as capability-class examples, not proof of availability.>

| Lane / task | Work class and risk | Assigned tier / model route | Why this is the lowest sufficient tier | Escalation trigger | Frontier exception |
|---|---|---|---|---|---|
| <lane> | <deterministic legwork, bounded coding, or judgment-bearing work> | <FAST, BALANCED, or FRONTIER; verified route> | <capability/verification fit> | <evidence required to move up one tier> | <why lower tiers are insufficient, or none> |

No task may default to the main model merely because it already owns the session. Search, inventory, extraction, summarization, log reduction, test execution, formatting, and mechanical edits belong to FAST or BALANCED routes whenever the runtime exposes a sufficient one.

### Optional execution/delegation map
<Use only for LEAN, STRUCTURED, or METASWARM when it adds operational value. For DIRECT write “None — direct execution is the most efficient adequate shape because <specific reason>.”>

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

**Continuity / do not redo**
- <settled investigation, decision, completed lane, failed approach, or recovered state the receiver must preserve; exact next move>

**Not started**
- <remaining outcome>

### Working state
- Repo/worktree: `<absolute path>`; branch/upstream: `<values>`
- HEAD/base and ahead/behind: `<values>`; pushed state: <value>
- Dirty files/diff/stashes/recovery: <exact scope or none>
- Active locks/actors/single-writer surfaces: <live evidence or unknown>
- Relevant external state: <observed timestamp/source, volatile refresh, or unknown>
- Active/background work: <processes, delegated lanes, tool sessions, drafts, or none; owner and recovery/continuation action>

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

---
Read docs/handoffs/handoff-<YYYY-MM-DD-HHmm>.md and do the continuation mission through its stop conditions, starting by <first concrete move as a gerund phrase>.
````

## Final Self-Check

- [ ] Could a fresh agent operate from this document without the prior chat?
- [ ] Does it account for every material result, decision, work-in-progress boundary, artifact, delegated/background lane, failed approach worth preserving, blocker, and remaining obligation from the session—not merely the latest subtask?
- [ ] Is the exact continuity boundary explicit: where work stopped, what happens next, what remains active or recoverable, and what must not be rediscovered, re-litigated, or redone?
- [ ] Was the Human Leverage Gate re-run after responses, on later discoveries, and immediately before finalization, with no unnecessary pause for discoverable facts or agent-resolvable engineering uncertainty?
- [ ] Is every answered or deferred human decision recorded separately with its horizon or option-preserving safe boundary, source, and revisit trigger, with no ambiguity or silence treated as deferral?
- [ ] Did the handoff author inspect the runtime's relevant skills, plugins, tools, subagents, apps, and MCP connectors; verify rather than assume availability; and queue each consequential capability with its first use and fallback?
- [ ] Were system-access options ranked by task fit, end-to-end efficiency, provenance, reliability, permissions, auditability, and context overhead rather than installation state alone?
- [ ] Before accepting a CLI, browser, manual, or custom path, did the author research better current options in the receiving Claude/Codex catalog and provider-primary sources?
- [ ] If the optimal relevant connector/plugin is available but missing, did the author recommend its receiving-harness-specific installation, disclose permissions/trust and efficiency tradeoffs, obtain an answer or explicit defer, and preserve the fallback?
- [ ] Are authoritative MCP connectors preferred for the systems they expose, with authentication/authority limits and non-MCP fallbacks represented honestly?
- [ ] Were `efficient-frontier`, `ponytail`, and more specific available skills explicitly evaluated and queued when applicable rather than merely named?
- [ ] Does every nontrivial execution lane have a verified FAST, BALANCED, or FRONTIER assignment using the least expensive and fastest tier that can complete it reliably?
- [ ] Are Haiku-class/fast routes assigned deterministic legwork and Sonnet-class/balanced routes assigned bounded coding and analysis whenever those routes are sufficient and available?
- [ ] Is every frontier execution assignment limited to judgment-bearing work and accompanied by concrete evidence that FAST and BALANCED are insufficient?
- [ ] Do escalation rules move up only one tier after an observable failure or capability gap instead of promoting work preemptively?
- [ ] When the main model is materially more capable and work is delegable, does the plan preserve it for orchestration, synthesis, integration, and review rather than execution legwork?
- [ ] Did the handoff author choose and justify the most efficient adequate execution shape?
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
- [ ] Did the Step 8 checks pass on the written file, is the closing sentence its last line, and is no `Status: DRAFT` line left?

## Anti-Patterns

1. **Capability blindness** — choosing a continuation shape from project files alone without checking the runtime's useful skills, plugins, tools, workers, apps, and MCP connectors.
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
15. **Frontier legwork** — spending a frontier model on search, inventory, extraction, summarization, logs, test execution, formatting, or bounded mechanical work that a verified FAST or BALANCED route can own.
16. **Decorative capability queue** — naming MCP, `efficient-frontier`, `ponytail`, or another skill without assigning its first real use, startup action, and fallback.
17. **Progress amnesia** — capturing the current plan but omitting completed side work, the exact stop point, active/background lanes, recovery state, failed approaches, or what must not be redone.
18. **Installed-is-best bias** — choosing a lower-efficiency path only because it is already configured, without researching and recommending a superior relevant option.
19. **Harness leakage** — assuming a Claude connector, skill invocation, authentication, or installation path works in Codex, or vice versa, without verifying and recording the receiving runtime's setup.
20. **Manual-workaround reflex** — asking for pasted data, browser choreography, or custom integration code before searching provider-primary sources and the runtime's connector/plugin catalog.
21. **One-model handoff** — assigning every lane to the session's main model without task-by-task capability and cost classification.
22. **Frontier by default** — selecting the strongest model without documenting why both FAST and BALANCED tiers are insufficient.
23. **Escalation leap** — jumping directly from a failed economy lane to frontier instead of trying the balanced workhorse tier or an equivalent route.

## Relationship to Other Tools

- Baton serializes task state **out of** a session; project-native “prime” or context-loading mechanisms load state **into** the next one.
- Reference existing plan, tracker, or framework state instead of duplicating it. Live repository and external state outrank persisted summaries.
- Prefer an available authenticated MCP connector for the system it authoritatively exposes, then fall back to the next direct verified mechanism. A connector never expands authority.
- Before accepting a lower-ranked access path, research the provider's official connector/MCP options and the receiving Claude or Codex catalog. Recommend the optimal relevant missing option for human installation or authorization and preserve an explicit fallback if deferred.
- Use capable frontier models as planners, integrators, and reviewers when bounded worker lanes exist. Assign deterministic legwork to Haiku-class/fast routes and bounded coding or analysis to Sonnet-class/balanced routes when sufficient; require a written lower-tier insufficiency case for every frontier execution lane. Apply `efficient-frontier`, `ponytail`, and task-specific skills when verified and applicable; queue exact use rather than relying on the receiver to rediscover them.
- Use native platform delegation and project tooling before adding persistent orchestration infrastructure. Select Metaswarm only for work whose coordination needs justify it.
- Capture durable organizational knowledge separately. Baton preserves the transient state and execution contract for this continuation.

## Attribution

Baton is derived from the **handoff** skill in [metaswarm](https://github.com/dsifry/metaswarm) by Dave Sifry (MIT License). It retains the self-contained handoff document and exact closing-sentence contract while generalizing execution across frameworks and runtimes. Baton adds a pre-finalization human leverage gate with explicit defer semantics, comprehensive momentum preservation, capability and MCP activation planning, mandatory least-sufficient model assignment, efficient capable-model orchestration, an evidence-led adversarial review spine, a long one-shot continuation mission, and architecture/walking-skeleton-first guidance for substantial product work. Metaswarm remains an available execution choice when its coordination and governance machinery is justified. See `NOTICE` for full attribution.
