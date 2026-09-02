#!/bin/bash
# Eval-scenario runner: turns one scenario directory under .tmp/evals/scenarios/
# into an isolated run under .tmp/evals/runs/<run-id>/, drives it through an
# author (Codex directly, or Claude via an external orchestrator), and scores
# the result with check.sh. bash 3.2 compatible (macOS default): no
# associative arrays, no mapfile/readarray. Depends on: git, python3 (for all
# JSON read/write), rsync, tar, shasum, and (for the "codex" subcommand) the
# codex CLI on PATH.
#
# Usage:
#   run-scenario.sh prepare <scenario-slug> <skill-dir> <run-id>
#   run-scenario.sh codex   <run-id> <model>
#   run-scenario.sh check   <run-id>
#
# CLAUDE-HARNESS WORKFLOW (no dedicated subcommand — driven by an orchestrator):
#   1. orchestrator runs: run-scenario.sh prepare <scenario-slug> <skill-dir> <run-id>
#   2. orchestrator reads <run>/prompt.txt and runs it through a Claude author
#      agent itself (Task/Agent tool, etc.) with that exact prompt text, and
#      tells the agent to save its final message verbatim to
#      <run>/last-message.txt.
#   3. orchestrator runs: run-scenario.sh check <run-id>
#   There is no "claude" subcommand here because driving a Claude agent is the
#   orchestrator's job, not a shell script's. meta.json still gets an
#   "harness"/"model" pair so `check` always has something to report; the
#   orchestrator may patch those two fields in meta.json before calling
#   `check` if it wants an accurate model name recorded in the index row.
#
# See evals/README.md for what each subcommand does in prose.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATON_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCENARIOS_DIR="$BATON_ROOT/.tmp/evals/scenarios"
RUNS_DIR="$BATON_ROOT/.tmp/evals/runs"
CHECK_SH="$SCRIPT_DIR/check.sh"

usage() {
  cat >&2 <<'EOF'
Usage:
  run-scenario.sh prepare <scenario-slug> <skill-dir> <run-id>
  run-scenario.sh codex   <run-id> <model>
  run-scenario.sh check   <run-id>
EOF
  exit 2
}

# meta_get <meta.json> <key> -- prints "" if the key is missing.
meta_get() {
  python3 -c '
import json, sys
path, key = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
print(data.get(key, ""))
' "$1" "$2"
}

# meta_set <meta.json> key1 val1 [key2 val2 ...] -- merges key/value pairs in.
meta_set() {
  python3 -c '
import json, sys
path = sys.argv[1]
pairs = sys.argv[2:]
with open(path) as f:
    data = json.load(f)
for i in range(0, len(pairs), 2):
    data[pairs[i]] = pairs[i + 1]
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
' "$@"
}

cmd_prepare() {
  [ $# -eq 3 ] || usage
  scenario="$1"; skill_dir="$2"; run_id="$3"

  scenario_dir="$SCENARIOS_DIR/$scenario"
  [ -d "$scenario_dir" ] || { echo "no such scenario: $scenario_dir" >&2; exit 1; }
  [ -f "$skill_dir/SKILL.md" ] || { echo "no SKILL.md under: $skill_dir" >&2; exit 1; }
  [ -f "$scenario_dir/prompt.txt" ] || { echo "scenario missing prompt.txt: $scenario_dir" >&2; exit 1; }

  run_dir="$RUNS_DIR/$run_id"
  if [ -e "$run_dir" ]; then
    echo "run dir already exists, refusing to clobber: $run_dir" >&2
    exit 1
  fi
  mkdir -p "$run_dir"

  # Copy the whole scenario dir (repo/, repo-b/, worktree-feature/, SESSION.md,
  # prompt.txt, rubric.json, any .tmp files) into the run copy. tar preserves
  # dotfiles (.git, .gitignore) and permissions more reliably across BSD/GNU
  # cp variants than a plain `cp -R src/. dst`.
  (cd "$scenario_dir" && tar cf - .) | (cd "$run_dir" && tar xf -)

  # multi-repo-worktree only: the copied worktree-feature/ is a broken clone
  # of the ORIGINAL scenario's worktree — its .git file and repo/.git/worktrees
  # registration both still point at the scenario path, not this run copy.
  # Rebuild the worktree link fresh inside the copy, then restore the dirty,
  # uncommitted working-tree edit that made this scenario worth having.
  if [ "$scenario" = "multi-repo-worktree" ]; then
    rm -rf "$run_dir/worktree-feature"
    rm -rf "$run_dir/repo/.git/worktrees/worktree-feature"
    git -C "$run_dir/repo" worktree prune >/dev/null
    git -C "$run_dir/repo" worktree add "$run_dir/worktree-feature" feature/limits >/dev/null
    rsync -a --exclude='.git' "$scenario_dir/worktree-feature/" "$run_dir/worktree-feature/"
    if ! git -C "$run_dir/worktree-feature" status --porcelain | grep -q .; then
      echo "worktree relink failed to reproduce the dirty working tree: $run_dir/worktree-feature" >&2
      exit 1
    fi
    echo "worktree relink verified dirty:"
    git -C "$run_dir/worktree-feature" status --short
  fi

  # The working directory the prompt names is "<scenario_dir><suffix>" (e.g.
  # ".../repo" or ".../worktree-feature", for multi-repo-worktree); pull the
  # suffix out of the prompt text itself rather than assuming one per scenario.
  workdir_orig=$(sed -n 's/.*session in \(.*\)\. Your memory.*/\1/p' "$scenario_dir/prompt.txt")
  if [ -z "$workdir_orig" ]; then
    echo "could not find 'session in <path>.' in $scenario_dir/prompt.txt" >&2
    exit 1
  fi
  suffix="${workdir_orig#"$scenario_dir"}"
  workdir="$run_dir$suffix"
  [ -d "$workdir" ] || { echo "computed workdir does not exist: $workdir" >&2; exit 1; }

  # Install the skill where Codex's project-skill discovery looks for it.
  mkdir -p "$workdir/.agents/skills/baton"
  cp "$skill_dir/SKILL.md" "$workdir/.agents/skills/baton/SKILL.md"
  skill_path="$workdir/.agents/skills/baton/SKILL.md"

  # Rewrite every absolute path pointing into the scenario dir (the workdir
  # sentence, the SESSION.md reference, anything else) to point into the run
  # copy instead, and drop in the real skill path.
  sed -e "s#$scenario_dir#$run_dir#g" -e "s#<SKILL_PATH>#$skill_path#g" \
    "$scenario_dir/prompt.txt" > "$run_dir/prompt.txt"

  skill_sha256=$(shasum -a 256 "$skill_dir/SKILL.md" | awk '{print $1}')
  created_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  python3 -c '
import json, sys
(path, scenario, run_id, skill_dir, skill_sha256, workdir, skill_path,
 created_at) = sys.argv[1:]
data = {
    "scenario": scenario,
    "run_id": run_id,
    "skill_dir": skill_dir,
    "skill_sha256": skill_sha256,
    "workdir": workdir,
    "skill_path": skill_path,
    "created_at": created_at,
    "harness": "unknown",
    "model": "",
}
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
' "$run_dir/meta.json" "$scenario" "$run_id" "$skill_dir" "$skill_sha256" \
    "$workdir" "$skill_path" "$created_at"

  echo "prepared: $run_dir"
  echo "workdir:  $workdir"
  echo "prompt:   $run_dir/prompt.txt"
  echo "meta:     $run_dir/meta.json"
}

cmd_codex() {
  [ $# -eq 2 ] || usage
  run_id="$1"; model="$2"
  run_dir="$RUNS_DIR/$run_id"
  meta="$run_dir/meta.json"
  [ -f "$meta" ] || { echo "no meta.json for run: $run_id (run prepare first)" >&2; exit 1; }

  workdir=$(meta_get "$meta" workdir)
  prompt_text=$(cat "$run_dir/prompt.txt")

  start=$(date +%s)
  codex exec -m "$model" -C "$workdir" --skip-git-repo-check \
    -o "$run_dir/last-message.txt" "$prompt_text" \
    > "$run_dir/codex.log" 2>&1
  exit_code=$?
  end=$(date +%s)
  seconds=$((end - start))

  meta_set "$meta" harness codex model "$model" exit_code "$exit_code" seconds "$seconds"

  echo "codex exit_code=$exit_code seconds=$seconds"
  echo "--- last message (${run_dir}/last-message.txt) ---"
  if [ -f "$run_dir/last-message.txt" ]; then
    cat "$run_dir/last-message.txt"
  else
    echo "(no last-message.txt written; see $run_dir/codex.log)"
  fi
}

# find_handoff <dir> -- first docs/handoffs/handoff-*.md under <dir>, or "".
find_handoff() {
  find "$1" -path '*/docs/handoffs/handoff-*.md' -type f 2>/dev/null | sort | head -1
}

# closing_sentence_line <file> -- prints "<total_lines>\t<last_nonempty_ln>\t<last_nonempty_text>"
closing_sentence_line() {
  awk '
    { if (NF) { ln = NR; text = $0 } total = NR }
    END { printf "%d\t%d\t%s\n", total, ln, text }
  ' "$1"
}

matches_closing() {
  # ^\**Read .+\.md and do .+\.\**$ , tolerating a leading/trailing "**"
  echo "$1" | grep -qE '^\*{0,2}Read .+\.md and do .+\.\*{0,2}$'
}

cmd_check() {
  [ $# -eq 1 ] || usage
  run_id="$1"
  run_dir="$RUNS_DIR/$run_id"
  meta="$run_dir/meta.json"
  [ -f "$meta" ] || { echo "no meta.json for run: $run_id (run prepare first)" >&2; exit 1; }

  scenario=$(meta_get "$meta" scenario)
  workdir=$(meta_get "$meta" workdir)
  skill_sha256=$(meta_get "$meta" skill_sha256)
  harness=$(meta_get "$meta" harness)
  model=$(meta_get "$meta" model)
  seconds=$(meta_get "$meta" seconds)

  # Search workdir, plus <run>/repo when that's a different directory
  # (multi-repo-worktree: workdir is worktree-feature, but repo/ shares the
  # same .git and could be where a handoff landed instead).
  handoff_file=$(find_handoff "$workdir")
  if [ -z "$handoff_file" ] && [ -d "$run_dir/repo" ] && [ "$workdir" != "$run_dir/repo" ]; then
    handoff_file=$(find_handoff "$run_dir/repo")
  fi

  handoff_found=false
  check_fail=""
  check_warn=""
  check_summary=""
  lines=""
  declared_depth=""
  has_draft=false
  has_deferred_or_decision_state=false
  handoff_ends_with_closing=false

  if [ -n "$handoff_file" ]; then
    handoff_found=true
    "$CHECK_SH" --root "$workdir" "$handoff_file" > "$run_dir/check.txt" 2>&1
    check_summary=$(grep '^SUMMARY' "$run_dir/check.txt" || true)
    check_fail=$(echo "$check_summary" | sed -n 's/.*fail=\([0-9]*\).*/\1/p')
    check_warn=$(echo "$check_summary" | sed -n 's/.*warn=\([0-9]*\).*/\1/p')

    lines=$(wc -l < "$handoff_file" | tr -d ' ')

    depth_line=$(grep -m1 -F "Document depth:" "$handoff_file" || true)
    if [ -n "$depth_line" ]; then
      declared_depth=$(echo "$depth_line" | grep -oE 'COMPACT|STANDARD|GOVERNED' | head -1)
    fi

    if sed 's/\*//g' "$handoff_file" | grep -qiE 'status:[[:space:]]*draft'; then
      has_draft=true
    fi
    if grep -qiE 'deferred by absence|Human decision state' "$handoff_file"; then
      has_deferred_or_decision_state=true
    fi

    handoff_line_info=$(closing_sentence_line "$handoff_file")
    handoff_last_nonempty=$(echo "$handoff_line_info" | cut -f3-)
    if matches_closing "$handoff_last_nonempty"; then
      handoff_ends_with_closing=true
    fi
  fi

  # Last message: closing sentence present + whether anything (even a blank
  # line) follows the last non-empty line.
  closing_present=false
  trailing_text=false
  last_msg="$run_dir/last-message.txt"
  if [ -f "$last_msg" ]; then
    msg_line_info=$(closing_sentence_line "$last_msg")
    msg_total=$(echo "$msg_line_info" | cut -f1)
    msg_last_ln=$(echo "$msg_line_info" | cut -f2)
    msg_last_text=$(echo "$msg_line_info" | cut -f3-)
    if matches_closing "$msg_last_text"; then
      closing_present=true
    fi
    if [ -n "$msg_last_ln" ] && [ "$msg_total" -gt "$msg_last_ln" ]; then
      trailing_text=true
    fi
  fi

  {
    echo "# Run report: $run_id"
    echo
    echo "- scenario: $scenario"
    echo "- harness: $harness"
    echo "- model: $model"
    echo "- skill_sha256: $skill_sha256"
    echo "- workdir: $workdir"
    echo "- seconds: $seconds"
    echo
    echo "## Handoff"
    echo "- handoff_found: $handoff_found"
    echo "- handoff_file: ${handoff_file:-none}"
    echo "- lines: $lines"
    echo "- declared_depth: ${declared_depth:-none}"
    echo "- status_draft_remains: $has_draft"
    echo "- has_deferred_by_absence_or_human_decision_state: $has_deferred_or_decision_state"
    echo "- handoff_last_line_is_closing_sentence: $handoff_ends_with_closing"
    echo
    echo "## Last message"
    echo "- closing_present: $closing_present"
    echo "- trailing_text: $trailing_text"
    echo
    echo "## check.sh"
    echo "- ${check_summary:-not run (no handoff found)}"
  } > "$run_dir/report.md"

  mkdir -p "$RUNS_DIR"
  index="$RUNS_DIR/index.tsv"
  if [ ! -f "$index" ]; then
    printf 'run_id\tscenario\tharness\tmodel\tskill_sha256_8\thandoff_found\tcheck_fail\tcheck_warn\tclosing_present\ttrailing_text\tlines\tseconds\n' > "$index"
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$run_id" "$scenario" "$harness" "$model" "${skill_sha256:0:8}" \
    "$handoff_found" "$check_fail" "$check_warn" "$closing_present" \
    "$trailing_text" "$lines" "$seconds" >> "$index"

  cat "$run_dir/report.md"
}

[ $# -ge 1 ] || usage
subcmd="$1"; shift
case "$subcmd" in
  prepare) cmd_prepare "$@" ;;
  codex) cmd_codex "$@" ;;
  check) cmd_check "$@" ;;
  *) usage ;;
esac
