# Baton evals

Mechanical checks for handoff documents (plan: `docs/plans/2026-09-01-baton-v2-rationalization-plan.md`
sections 6, 8). Fixtures, scenario repos, and run output live under `.tmp/evals/` (gitignored) — only these scripts are committed.

- `dedupe-corpus.sh [outdir]` — hashes every `docs/handoffs/handoff-*.md` under
  `~/Projects`, keeps one path per content hash, writes `<outdir>/corpus-unique.tsv`.
- `check.sh [--root DIR] [--baseline] [--quiet] <handoff.md>` — runs C1-C9 against one
  document: C1 file present/non-empty; C2 no "Status: DRAFT"; C3 depth/human-decision/
  Continuation-Mission fields present; C4 evidence class is exactly Observed/Derived/
  Volatile/Unknown; C5 cited paths resolve (an unresolved bare filename with no "/"
  warns instead of failing; an unresolved multi-segment path fails, in both profiles);
  C6 closing sentence names this file; C7 line
  count under the declared depth's ceiling; C8 model IDs carry provenance; C9 warns on
  secret-shaped strings without printing the match. Prints one `PASS|FAIL|WARN|INFO <id>
  <detail>` line per check then `SUMMARY fail=N warn=N pass=N file=<path>`; exits 0 iff
  `fail=0`. `--baseline` is the v1 profile for replaying old documents: C4/C6/C8, and a
  compact document's missing depth, grade as WARN/INFO instead of FAIL.
- `replay.sh [--since DATE] [--format PREFIX] [--outdir DIR] <corpus-unique.tsv>` — runs
  `check.sh --baseline` per corpus row, saves output to `<outdir>/replay/<stamp>.txt`,
  prints per-check-id counts of documents with a FAIL or WARN.
- `run-scenario.sh prepare <scenario-slug> <skill-dir> <run-id>` — copies a scenario
  directory from `.tmp/evals/scenarios/<slug>/` into an isolated
  `.tmp/evals/runs/<run-id>/`, re-links the `multi-repo-worktree` scenario's worktree so
  it works from the copy, installs the skill at `<workdir>/.agents/skills/baton/SKILL.md`
  for Codex discovery, rewrites `prompt.txt` to point at the run copy and the installed
  skill, and writes `meta.json`.
- `run-scenario.sh codex <run-id> <model>` — runs `codex exec` against the prepared run's
  workdir with that prompt, saves the transcript to `codex.log` and the final message to
  `last-message.txt`, and records exit code/wall-clock seconds into `meta.json`.
- `run-scenario.sh check <run-id>` — finds the run's handoff file, scores it with
  `check.sh --root <workdir>` (v2 profile), checks the last message for the closing
  sentence and any trailing text, checks the handoff for DRAFT/deferred-decision markers
  and its own closing line, writes `<run>/report.md`, and appends one row to
  `.tmp/evals/runs/index.tsv`.

**Claude-harness runs** have no dedicated subcommand: an orchestrator calls `prepare`,
runs a Claude author agent itself with the contents of `<run>/prompt.txt`, has that agent
save its final message verbatim to `<run>/last-message.txt`, then calls `check`. See the
comment at the top of `run-scenario.sh` for the exact handoff points.

`check.sh` does regex matching, not Markdown parsing, so a git ref or version string can
read as an unresolved path — expected noise on real corpus documents, not a bug.

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
