#!/bin/bash
# trigger-eval.sh -- does a harness pick the baton skill on its own for one
# realistic query, with no hint that baton exists? bash 3.2 compatible
# (macOS default): no associative arrays, no mapfile/readarray. Depends on:
# python3 (JSON parsing for the Claude lane only), and whichever of the two
# harness CLIs the caller selects (`claude`, `codex`). Uses `timeout` /
# `gtimeout` when present, else a background-job watchdog.
#
# Usage:
#   trigger-eval.sh <claude|codex> <index> <rep> [outdir]
#
# Reads the query for <index> from .tmp/trigger/queries.tsv (columns: index,
# should_trigger, query), runs it once against the chosen harness from
# .tmp/trigger/scratch, and writes <outdir>/<harness>-q<index>-r<rep>/
# containing the raw transcript plus a one-line result.tsv:
#   index  harness  rep  invoked_baton(true|false)  other_skills(csv|none)  seconds
# The same line is printed to stdout.
#
# Detection:
#   claude -- parse out.json (a JSON array of stream events; see smoke test
#     evidence in evals/README.md) for assistant events whose message.content
#     holds a tool_use block with name "Skill"; its input.skill names the
#     invoked skill. invoked_baton is true when that name is "baton" or
#     starts with "baton"/"/baton". A bare "/baton" query with no such block
#     still counts if the assistant's own text carries a baton-skill
#     fingerprint (a docs/handoffs/handoff- path or "Continuation Mission").
#   codex -- grep codex.log for a read-style shell command (cat/sed/head/
#     tail/less/more/bat/rg/grep/awk) applied to a "skills/<name>/SKILL.md"
#     path (however the command spells the path -- ~/.agents or a relative
#     .agents both match). Requiring the verb on the same line, rather than
#     a bare substring match anywhere in the log, was necessary in practice:
#     codex.log also echoes ~/.codex/memories/MEMORY.md content, which can
#     narrate a past session's skill path with no read happening now, and
#     prints a plain existence probe (`[ -f "$p/SKILL.md" ]`) that never
#     resolves to a literal path. invoked_baton is true iff <name> is
#     "baton"; every other <name> read goes into other_skills. A timeout is
#     not treated as a detection failure -- whatever the log captured before
#     the deadline is still scanned.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATON_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
QUERIES_TSV="$BATON_ROOT/.tmp/trigger/queries.tsv"
SCRATCH_DIR="$BATON_ROOT/.tmp/trigger/scratch"
DEFAULT_RUNS_DIR="$BATON_ROOT/.tmp/trigger/runs"

CLAUDE_TIMEOUT_SECS=300
CODEX_TIMEOUT_SECS=240

usage() {
  echo "Usage: trigger-eval.sh <claude|codex> <index> <rep> [outdir]" >&2
  exit 2
}

# run_with_timeout <seconds> -- <cmd...>  Prefers timeout/gtimeout; falls
# back to a background job plus a sleep-and-kill watchdog when neither is on
# PATH. Exit status is the command's own (or the timeout wrapper's), and a
# timeout here is reported to the caller by exit code only -- callers that
# treat timeouts as non-fatal (the codex lane) just ignore the status.
run_with_timeout() {
  secs="$1"; shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$secs" "$@"
    return $?
  fi
  if command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$secs" "$@"
    return $?
  fi
  "$@" &
  pid=$!
  ( sleep "$secs"; kill -TERM "$pid" 2>/dev/null ) &
  watchdog=$!
  wait "$pid"
  status=$?
  kill "$watchdog" 2>/dev/null
  wait "$watchdog" 2>/dev/null
  return $status
}

# get_query <index> -- sets QUERY and SHOULD_TRIGGER globals, or exits 1.
get_query() {
  idx="$1"
  line=$(awk -F'\t' -v i="$idx" '$1==i{print; exit}' "$QUERIES_TSV")
  if [ -z "$line" ]; then
    echo "no such index in $QUERIES_TSV: $idx" >&2
    exit 1
  fi
  SHOULD_TRIGGER=$(echo "$line" | cut -f2)
  QUERY=$(echo "$line" | cut -f3-)
}

# parse_claude_json <json_file> <query> -- prints "invoked_baton\tother_skills"
parse_claude_json() {
  python3 - "$1" "$2" <<'PYEOF'
import json, sys

json_file, query = sys.argv[1], sys.argv[2]

def emit(invoked, others):
    print(("true" if invoked else "false") + "\t" + (",".join(others) if others else "none"))

try:
    with open(json_file) as f:
        data = json.load(f)
except Exception:
    emit(False, [])
    sys.exit(0)

if not isinstance(data, list):
    emit(False, [])
    sys.exit(0)

invoked_baton = False
other_skills = []
seen = set()

for ev in data:
    if not isinstance(ev, dict) or ev.get("type") != "assistant":
        continue
    for block in (ev.get("message") or {}).get("content") or []:
        if not isinstance(block, dict) or block.get("type") != "tool_use":
            continue
        if block.get("name") != "Skill":
            continue
        name = (block.get("input") or {}).get("skill")
        if not isinstance(name, str):
            continue
        norm = name.lstrip("/")
        if norm == "baton" or norm.startswith("baton"):
            invoked_baton = True
        elif norm not in seen:
            seen.add(norm)
            other_skills.append(norm)

# Bare "/baton" with no captured tool_use: fall back to a content fingerprint
# in the assistant's own text (see module docstring for why).
if not invoked_baton and query.strip() == "/baton":
    for ev in data:
        if not isinstance(ev, dict) or ev.get("type") != "assistant":
            continue
        for block in (ev.get("message") or {}).get("content") or []:
            if isinstance(block, dict) and block.get("type") == "text":
                text = block.get("text", "")
                if "docs/handoffs/handoff-" in text or "Continuation Mission" in text:
                    invoked_baton = True

emit(invoked_baton, other_skills)
PYEOF
}

run_claude() {
  rundir="$1"
  out_json="$rundir/out.json"
  err_txt="$rundir/err.txt"

  start=$(date +%s)
  ( cd "$SCRATCH_DIR" && run_with_timeout "$CLAUDE_TIMEOUT_SECS" \
      claude -p --model sonnet --max-turns 6 --allowedTools Skill \
      --output-format json "$QUERY" ) > "$out_json" 2> "$err_txt"
  end=$(date +%s)
  SECONDS_ELAPSED=$((end - start))

  DETECTION=$(parse_claude_json "$out_json" "$QUERY")
  INVOKED_BATON=$(echo "$DETECTION" | cut -f1)
  OTHER_SKILLS=$(echo "$DETECTION" | cut -f2)
}

run_codex() {
  rundir="$1"
  codex_log="$rundir/codex.log"
  last_txt="$rundir/last.txt"

  start=$(date +%s)
  ( cd "$SCRATCH_DIR" && run_with_timeout "$CODEX_TIMEOUT_SECS" \
      codex exec -s read-only --skip-git-repo-check -C "$SCRATCH_DIR" \
      -o "$last_txt" "$QUERY" ) > "$codex_log" 2>&1
  end=$(date +%s)
  SECONDS_ELAPSED=$((end - start))
  # A timeout is not a detection failure: whatever the log captured stands.

  # A bare substring match over the whole log over-fires: codex.log also
  # echoes ~/.codex/memories/MEMORY.md content (which narrates past sessions
  # and can quote a "skills/<name>/SKILL.md" path with no read happening
  # now) and prints a plain existence probe (`[ -f "$p/SKILL.md" ]`) that
  # never resolves to a literal path string at all. A real read is a shell
  # command that opens the file, so require a read-style verb on the same
  # log line as the path -- observed in this smoke test as `sed -n
  # '<range>' <path>`, which is what a genuine skill load looks like here.
  read_lines=$(grep -nE '\b(cat|sed|head|tail|less|more|bat|rg|grep|awk)\b.*skills/[A-Za-z0-9_.-]+/SKILL\.md' "$codex_log")

  INVOKED_BATON="false"
  if echo "$read_lines" | grep -q 'skills/baton/SKILL\.md'; then
    INVOKED_BATON="true"
  fi
  OTHER_SKILLS=$(echo "$read_lines" | grep -oE 'skills/[A-Za-z0-9_.-]+/SKILL\.md' \
    | sed -E 's#skills/([^/]+)/SKILL\.md#\1#' \
    | grep -v '^baton$' | sort -u | paste -sd, -)
  [ -z "$OTHER_SKILLS" ] && OTHER_SKILLS="none"
}

[ $# -ge 3 ] && [ $# -le 4 ] || usage
HARNESS="$1"; INDEX="$2"; REP="$3"; RUNS_DIR="${4:-$DEFAULT_RUNS_DIR}"

case "$HARNESS" in
  claude|codex) ;;
  *) usage ;;
esac
case "$INDEX" in ''|*[!0-9]*) usage ;; esac
case "$REP" in ''|*[!0-9]*) usage ;; esac

[ -f "$QUERIES_TSV" ] || { echo "missing query file: $QUERIES_TSV" >&2; exit 1; }
[ -d "$SCRATCH_DIR" ] || { echo "missing scratch dir: $SCRATCH_DIR" >&2; exit 1; }

get_query "$INDEX"

# Reset the scratch repo so one run's artifacts (a written HANDOFF.md, a
# created file) never leak into the next run's context.
( cd "$SCRATCH_DIR" && git checkout -q -- . 2>/dev/null; git clean -fdq 2>/dev/null ) || true

RUN_DIR="$RUNS_DIR/${HARNESS}-q${INDEX}-r${REP}"
mkdir -p "$RUN_DIR"
printf 'should_trigger\t%s\nquery\t%s\n' "$SHOULD_TRIGGER" "$QUERY" > "$RUN_DIR/query.txt"

if [ "$HARNESS" = "claude" ]; then
  run_claude "$RUN_DIR"
else
  run_codex "$RUN_DIR"
fi

RESULT_LINE=$(printf '%s\t%s\t%s\t%s\t%s\t%s' \
  "$INDEX" "$HARNESS" "$REP" "$INVOKED_BATON" "$OTHER_SKILLS" "$SECONDS_ELAPSED")
echo "$RESULT_LINE" > "$RUN_DIR/result.tsv"
echo "$RESULT_LINE"
