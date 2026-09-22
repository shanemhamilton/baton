---
name: baton
license: MIT
description: Use when ending or compacting a session, switching machines or sessions, running low on context, saving where work stands for later, or handing work off to a fresh session — updates one verified canonical continuation record plus one exact closing sentence. An explicit Baton checkpoint saves essential continuity without ending the session. Not a colleague-facing document, README, or project memory. When another handoff skill is installed, including metaswarm's handoff, use this one.
---

# Baton

Write for a fresh agent with zero prior chat context. The handoff is an evidence-backed launchpad, not a transcript of what happened.
The receiving session never loads this skill, so anything it must do belongs in the document's Section 0.
Never assume a capability authenticated in one harness exists in another.

## Checkpoint (explicit only)

When the user explicitly requests a **Baton checkpoint**, follow this section instead of the final handoff workflow. Invoke it at a material decision or milestone while context still contains the rationale; this skill has no automatic checkpoint hook.

Update the current task's existing authorized durable record selected by repository policy. If no native record exists and policy permits it, use one named local fallback, `docs/handoffs/checkpoint-<task>.md`; never create a parallel handoff where the repository says not to. Preserve the objective, latest user corrections, exclusions, approval scope and source, decisive failed approaches and why they failed, unfinished work, and next safe move. Distinguish approved, proposed, and awaiting approval; classify load-bearing claims as `Observed`, `Derived`, `Volatile`, or `Unknown` with their source. Record only continuity that would otherwise be lost; omit secrets and do not expand authority.

Read back the saved record, report its locator, and continue the current task. Do not run the Human Leverage Gate or emit the terminal closing sentence. For a later final continuation record, consolidate surviving checkpoint facts, refresh volatile state, and mark unrecoverable gaps `Unknown`; the receiver must not need the checkpoint to recover essential intent or authority.

## Contract

For final handoffs, produce two deliverables, always — including non-interactive, scheduled, and subagent runs. The remaining workflow applies to final handoffs.

1. **One canonical continuation record.** Before writing, read applicable repository instructions and identify the project's durable task system. Update that system's existing task, plan, playbook, or issue when it is declared canonical. A local `docs/handoffs/handoff-<YYYY-MM-DD-HHmm>.md` is a fallback only when no canonical system exists and repository policy permits a handoff file. Do not create a parallel handoff record. The selected record must name itself as `Continuation record`, its selection rule as `Continuation policy`, its task identity and lineage, and a `Receiver start` instruction.
2. **The closing sentence**, copied verbatim from `Receiver start`, as the last output of the session with nothing after it. For a local record, `Receiver start` is its last nonblank line. For a native tracker, it is a durable dedicated continuation field or comment that the receiver can read back through the repository's normal interface.

✅ `Read docs/plans/payments-fix.md and do the continuation mission through its stop conditions, starting by running the failing payments test.` — and the session ends there.

❌ Creating `docs/handoffs/` beside a repository-managed task record "for safety" — it makes two continuation authorities and recreates stale-state failures.

No credentials, tokens, cookies, or auth state in the record. Keep a fallback `docs/handoffs/` record untracked unless the project deliberately tracks it. A fresh clone or another worktree does not contain the source checkout's untracked files or uncommitted changes; even a tracked record requires a revision containing it. In a multi-repo or worktree session, use the absolute record locator in `Receiver start` and name the owning repository in Section 0.

## Rules

1. **Verify before recording.** Classify every load-bearing claim as exactly `Observed`, `Derived`, `Volatile`, or `Unknown` — no synonyms. Cite each path as it resolves from the repository root or as an absolute path, never as a bare filename.
2. **Leave no important work behind, and give it a durable location** — disk, tracker, or a commit or PR body. Chat is not a record. A gated draft goes to an untracked local file, named.
3. **Preserve momentum exactly.** Record the stop point, the next move, active or background lanes, and the do-not-redo boundary, so the receiver resumes instead of reinvestigating.
4. **Right-size consequential routing.** When delegation or a model choice materially affects continuation, route legwork to FAST, bounded coding and analysis to BALANCED, judgment to FRONTIER; explain why lower tiers are insufficient for a frontier lane. Leave routine choices to the receiver's actual runtime. Name model families, not IDs, unless you cite a real catalog (Codex: `~/.codex/models_cache.json`; Claude Code exposes none).
5. **One human round, then finish.** At most one round of one to three questions. In a non-interactive, scheduled, or subagent run, or when no answer arrives, record each unresolved choice as deferred by absence with its option-preserving default and revisit trigger.
6. **Delegate where useful.** Use a cheaper subagent for an independent state sweep when it saves work, and for the fresh challenger when required below.
7. **Record Git identity, not a prose branch claim.** For Git work, complete every field in the `Checkout identity` schema and reconcile a mismatch read-only before writing. A different worktree, common directory, HEAD, branch, truth ref, or dirty-state digest is a contradiction, not a harmless refresh.
8. **Protect worktree state.** A worktree cleanup operation is never branch deletion. Unknown ownership, integration evidence, unique-commit result, recovery route, or authority means `PRESERVE`. Do not move a linked worktree through the filesystem, prune, force-remove, clean, or delete a branch merely because its upstream disappeared.
9. **Never expand authority.** Record granted approval separately from proposed or pending actions, with its source, scope, and conditions. `Cleanup authority` defaults to `No destructive cleanup authorized`. Retain valid grants without asking again; changed conditions or newer user instructions invalidate only affected authority. Destructive, production, privacy, security, cost, and external actions retain their existing gates.

## Method

### Step 1 — Reconstruct the mission

State the objective using the user's latest corrections and exclusions; why settled decisions matter; the Definition of Done as observable criteria, including proof local tests cannot give; the execution horizon (the largest safe body of work needing no new decision or approval); and the hard stops.
Preserve uncertainty rather than filling gaps with plausible detail.

### Step 2 — Establish live state

```bash
git rev-parse --show-toplevel
git rev-parse --path-format=absolute --git-common-dir
git remote get-url origin || true
git rev-parse --verify HEAD || printf 'UNBORN\n'
git symbolic-ref --quiet --short HEAD || printf 'DETACHED\n'
git status --short --branch
git status --porcelain=v2 --untracked-files=all | shasum -a 256
git worktree list --porcelain
git log --oneline -10 && git stash list
```

For Git work, record this **Checkout identity** in Section 0. `Repository identity` is `git remote get-url origin` when present; otherwise use the canonical `Git common directory`. `Truth ref` is `<ref> @ <40-char resolved SHA>`, never a guessed branch; `Unknown — <reason>` holds work to read-only reconciliation until it is recovered. `Dirty-state digest` is the SHA-256 above, made from the complete porcelain output including untracked paths.

| Field | Required value |
|---|---|
| Repository identity | non-secret origin URL, or canonical Git common directory when no origin exists |
| Repository root | `git rev-parse --show-toplevel` |
| Execution worktree | absolute checkout path used for the work |
| Git common directory | absolute `git rev-parse --git-common-dir` result |
| Author HEAD | exact SHA, or `UNBORN` |
| Author branch | branch name, or `DETACHED` |
| Truth ref | `<ref> @ <40-char resolved SHA>`, or `Unknown — <reason>` when writing remains blocked by read-only reconciliation |
| Upstream state | `none`, or the current first line of `git status --short --branch` |
| Dirty-state digest | SHA-256 of complete porcelain v2 status with untracked files |
| Checkout observed at | timestamp of this capture |
| Checkout refresh command | runnable command that refreshes the complete tuple |
| Checkout mismatch disposition | `read-only reconciliation` before writing; state the safe next action if the tuple differs |

The receiver compares its live tuple with the recorded one before modifying anything. A root, execution-worktree, common-directory, HEAD, branch, truth-ref, upstream-state, or dirty-digest mismatch requires read-only reconciliation: list the registry and status, identify the intended lane and owner, refresh supporting claims, then update only the affected continuation steps. A mismatch never authorizes cleanup or a new worktree.

Also check worktrees, locks, active actors, and deploy or runtime state when they bear on the task. Record failed refreshes as missing evidence; do not suppress them.
For claims supporting the next move or a do-not-redo boundary, use the existing Refresh column to state when the evidence still applies and what change requires revisiting it. Carry the latest user corrections into the objective, exclusions, and authority; do not let an older plan override them.

**Linked-worktree lifecycle (conditional):** Set `Worktree lifecycle action` to `NONE`, `MOVE`, `REMOVE`, `REPAIR`, or `BRANCH-DELETE` (comma-separate independently targeted actions). `NONE` omits the ledgers. Every other action requires both ledgers below and a pre-action inventory. Each Worktree ledger row identifies its own `Action`, which must appear in this list. `MOVE` uses `git worktree move`; never use a filesystem move. Prefer a repository-native retirement command when one exists; when none exists, non-forced `git worktree remove <path>` is permitted only with the explicit authority, recovery, and verification in that row. `prunable` registry state, a missing source directory, or a Git-root mismatch is a hard stop: inventory the physical path and changes, repair or restore, and re-verify the registry before considering any retirement. Never jump from `prunable` to prune or remove.

`REMOVE` and `BRANCH-DELETE` are independent actions. A gone upstream or an absent worktree is not integration evidence. Before removal, a detached worktree needs a recovery ref. Before deleting a branch, record its tip SHA, upstream state, attached worktree, owner, integration evidence (including a possible squash merge), unique-commit result, and recovery ref. `Unknown` in an ownership, evidence, recovery, or authority field requires `PRESERVE`; do not infer deletion from worktree removal.

`Cleanup authority` is exactly `No destructive cleanup authorized` unless existing explicit authority covers the target. An exception names the repository-native command and uses `authorized; source: <authority>; scope: <exact targets>; conditions: <preconditions and recovery>`. Generic `git clean`, `git worktree prune`, direct filesystem removal, and forced removal are never a substitute for that authority.

**Worktree ledger**

| Target path | Action | Source path | Destination path | Repository | HEAD | Branch | Registry state | Dirty state | Untracked paths | Stash dependency | Unique commits | Integration evidence | Active process or lease | Owner/task | Recovery ref | Pre-action inventory | Post-action verification | Disposition | Retirement command | Action owner |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| <one target per row; record `Unknown` explicitly> | <MOVE | REMOVE | REPAIR | BRANCH-DELETE> | <physical source> | <destination for MOVE; source when not moving> | <repository identity> | <SHA> | <branch or DETACHED> | <registry result> | <complete tracked state> | <full untracked list> | <stash or none> | <check result> | <merge/PR proof or Unknown> | <lease/process state> | <owner and task> | <ref or Unknown> | <path/status/registry evidence> | <new registry and path evidence> | <RETAIN | REMOVE-CANDIDATE | TRANSFERRED | UNKNOWN> | <native command or non-forced `git worktree remove <path>`> | <responsible actor> |

`REMOVE-CANDIDATE` is not permission to remove. A receiver reuses the recorded execution worktree by default. Creating another requires an isolation reason, owner, base SHA, branch, and retirement trigger in a new ledger row. At Definition of Done, record one disposition for every lane: `RETAIN`, `REMOVE-CANDIDATE`, `TRANSFERRED`, or `UNKNOWN`.

**Branch ledger**

| Branch | Tip SHA | Upstream state | Attached worktree | Owner/task | Integration evidence | Unique commits | Recovery ref | Disposition | Action owner |
|---|---|---|---|---|---|---|---|---|---|
| <branch> | <SHA> | <state> | <path or none> | <owner/task or Unknown> | <proof or Unknown> | <check result> | <ref or Unknown> | <PRESERVE unless deletion is proven> | <responsible actor> |

Use this table for each `BRANCH-DELETE` target. It is a preservation ledger, not a deletion queue.

**Moving machines or checkouts:** Record `Transfer source root`, `Transfer destination root`, `Handoff source`, `Handoff destination`, `Transfer availability`, and `Receiver readback SHA-256` in Section 0. Here, “handoff” means the selected canonical continuation record, even when it is a plan or tracker rather than `docs/handoffs/`. Inventory only essential local artifacts, including required uncommitted changes, untracked files, and supporting evidence: source and destination locators, recovery or transfer route within existing authority, and availability evidence. Before declaring cross-checkout continuity ready, verify the receiver's revision and read back the finalized continuation record and essential artifacts there; require byte-identical source and destination copies plus a matching SHA-256 of the record with only its own `Receiver readback SHA-256` value replaced by literal `<attested-content-hash>`. That one-field normalization avoids a self-referential hash while invalidating the receipt when any other content changes. Existence on the author's machine proves no destination access. Otherwise set `Transfer availability` to `Unknown`, name the exact pending prerequisite and affected continuation, and continue independent safe preparation. Do not publish private artifacts or transfer credentials/auth state to make a move work; preserve existing permission boundaries.

**Not a git repository** (`git rev-parse` fails): record file-level state — which files changed, where they are, what is unsaved — plus the external state the work depends on.

**Low context** (the user said "compact" or "running low", the harness warned, or a prior compaction already dropped detail): recover surviving task notes or checkpoints and refresh live state. Update a compact continuation record retaining the objective, authority and exclusions, unfinished work, and next safe move; cite durable sources without treating their volatile facts as current. Class missing intent, rationale, approvals, and open questions individually as `Unknown`, never guessed. If missing authority blocks execution, make the next move a safe recovery or preparation step. Run Step 8 and finish; a thin record beats none.

### Step 3 — Human Leverage Gate

A choice qualifies only when all four hold: it is not resolvable from source, instructions, tracker, or a safe probe; plausible answers materially change outcome, risk, or horizon; it belongs to the human rather than to reversible engineering judgment; and settling it now avoids rework.

Qualifies: "charge the platform fee on gross or net fare?" — a money-path policy the code cannot infer, and the schema differs per answer. Does not qualify: "which mock library for the new test?" — reversible, and the repo already has a convention.

Write the canonical continuation record first with `Status: DRAFT — awaiting human answer` in Section 0, then ask once. Rule 5's terminator ends the gate: record unanswered choices as deferred by absence, remove the DRAFT line, finalize. If nothing qualifies, write `Human decision state: none needed`.

```text
Human decision needed before I finalize the continuation record

1. <decision>
   Why now: <how it changes the next session's useful work>
   Options: <viable choices and their practical effects>
   Recommendation: <default and why>
   If deferred: <option-preserving default, plus revisit trigger>

Reply with a choice, feedback, or "defer." I finalize the continuation record after your response.
```

### Step 4 — Capabilities and shape

Inspect and record only capabilities that change the continuation: a required operation, access constraint, known failure, or material cost or quality tradeoff. Verify them against the live runtime, not remembered inventories or project settings alone. When the receiver is a different machine or harness, class unverified receiving capabilities `Unknown` and queue their verification at boot before their first use; do not copy a general inventory of this harness.

Rank access paths: authoritative connector, then maintained connector, then vendor CLI or API, then UI automation, then manual transfer; tie-break within a tier on what is already authenticated and needs the least setup and permission, and drop a higher tier when it lacks the operation, has weak provenance, or is less reliable here.

If a missing option materially improves the mission, recommend it and use the existing Human Leverage Gate — never install or authorize it yourself; continue with the fallback if the human defers. Record unavailable catalog or network access only when it affects the chosen route.
Name skills by bare name. Record a receiving-harness invocation only after verifying it there. Queue `efficient-frontier` for capable-model orchestration and `ponytail` for the smallest correct implementation when the receiving harness lists them and the mission benefits; queue any more specific skill the same way.

Two shapes: `DIRECT` (one context) or `LEAN` (a capable main model plus one to three bounded workers for useful independent lanes). Preserve routing constraints that matter; otherwise let the receiver choose from its runtime without inventing delegation to fill the template. Escalate to a heavier framework only by naming the concrete coordination failure — multiple writers, durable cross-session state, formal governance gates — that neither shape manages.

**Nontrivial** means the work touches more than one file, more than one independent lane, or has a stop condition outside local tests; a same-repo single-file fix with a known test is trivial. Trivial work skips the Step 6 fresh challenger unless the risk tier is medium or high. Omit capability and routing fields that do not change the receiver's work.

### Step 5 — Design the longest safe one-shot run

Give the receiver an outcome ladder, not a script:

1. Boot: activate queued capabilities, verify the intended repository/worktree and relevant unfinished changes, then check the next move's preconditions against live state and current instructions. Revise only affected steps when facts changed; retain settled work whose evidence still applies.
2. Confirm structure: understand the existing architecture before changing it.
3. Expand by value and dependency, in slices small enough to verify.
4. Verify after each milestone; fix ordinary failures and keep going.
5. Challenge, integrate, rerun decisive checks.
6. At Definition of Done, update the canonical continuation record's `Continuation lifecycle` to `CLOSED`, record the final worktree and branch dispositions in the durable task or PR, and retire the active continuation instruction. At a genuine hard stop, update the same record's lineage instead of creating a competing continuation chain.

Name the first move's expected observation and a useful safe fallback if it differs. A contradiction or missing prerequisite blocks only dependent unsafe work; continue independent permitted preparation.
Keep-going rule: proceed through ordinary ambiguity with reversible, recorded assumptions — a routine test failure, a finished subtask, or the end of a checklist is not a stopping point. For greenfield or substantial cross-cutting work make the first milestone a walking skeleton, the thinnest end-to-end path that runs; for a fix, release, or mature code path, skip it.

### Step 6 — Challenge

1. **Claim audit** — attach evidence to every load-bearing status, path, command, branch, and acceptance claim.
2. **Falsification** — hunt the strongest contradiction: stale state, wrong worktree, hidden dirty changes, missing files, unverified external status, a plan the architecture cannot hold.
3. **Fresh challenge** — for nontrivial work give a fresh read-only challenger only the continuation record and permitted raw artifacts, without the prior conversation or your verdict. Have it reconstruct the first safe action, expected result, conditions that invalidate that action, and information it still needs; judge whether those follow from the evidence, not whether the headings look complete. Use a cheaper subagent when available. With no independent context, perform the same reconstruction in a separated zero-assumption reread and disclose that fallback in Section 0.
4. **Correction and replay** — fix supported findings, rerun decisive checks, reread the record. Record unresolved disagreement as uncertainty.

Low risk gets the path and command checks plus falsification. Medium risk adds one independent truth or plan review. High risk adds separate truth and domain reviewers, plus verified target, impact, and recovery immediately before any consequential action. Reviewer output is evidence, not a verdict.

### Step 7 — Write the document

One record shape, three depth labels, soft ceilings: `COMPACT` 80 lines for narrow low-uncertainty work; `STANDARD` 200 lines, adding needed delegation, decision detail, and later horizons; `GOVERNED` 320 lines, adding separate truth and domain reviewers and recovery or rollback evidence. Adapt the headings to a repository-native tracker or record only when its native fields make the mapping unambiguous; otherwise use a permitted local record.
Depth is independent of shape: a `DIRECT` money-path repair can need `GOVERNED`. Do not repeat a fact across sections, and never precompute a hypothetical hash, output, or commit as future proof — give the command and the acceptance condition instead.
When space competes, preserve in this order: user intent and current boundaries; unfinished work and working state; the next safe action and its preconditions; settled decisions and failed approaches the receiver might repeat; supporting references. Keep irreplaceable rationale in the record; link recoverable detail with its location and purpose. For a retained failed approach, include the failure evidence and what would justify revisiting it. Routine capability inventories and model advice never displace these facts.

### Step 8 — Check, then emit

Run these against a selected local continuation record and fix every FAIL first. A local record must be a non-symlink file inside `Repository root`, and `Continuation record` must resolve back to that file. Use backticks for file citations that must exist now. Describe planned, deleted, or pending destination paths in plain prose with their explicit status, keeping the information in its required section. If this repository has `evals/check.sh`, run `bash evals/check.sh --root <repo-root> <record>` as well; it adds model-identifier provenance and secrets checks the block below omits. For a repository-declared remote tracker, read back the durable native record and every required field through its normal interface; state that a file-path evaluator did not run. With no shell, perform each check by reading and say so in the Review tier line of Section 0.

```bash
(
r='<absolute repository root or non-Git working directory>'
f='<absolute local continuation record>'
cd "$r" || exit 1
failed=0
fail() { echo "FAIL $*"; failed=1; }
test -s "$f" && test -f "$f" && test ! -L "$f" || { fail 'missing regular non-symlink record'; exit 1; }
rr=$(cd -P "$r" 2>/dev/null && pwd)
rf=$(cd -P "$(dirname "$f")" 2>/dev/null && pwd)/$(basename "$f")
case "$rf" in "$rr"/*) ;; *) fail 'record is outside repository root' ;; esac
field() { sed 's/[*`]//g' "$f" | sed -n "s/^[[:space:]>-]*$1:[[:space:]]*//p" | head -1; }
filled() { printf '%s\n' "$1" | sed -E 's/^[[:space:]>-]*//;s/^\[[ xX]\][[:space:]]*//;s/[[:space:]]*$//' | grep -qvE '^$|^<[^>]*>$|^(TODO|TBD|N/A|\.\.\.)$'; }
body() { awk -v want="$1" -v all="${2:-}" '/^#+ /{level=match($0,/[^#]/)-1;if(on&&level<=depth)on=0;if($0~want){on=1;depth=level};next} on&&(all||$0!~/^[ \t]*(---|```|[|])/){print}' "$f"; }
sed 's/\*//g' "$f" | grep -qiE 'status:[[:space:]]*draft' && fail 'draft line still present'
d=$(field 'Document depth'); n=$(awk 'END{print NR}' "$f")
case "$d" in COMPACT) c=80 ;; STANDARD) c=200 ;; GOVERNED) c=320 ;; *) c=0; fail 'invalid Document depth' ;; esac
[ "$c" -gt 0 ] && [ "$n" -gt "$c" ] && echo "WARN $d is $n lines > $c"
for k in 'Continuation record' 'Continuation policy' 'Task identity' 'Continuation lifecycle' 'Continuation lineage' 'Revalidation triggers' 'Human decision state' 'Cleanup authority' 'Worktree lifecycle action' 'Start by' 'Receiver start'; do filled "$(field "$k")" || fail "empty or missing $k"; done
rec=$(field 'Continuation record')
case "$rec" in '~'*) rec="$HOME${rec#\~}" ;; esac
[ -n "$rec" ] && [ "$rec" -ef "$f" ] || fail 'Continuation record must resolve to this exact file'
filled "$(field 'Objective')" || filled "$(body 'Outcome and Done')" || fail 'empty or missing objective'
filled "$(body 'Continuation Mission' | sed 's/[*`]//g' | sed -n 's/^[[:space:]-]*Keep going until:[[:space:]]*//p')" || fail 'empty or missing continuation stop'
awk -F'|' '
  function clean(s){gsub(/[ *`\t]/,"",s);return s}
  function content(s){return s!=""&&s!~/^<.*>$/&&s!~/^(TODO|TBD)$/}
  /^\|/ {
    if ($0~/^[| :\t-]+$/) next
    header=0
    for(i=2;i<NF;i++) if(clean($i)=="Class") header=1
    if(header){cl=0;claim=0;ev=0;for(i=2;i<NF;i++){s=clean($i);if(s=="Class")cl=i;if(s=="Claim")claim=i;if(s=="Evidence")ev=i};next}
    if(cl){v=clean($cl);if(v!~/^(Observed|Derived|Volatile|Unknown)$/)bad=1;else if(claim&&ev){if(content(clean($claim))&&content(clean($ev)))truth=1;else bad=1}}
    next
  }
  {cl=0}
  END{exit(bad||!truth)}
' "$f" || fail 'invalid class or no populated Claim/Class/Evidence row'
grep -qE '(\*\*|\| *|— *)(Believed|Stale|Assumed|Inferred|Confirmed|Reported|Likely|Estimated)([^A-Za-z]|$)' "$f" && fail 'class outside the four allowed values'
paths=$(body 'Launch Contract|Live Truth|Working state|Read first|Continuation Mission' all \
  | grep -oE '`[^` ]+`' | tr -d '`' | grep -E '/|\.[a-z]+$' \
  | grep -vE '^(<|@|https?:|[a-z0-9.-]+\.(com|org|io|dev|net)/|origin/|upstream/|refs/|[0-9]+/[0-9]+$|/(v[0-9]+|api)/|(feature|fix|chore|hotfix|release|bugfix|codex)/)|\*' \
  | sed -E 's/:[0-9][0-9,.-]*$//' | sort -u | while IFS= read -r p; do
    q="$p"; [[ "$p" = '~'* ]] && q="$HOME${p#\~}"
    test -e "$q" && continue
    if [[ "$p" = */* ]]; then echo 'FAIL cited path not found'; else echo 'WARN bare filename not found'; fi
  done)
[ -n "$paths" ] && printf '%s\n' "$paths"
printf '%s\n' "$paths" | grep -q '^FAIL' && failed=1
last=$(awk 'NF{last=$0}END{print last}' "$f" | sed 's/[*`]//g;s/^[[:space:]]*//;s/[[:space:]]*$//')
start=$(field 'Receiver start')
[ "$start" = "$last" ] || fail 'Receiver start must be the final line'
p=$(printf '%s\n' "$last" | sed -nE 's/^Read (.+) and do .+\.$/\1/p')
case "$p" in '~'*) p="$HOME${p#\~}" ;; esac
[ -n "$p" ] && [ "$p" -ef "$f" ] || fail 'closing sentence must resolve to this exact file'
exit "$failed"
)
```

Keep the canonical closing form `Read <verified continuation record> and do ...`. For a cross-checkout transfer, after the last record edit, verify that the receiving copy is byte-identical and accessible; record the receiver's canonical-content SHA-256 readback before emitting a destination path. Canonical content replaces only the `Receiver readback SHA-256` value with literal `<attested-content-hash>`, so the receipt cannot self-invalidate. Any other later correction invalidates transfer verification. While destination access is unavailable or `Unknown`, name the verified source record and make the first move establish or complete transfer within existing authority. Record prerequisites in Section 0, never inside the closing sentence's record locator; this source-session instruction does not establish destination readiness. Source-record validation and receiver-readback validation are separate checks.

Then reread the continuation record as the receiver would: if you could not run the first move or identify its explicit unmet prerequisite from the record alone, passing checks do not make it done. Emit `Receiver start` as the only output.

## Template

````markdown
# Continuation: <short outcome-oriented title>

**Date:** <YYYY-MM-DD HH:mm>

## 0. Launch Contract
> **Main directive:** Own this as the primary execution session. Re-ground volatile facts without repeating settled work, then work the Continuation Mission until Definition of Done or a stated hard stop. Do not stop because one milestone or delegated lane finishes.

- **Continuation record:** `<canonical record locator; a local record points to itself>`
- **Continuation policy:** <repository instruction or declared native system that selected this record; local fallback permission when used>
- **Task identity:** <durable task, issue, PR, or repository-native key>
- **Continuation lifecycle:** <ACTIVE | SUPERSEDED | CLOSED>
- **Continuation lineage:** <predecessor/supersedes/superseded-by state, or `none`>
- **Revalidation triggers:** <what invalidates the live state or requires a new receiver readback>
- **Document depth:** <COMPACT | STANDARD | GOVERNED>
- **Status:** <omit when final; while a question is open: DRAFT — awaiting human answer>
- **Human decision state:** <none needed | per choice: answered—decision, horizon, source; deferred—default and revisit trigger>
- **One-shot horizon:** <largest coherent safe outcome>
- **Hard stops and authority:** <real gates; granted approval with source, scope, and conditions; separately name proposed or pending actions. Reuse still-valid approval without asking again; delegation expands nothing>
- **Cleanup authority:** No destructive cleanup authorized
  - <Exception only: `authorized; source: <authority>; scope: <exact targets>; conditions: <preconditions and recovery>` plus the repository-native command>
- **Worktree lifecycle action:** <NONE | MOVE | REMOVE | REPAIR | BRANCH-DELETE; comma-separate independent targets>
- **Start by:** <one concrete safe move naming the artifact, its preconditions, expected observation, and useful safe fallback if it differs>
- **Boot refresh:** <only the volatile facts that matter>
- **Reconcile at boot:** Verify the intended repository/worktree, relevant unfinished changes, and next-action preconditions against live state and current instructions. Any tuple mismatch requires **read-only reconciliation** before writing. Newer user corrections supersede this record. Revise only affected steps; retain do-not-redo boundaries while their supporting evidence still applies. Block only dependent unsafe actions and continue independent permitted work.
- **Receiver start:** `Read <continuation record> and do the continuation mission through its stop conditions, starting by <first concrete move as a gerund phrase>.`
- **Review tier and challenge:** <low/medium/high; first-action reconstruction findings or disclosed fallback; note here when checks were performed by reading>
- **Execution:** <omit unless coordination matters: DIRECT | LEAN via native mechanism; right-sizing reason>
- **Capability activation:** <omit unless needed: name — first use — verified route or fallback>
- **Recommended install/connect:** <omit unless material: missing option — verified install path — what it unblocks — human answer or deferred fallback>
- **Model routing:** <omit routine choices; for consequential lanes: tier — family or cited route — escalation trigger — frontier exception>

### Checkout identity (Git work only)

- **Repository identity:** <origin URL, or canonical Git common directory>
- **Repository root:** `<git top-level>`
- **Execution worktree:** `<absolute worktree path>`
- **Git common directory:** `<absolute common directory>`
- **Author HEAD:** <exact SHA or UNBORN>
- **Author branch:** <branch or DETACHED>
- **Truth ref:** <`ref @ 40-char resolved SHA`, or `Unknown — reason` only with read-only reconciliation>
- **Upstream state:** <none or current `git status --short --branch` first line>
- **Dirty-state digest:** <SHA-256 of porcelain v2 including untracked files>
- **Checkout observed at:** <timestamp>
- **Checkout refresh command:** <runnable complete-tuple refresh command>
- **Checkout mismatch disposition:** <read-only reconciliation steps and safe fallback>

### Transfer (cross-checkout or machine only)

- **Transfer source root:** `<absolute source root>`
- **Transfer destination root:** `<absolute destination root>`
- **Handoff source:** `<source copy of the selected continuation record>`
- **Handoff destination:** `<destination copy of the selected continuation record>`
- **Transfer availability:** <verified | Unknown; pending prerequisite and affected continuation when Unknown>
- **Receiver readback SHA-256:** <matching SHA-256 after replacing this field's own value with literal `<attested-content-hash>` in both byte-identical records, or Unknown with reason>

### Worktree ledger

<Omit when `Worktree lifecycle action: NONE`; otherwise copy the exact Step 2 Worktree ledger table and complete one row per target. `Unknown` requires `RETAIN`.>

### Branch ledger

<Omit when `Worktree lifecycle action: NONE`; otherwise copy the exact Step 2 Branch ledger table and complete one row per branch target.>

## 1. Outcome and Done
<Objective and why, incorporating the latest user corrections and explicit exclusions, in one to three sentences.>
- [ ] <observable acceptance criterion>
- [ ] <decisive criterion, including external proof when local green is insufficient>

## 2. Live Truth
- **Status:** <remaining, in progress, done>
- **Momentum checkpoint:** <exact stop point, active or background lanes, what not to redo and supporting claim rows; next action is in Section 0>
- **Working state:** <HEAD/upstream/dirty/locks/external state, only where relevant>

| Claim | Class | Evidence | Refresh |
|---|---|---|---|
| Payments suite is red on 3 cases | Observed | `bun test payments` at 14:02 | rerun at boot; reopen the fix plan if these failures changed |

- **Read first:** <real paths, each with why it matters>

## 3. Decisions and Structure
- <settled decision and rationale, or failed approach the receiver might retry with failure evidence and revisit condition; mark an answered human choice Observed, a deferred one with its revisit trigger>
- **Structure:** <first structural milestone or walking skeleton, or "not applicable — existing path suffices">

## 4. Verification
```bash
<smallest decisive check set>
```
<What green proves, and what it does not.>

## 5. Risks and Hard Stops
- <risk or blocker, owner, evidence needed, whether it blocks now; for a hard stop, the exact forbidden action and the nearest allowed one> — or "None known."

## 6. Continuation Mission
- **Continue through:** <short outcome ladder>
- **Keep going until:** <Definition of Done or a named hard stop>

---
Read <continuation record> and do the continuation mission through its stop conditions, starting by <first concrete move as a gerund phrase>.
````

`STANDARD` adds a delegation map when lanes need coordination (lane, owner, single-writer boundary, evidence return), decision detail with relevant rejected alternatives, and later horizons when they guide continuation. `GOVERNED` adds separate truth and domain reviewers with their findings, and recovery or rollback evidence.

## Attribution

Baton derives from the **handoff** skill in [metaswarm](https://github.com/dsifry/metaswarm) by Dave Sifry (MIT License), keeping its self-contained document and exact closing-sentence contract while generalizing across runtimes.
Baton adds the human leverage gate, the four evidence classes, least-sufficient tier routing, and the mechanical check. See `NOTICE` for full attribution.
