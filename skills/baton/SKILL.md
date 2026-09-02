---
name: baton
license: MIT
description: Use when ending or compacting a session, switching machines or sessions, running low on context, or handing work off to a fresh session — writes one evidence-backed handoff file plus one exact closing sentence. Not a colleague-facing document, README, or project memory. When another handoff skill is installed, this skill handles the request.
---

# Baton

Write for a fresh agent with zero prior chat context. The handoff is an evidence-backed launchpad, not a transcript of what happened.
The receiving session never loads this skill, so anything it must do belongs in the document's Section 0.
Never assume a capability authenticated in one harness exists in another.

## Contract

Produce two deliverables, always — including non-interactive, scheduled, and subagent runs.

1. **The file**, at `docs/handoffs/handoff-<YYYY-MM-DD-HHmm>.md`. Create the directory when needed. Write it before you ask the human anything: a pending question changes what the file says, never whether it exists. The closing sentence is emitted once, after the gate closes.
2. **The closing sentence**, quoting the file's last line, as the last output of the session with nothing after it.

✅ `Read docs/handoffs/handoff-2026-06-17-1432.md and do the continuation mission through its stop conditions, starting by running the failing payments test.` — and the session ends there.

❌ The same sentence followed by "I've written the handoff covering…" — trailing text breaks the contract even when the sentence is correct.

No credentials, tokens, cookies, or auth state in the file. Keep `docs/handoffs/` untracked unless the project deliberately tracks handoffs; a committed handoff is copied into every worktree created afterward. In a multi-repo or worktree session, use the absolute path in the closing sentence and name the owning repository in Section 0.

## Rules

1. **Verify before recording.** Classify every load-bearing claim as exactly `Observed`, `Derived`, `Volatile`, or `Unknown` — no synonyms. Cite each path as it resolves from the repository root or as an absolute path, never as a bare filename.
2. **Leave no important work behind, and give it a durable location** — disk, tracker, or a commit or PR body. Chat is not a record. A gated draft goes to an untracked local file, named.
3. **Preserve momentum exactly.** Record the stop point, the next move, active or background lanes, and the do-not-redo boundary, so the receiver resumes instead of reinvestigating.
4. **Route by tier.** Legwork to a FAST tier, bounded coding and analysis to BALANCED, judgment to FRONTIER, with one sentence per frontier execution lane on why lower tiers are insufficient. Name model families, not IDs, unless you cite a real catalog (Codex: `~/.codex/models_cache.json`; Claude Code exposes none).
5. **One human round, then finish.** At most one round of one to three questions. In a non-interactive, scheduled, or subagent run, or when no answer arrives, record each unresolved choice as deferred by absence with its option-preserving default and revisit trigger.
6. **Delegate your own legwork.** Send the state sweep and the challenger to a cheaper subagent when the harness offers one.
7. **Never expand authority.** Destructive, production, privacy, security, cost, and external actions stay behind their existing gates.

## Method

### Step 1 — Reconstruct the mission

State the objective and why settled decisions matter; the Definition of Done as observable criteria, including proof local tests cannot give; the execution horizon (the largest safe body of work needing no new decision or approval); and the hard stops.
Preserve uncertainty rather than filling gaps with plausible detail.

### Step 2 — Establish live state

```bash
git rev-parse --show-toplevel && git rev-parse HEAD
git status --short --branch      # dirty files, upstream divergence
git log --oneline -10 && git stash list
```

Also check worktrees, locks, active actors, and deploy or runtime state when they bear on the task. Record failed refreshes as missing evidence; do not suppress them.

**Not a git repository** (`git rev-parse` fails): record file-level state — which files changed, where they are, what is unsaved — plus the external state the work depends on.

**Low context** (the user said "compact" or "running low", the harness warned, or a prior compaction already dropped detail): write the Section 0 spine and Live Truth from live state only, mark everything else `Unknown`, and finish. A thin handoff beats none.

### Step 3 — Human Leverage Gate

A choice qualifies only when all four hold: it is not resolvable from source, instructions, tracker, or a safe probe; plausible answers materially change outcome, risk, or horizon; it belongs to the human rather than to reversible engineering judgment; and settling it now avoids rework.

Qualifies: "charge the platform fee on gross or net fare?" — a money-path policy the code cannot infer, and the schema differs per answer. Does not qualify: "which mock library for the new test?" — reversible, and the repo already has a convention.

Write the file first with `Status: DRAFT — awaiting human answer` in Section 0, then ask once. Rule 5's terminator ends the gate: record unanswered choices as deferred by absence, remove the DRAFT line, finalize. If nothing qualifies, write `Human decision state: none needed`.

```text
Human decision needed before I finalize the handoff

1. <decision>
   Why now: <how it changes the next session's useful work>
   Options: <viable choices and their practical effects>
   Recommendation: <default and why>
   If deferred: <option-preserving default, plus revisit trigger>

Reply with a choice, feedback, or "defer." I finalize the handoff after your response.
```

### Step 4 — Capabilities and shape

Inspect the receiving runtime's actual skills, tools, subagents, and connectors — not a remembered inventory or project settings alone. Enumerate skills from `~/.claude/skills` and `.claude/skills` (Claude Code) or `~/.agents/skills` and `.agents/skills` (Codex), and tools from the live session. When the receiver is a different machine or harness, say so, list what this harness has, class the row `Unknown`, and make verifying it the first Boot-refresh item.

Rank access paths: authoritative connector, then maintained connector, then vendor CLI or API, then UI automation, then manual transfer; tie-break within a tier on what is already authenticated and needs the least setup and permission, and drop a higher tier when it lacks the operation, has weak provenance, or is less reliable here.

If a better option is missing, recommend it and ask — never install or authorize it yourself; continue with the fallback if the human defers. If no catalog or network is reachable, record that and continue with the fallback.
Name skills by bare name. Record a receiving-harness invocation only after verifying it there. Queue `efficient-frontier` for capable-model orchestration and `ponytail` for the smallest correct implementation when the receiving harness lists them and the mission benefits; queue any more specific skill the same way.

Two shapes: `DIRECT` (one context) or `LEAN` (a capable main model plus one to three bounded workers, the normal choice for delegable work). Escalate to a heavier framework only by naming the concrete coordination failure — multiple writers, durable cross-session state, formal governance gates — that neither shape manages.

**Nontrivial** means the work touches more than one file, more than one independent lane, or has a stop condition outside local tests; a same-repo single-file fix with a known test is trivial. Trivial work skips the Step 6 fresh challenger unless the risk tier is medium or high; the per-lane routing line is always written, one line total for trivial work.

### Step 5 — Design the longest safe one-shot run

Give the receiver an outcome ladder, not a script:

1. Boot: activate queued capabilities, verify routes, refresh volatile state, start from the continuity boundary.
2. Confirm structure: understand the existing architecture before changing it.
3. Expand by value and dependency, in slices small enough to verify.
4. Verify after each milestone; fix ordinary failures and keep going.
5. Challenge, integrate, rerun decisive checks.
6. Close at Definition of Done, or write the next Baton at a genuine hard stop.

Keep-going rule: proceed through ordinary ambiguity with reversible, recorded assumptions — a routine test failure, a finished subtask, or the end of a checklist is not a stopping point. For greenfield or substantial cross-cutting work make the first milestone a walking skeleton, the thinnest end-to-end path that runs; for a fix, release, or mature code path, skip it.

### Step 6 — Challenge

1. **Claim audit** — attach evidence to every load-bearing status, path, command, branch, and acceptance claim.
2. **Falsification** — hunt the strongest contradiction: stale state, wrong worktree, hidden dirty changes, missing files, unverified external status, a plan the architecture cannot hold.
3. **Fresh challenge** — for nontrivial work give a fresh read-only challenger the handoff and the raw artifacts, never your verdict, and delegate it to a cheaper subagent. With no independent context available, do a separated zero-assumption reread and disclose that fallback in Section 0.
4. **Correction and replay** — fix supported findings, rerun decisive checks, reread the file. Record unresolved disagreement as uncertainty.

Low risk gets the path and command checks plus falsification. Medium risk adds one independent truth or plan review. High risk adds separate truth and domain reviewers, plus verified target, impact, and recovery immediately before any consequential action. Reviewer output is evidence, not a verdict.

### Step 7 — Write the document

One template, three depth labels, soft ceilings: `COMPACT` 80 lines for narrow low-uncertainty work; `STANDARD` 200 lines, adding the delegation map, decision detail, and later horizons; `GOVERNED` 320 lines, adding separate truth and domain reviewers and recovery or rollback evidence.
Depth is independent of shape: a `DIRECT` money-path repair can need `GOVERNED`. Do not repeat a fact across sections, and never precompute a hypothetical hash, output, or commit as future proof — give the command and the acceptance condition instead.

### Step 8 — Check, then emit

Run these against the written file and fix every FAIL first. A path the receiver is told to create, or one recorded as deleted, is a false FAIL: state it in prose outside the scanned sections rather than deleting the record. If this repository has `evals/check.sh`, run `bash evals/check.sh --root <repo-root> <file>` as well; it adds model-identifier provenance and secrets checks the block below omits. With no shell, perform each check by reading and say so in the Review tier line of Section 0.

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
f=docs/handoffs/handoff-<YYYY-MM-DD-HHmm>.md
test -s "$f" || echo "FAIL missing file"
grep -qi 'Status: DRAFT' "$f" && echo "FAIL draft line still present"
for k in 'Document depth:' 'Human decision state:' 'Continuation Mission'; do grep -q "$k" "$f" || echo "FAIL missing $k"; done
d=$(grep -m1 -oE 'Document depth:\**[[:space:]]*(COMPACT|STANDARD|GOVERNED)' "$f" | grep -oE 'COMPACT|STANDARD|GOVERNED'); n=$(wc -l < "$f" | tr -d " ")
case "$d" in COMPACT) c=80 ;; STANDARD) c=200 ;; GOVERNED) c=320 ;; *) c=0 ;; esac
[ "$c" -gt 0 ] && [ "$n" -gt "$c" ] && echo "WARN $d is $n lines > $c: relabel or move detail to a referenced file"
awk '/^#+ /{s=$0} s ~ /(Live Truth|Working state|Read first|Continuation Mission)/' "$f" \
  | grep -oE '`[^` ]+`' | tr -d '`' | grep -E '/|\.[a-z]+$' \
  | grep -vE '^(<|@|https?:|[a-z0-9.-]+\.(com|org|io|dev|net)/|docs/handoffs/|origin/|upstream/|refs/|[0-9]+/[0-9]+$|/[^/]*$|(feature|fix|chore|hotfix|release|bugfix)/)|\*' \
  | sed -E 's/:[0-9]+(-[0-9]*)?$//' | sort -u | while read -r p; do
    q="${p/#\~/$HOME}"; test -e "$q" && continue
    case "$p" in */*) echo "FAIL path not found: $p" ;; *) echo "WARN bare filename not found: $p" ;; esac
  done
tail -n 1 "$f" | grep -qE "^\**Read .*$(basename "$f").* and do .+\.\**$" || echo "FAIL last line is not the closing sentence naming this file"
grep -noE '(\*\*|\| *|— *)(Believed|Stale|Assumed|Inferred|Confirmed|Reported|Likely|Estimated)([^A-Za-z]|$)' "$f" && echo "FAIL class word outside Observed/Derived/Volatile/Unknown"
grep -nE '\|[[:space:]]*(Observed|Derived|Volatile|Unknown)[[:space:]]*[/,]' "$f" && echo "FAIL compound class; use exactly one of the four"
```

Then reread the file as the receiver would: if you could not run the first move from the document alone, passing checks do not make it done. Emit its last line as the only output.

## Template

````markdown
# Handoff: <short outcome-oriented title>

**Date:** <YYYY-MM-DD HH:mm> · **Repo/branch:** `<absolute path>` / `<branch>`

## 0. Launch Contract
> **Main directive:** Own this as the primary execution session. Re-ground volatile facts without repeating settled work, then work the Continuation Mission until Definition of Done or a stated hard stop. Do not stop because one milestone or delegated lane finishes.

- **Document depth:** <COMPACT | STANDARD | GOVERNED>
- **Status:** <omit when final; while a question is open: DRAFT — awaiting human answer>
- **Execution:** <DIRECT | LEAN> via <native mechanism>; <one-sentence right-sizing reason>
- **Capability activation:** <one line per queued capability: name — first use — fallback; or none>
- **Recommended install/connect:** <missing better option — exact install path for this harness — what it unblocks — human answer, or "deferred, using <fallback>"; or none identified, or catalog unreachable>
- **Model routing:** <one line per lane: tier — family or cited route — escalation trigger — frontier exception>
- **Human decision state:** <none needed | per choice: answered—decision, horizon, source; deferred—default and revisit trigger>
- **One-shot horizon:** <largest coherent safe outcome>
- **Review tier and challenge:** <low/medium/high; who challenges what, or the disclosed fallback; note here when checks were performed by reading>
- **Boot refresh:** <only the volatile facts that matter>
- **Hard stops and authority:** <real gates; delegation expands nothing>
- **Owning repository:** <absolute path; multi-repo or worktree sessions only>

## 1. Outcome and Done
<Objective and why, in one to three sentences.>
- [ ] <observable acceptance criterion>
- [ ] <decisive criterion, including external proof when local green is insufficient>

## 2. Live Truth
- **Status:** <done, in progress, remaining>
- **Momentum checkpoint:** <exact stop point, next move, active or background lanes, what not to redo>
- **Working state:** <HEAD/upstream/dirty/locks/external state, only where relevant>

| Claim | Class | Evidence | Refresh |
|---|---|---|---|
| Payments suite is red on 3 cases | Observed | `bun test payments` at 14:02 | rerun at boot |

- **Read first:** <real paths, each with why it matters>

## 3. Decisions and Structure
- <settled decision and rationale; mark an answered human choice Observed, a deferred one with its revisit trigger>
- **Structure:** <first structural milestone or walking skeleton, or "not applicable — existing path suffices">

## 4. Verification
```bash
<smallest decisive check set>
```
<What green proves, and what it does not.>

## 5. Risks and Hard Stops
- <risk or blocker, owner, evidence needed, whether it blocks now> — or "None known."

## 6. Continuation Mission
- **Start by:** <one concrete move naming the artifact>
- **Continue through:** <short outcome ladder>
- **Keep going until:** <Definition of Done or a named hard stop>

---
Read docs/handoffs/handoff-<YYYY-MM-DD-HHmm>.md and do the continuation mission through its stop conditions, starting by <first concrete move as a gerund phrase>.
````

`STANDARD` adds a delegation map (lane, owner, single-writer boundary, evidence return), per-decision detail with rejected alternatives, and a later-horizons section. `GOVERNED` adds separate truth and domain reviewers with their findings, and recovery or rollback evidence.

## Attribution

Baton derives from the **handoff** skill in [metaswarm](https://github.com/dsifry/metaswarm) by Dave Sifry (MIT License), keeping its self-contained document and exact closing-sentence contract while generalizing across runtimes.
Baton adds the human leverage gate, the four evidence classes, least-sufficient tier routing, and the mechanical check. See `NOTICE` for full attribution.
