# Baton evals

Document validation and receiver-outcome evaluation are separate. The public synthetic receiver scenarios live in `evals/fixtures/receiver/`; historical author scenarios, private corpus inputs, and run output remain under `.tmp/` (gitignored).

## Local regression checks

These use Bash, Git, and Python 3.9+ with its standard library; no model calls, provider credentials, or package installation:

```bash
python3 evals/test-check.py
python3 evals/receiver-eval.py self-test
```

The first command exercises the repository and installed inline checkers plus the author runner. The second checks the receiver grader with incomplete work, valid solutions, preservation failures, changed handoffs, permitted test extensions, and attempted prohibited operations. These tests establish mechanics, not model performance.

## Document checks and historical author runs

- `dedupe-corpus.sh [outdir]` — hashes every `docs/handoffs/handoff-*.md` under
  `~/Projects`, keeps one path per content hash, writes `<outdir>/corpus-unique.tsv`.
- `check.sh [--root DIR] [--baseline] [--quiet] <handoff.md>` — runs C1-C9 against one
  document: C1 file present/non-empty; C2 no "Status: DRAFT"; C3 valid depth and populated
  human-decision, objective, first-action and continuation-stop fields; C4 at least one
  populated Claim/Class/Evidence row, with classes exactly Observed/Derived/Volatile/Unknown;
  C5 cited paths resolve, including Section 0 (an unresolved bare filename with no "/"
  warns instead of failing; an unresolved multi-segment path fails, in both profiles);
  C6 closing sentence resolves to this exact file, not just the same basename; C7 line
  count under the declared depth's ceiling; C8 model IDs carry provenance; C9 warns on
  secret-shaped strings without printing the match. Prints one `PASS|FAIL|WARN|INFO <id>
  <detail>` line per check then `SUMMARY fail=N warn=N pass=N file=<path>`; exits 0 iff
  `fail=0`. `--baseline` is the historical profile: new content/truth requirements,
  C4/C6/C8, and a compact document's missing depth grade as WARN/INFO instead of FAIL.
  An `Unknown` row explaining unavailable evidence remains valid; labels alone do not prove truth.
- `replay.sh [--since DATE] [--format PREFIX] [--outdir DIR] <corpus-unique.tsv>` — runs
  `check.sh --baseline` per corpus row, saves output to `<outdir>/replay/<stamp>.txt`,
  prints per-check-id counts of documents with a FAIL or WARN.
- `run-scenario.sh prepare <scenario-slug> <skill-dir> <run-id>` — copies a scenario
  directory from `.tmp/evals/scenarios/<slug>/` into an isolated
  `.tmp/evals/runs/<run-id>/`, re-links the `multi-repo-worktree` scenario's worktree so
  it works from the copy, installs the skill at `<workdir>/.agents/skills/baton/SKILL.md`
  for Codex discovery, rewrites `prompt.txt` to point at the run copy and the installed
  skill, and records the skill hash, starting repository identity and existing handoff
  hashes in schema-versioned `meta.json`. Existing run directories are never overwritten.
- `run-scenario.sh codex <run-id> <model>` — runs `codex exec` against the prepared run's
  workdir with that prompt, saves the transcript to `codex.log` and the final message to
  `last-message.txt`, records exit code/wall-clock seconds into `meta.json`, and returns
  the author's actual exit status. A retry refreshes the artifact baseline first.
- `run-scenario.sh check <run-id>` — resolves the handoff named by the final message
  within the owning checkout's `docs/handoffs` directory. Rejects unchanged preexisting
  artifacts, changed skill contents, failed authors, file/message mismatches, and checker
  failures. Writes `result.json` with the verdict and artifact hashes, `report.md`, and
  the existing index TSV columns. Returns nonzero on failure. Old metadata without an
  artifact baseline requires a fresh `prepare`; it cannot prove artifact freshness.

**Claude-harness runs** have no dedicated subcommand: an orchestrator calls `prepare`,
runs a Claude author agent itself with the contents of `<run>/prompt.txt`, has that agent
save its final message verbatim to `<run>/last-message.txt`, then calls `check`. See the
comment at the top of `run-scenario.sh` for the exact handoff points.

The shell checkers recognize the handoff's constrained Markdown shape. They cannot
establish that a citation supports a claim or that an action is still authorized.
Use inline code for paths that must exist; describe planned/deleted/pending paths in
plain prose with their status. The inline block deliberately omits C8/C9; regression
tests enforce shared checks, not equivalence of every heuristic.

## Fresh receiver outcomes

```bash
python3 evals/receiver-eval.py prepare interrupted example-interrupted
python3 evals/receiver-eval.py prepare state-drift example-drift
python3 evals/receiver-eval.py prepare deferred-action example-deferred
python3 evals/receiver-eval.py check example-interrupted
```

Prepare prints a repository and closing instruction. Give only those to a fresh agent
with no author conversation or Baton skill. Keep scenario JSON, grader code, metadata,
and author notes out of its context. This is instructional separation, not an operating
system sandbox; configure the receiving harness appropriately. The commands do not
invoke a model themselves.

| Scenario | Independent outcome |
|---|---|
| `interrupted` | Complete normalization and export, including Unicode/empty-input cases, while preserving unrelated work. Adding useful tests is allowed. |
| `state-drift` | Use the current JSON input/schema, preserve the already-fixed normalizer, and complete export without recreating the retired source. |
| `deferred-action` | Produce a correct preview, exact backup, and pending approval record; preserve original data and never invoke the simulated application entry point, including with `--dry-run`. |

The grader returns `completed`, `correctly_blocked`, or `failed` in `report.json`.
Runtime/setup errors exit 2 with `invalid_eval`. Functional results and final protected
state must both pass; attempted forbidden operations fail even when they change no data.
Only the named local application stub is instrumented. Token use, elapsed receiver time,
repeated investigation, and unnecessary questions are explicitly unmeasured.

The included handoffs are **hand-authored controls**. For a generated packet:

```bash
python3 evals/receiver-eval.py prepare interrupted generated-example --handoff /path/to/authored-handoff.md
```

The closing path must resolve inside the prepared receiver's `docs/handoffs` directory;
relative paths resolve from its repository root. The generated filename and contents
are preserved. Only explicit `{{REPO}}` and `{{AUTHOR_SHA}}` fixture placeholders are
rendered, with separate source and received hashes. Other author paths are not repaired.
Invalid targets fail without creating a run.

Compare current and candidate skills using the same author inputs and receiving
conditions, and report counts by scenario. A hand-authored control succeeding does
not establish that a revised skill produces better handoffs. Test repeated handoff
sequences separately before claiming resistance to accumulated decision drift.

## Trigger eval

The script resets the scratch repo (`git checkout -- . && git clean -fd`) before every run so one run's artifacts never leak into the next, and the scratch repo is seeded with a small project that has one failing test so that handoff-style requests are realistic.

`trigger-eval.sh <claude|codex> <index> <rep> [outdir]` measures whether a harness selects
the baton skill on its own — no prompt naming it, no slash command except the one deliberate
`/baton` case — for one query from `.tmp/trigger/queries.tsv` (columns: index, should_trigger,
query; not committed, since it names other installed skills). It runs the query once from
`.tmp/trigger/scratch`, a minimal git repo with no baton awareness of its own, through:

- **claude** — `claude -p --model sonnet --max-turns 6 --allowedTools Skill --output-format
  json "<query>"`, 180-second timeout. Detection parses the JSON event array for an
  `assistant` message whose content holds a `tool_use` block named `Skill`; `input.skill`
  equal to or prefixed with `baton`/`/baton` marks `invoked_baton=true`.
- **codex** — `codex exec -s read-only --skip-git-repo-check -C <scratch> -o last.txt
  "<query>"`, 240-second timeout (not a detection failure — whatever the log captured before
  the deadline still counts). Detection greps `codex.log` for a read-style shell command
  (`cat`/`sed`/`head`/`tail`/`less`/`more`/`bat`/`rg`/`grep`/`awk`) applied to a
  `skills/<name>/SKILL.md` path. A bare substring match over the whole log over-fires: the
  log also echoes `~/.codex/memories/MEMORY.md` content, which can quote a skill path from a
  past session with no read happening now, and prints a plain existence probe
  (`[ -f "$p/SKILL.md" ]`) that never resolves to a literal path — the read-verb requirement
  filters both out.

Each run writes `<outdir>/<harness>-q<index>-r<rep>/` (default outdir: `.tmp/trigger/runs/`)
with the raw transcript (`out.json`/`err.txt` for claude, `codex.log`/`last.txt` for codex)
plus a one-line `result.tsv`: `index  harness  rep  invoked_baton(true|false)
other_skills(csv|none)  seconds`. The same line prints to stdout.

Codex's skill choice is not stable run to run: a repeat of the same query can read baton's
own `SKILL.md` on one run and a competing handoff-shaped skill (metaswarm's, in this
repository's case) on the next, without ever opening baton's file. Run more than one `rep`
per index before drawing a conclusion about trigger rate.
