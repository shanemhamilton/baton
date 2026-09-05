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

set -eu
set -o pipefail

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

valid_id() {
  [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || { echo "invalid scenario/run id" >&2; exit 2; }
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
  valid_id "$scenario"
  valid_id "$run_id"
  skill_dir=$(cd "$skill_dir" && pwd)

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
  case "$workdir_orig" in
    "$scenario_dir"/*) ;;
    *) echo "scenario workdir must be inside the scenario directory" >&2; exit 1 ;;
  esac
  suffix="${workdir_orig#"$scenario_dir"}"
  workdir="$run_dir$suffix"
  [ -d "$workdir" ] || { echo "computed workdir does not exist: $workdir" >&2; exit 1; }
  workdir=$(cd "$workdir" && pwd -P)
  physical_run=$(cd "$run_dir" && pwd -P)
  case "$workdir" in
    "$physical_run"/*) ;;
    *) echo "computed workdir escapes the run directory" >&2; exit 1 ;;
  esac

  # Install the skill where Codex's project-skill discovery looks for it.
  mkdir -p "$workdir/.agents/skills/baton"
  cp "$skill_dir/SKILL.md" "$workdir/.agents/skills/baton/SKILL.md"
  skill_path="$workdir/.agents/skills/baton/SKILL.md"

  # Rewrite every absolute path pointing into the scenario dir (the workdir
  # sentence, the SESSION.md reference, anything else) to point into the run
  # copy instead, and drop in the real skill path.
  python3 - "$scenario_dir" "$run_dir" "$skill_path" <<'PY_PROMPT'
import pathlib, sys
source, target, skill = sys.argv[1:]
prompt = (pathlib.Path(source) / "prompt.txt").read_text()
(pathlib.Path(target) / "prompt.txt").write_text(prompt.replace(source, target).replace("<SKILL_PATH>", skill))
PY_PROMPT

  skill_sha256=$(shasum -a 256 "$skill_dir/SKILL.md" | awk '{print $1}')
  created_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  python3 -c '
import hashlib, json, pathlib, subprocess, sys, time
(path, scenario, run_id, skill_dir, skill_sha256, workdir, skill_path,
 created_at) = sys.argv[1:]
def git(*args):
    result = subprocess.run(["git", "-C", workdir, *args], capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else None
run_dir = pathlib.Path(path).parent.resolve()
repo_root = git("rev-parse", "--show-toplevel")
if repo_root and run_dir not in pathlib.Path(repo_root).resolve().parents:
    repo_root = None  # a non-Git fixture must not inherit the outer Baton checkout
initial = {str(p.resolve()): hashlib.sha256(p.read_bytes()).hexdigest()
           for p in run_dir.glob("**/docs/handoffs/*.md") if p.is_file()}
data = {
    "schema_version": 2,
    "prepared_at_ns": time.time_ns(),
    "initial_handoffs": initial,
    "starting_repo": {"root": repo_root,
                      "head": git("rev-parse", "HEAD") if repo_root else None,
                      "branch": git("symbolic-ref", "--short", "HEAD") if repo_root else None,
                      "status_sha256": hashlib.sha256((git("status", "--porcelain") or "").encode()).hexdigest() if repo_root else None},
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
  valid_id "$run_id"
  run_dir="$RUNS_DIR/$run_id"
  meta="$run_dir/meta.json"
  [ -f "$meta" ] || { echo "no meta.json for run: $run_id (run prepare first)" >&2; exit 1; }

  workdir=$(meta_get "$meta" workdir)
  prompt_text=$(cat "$run_dir/prompt.txt")

  # Refresh artifact baseline on retries; a previous attempt is now preexisting.
  python3 - "$meta" "$run_dir" <<'PY_BASELINE'
import hashlib, json, pathlib, sys
path, run = map(pathlib.Path, sys.argv[1:])
meta = json.loads(path.read_text())
meta["initial_handoffs"] = {str(p.resolve()): hashlib.sha256(p.read_bytes()).hexdigest()
                            for p in run.glob("**/docs/handoffs/*.md") if p.is_file()}
path.write_text(json.dumps(meta, indent=2) + "\n")
PY_BASELINE
  meta_set "$meta" harness codex model "$model" exit_code pending
  start=$(date +%s)
  # Do not reuse a previous invocation's final message when the author fails.
  : > "$run_dir/last-message.txt"
  if codex exec -m "$model" -C "$workdir" --skip-git-repo-check \
    -o "$run_dir/last-message.txt" "$prompt_text" \
    > "$run_dir/codex.log" 2>&1; then
    exit_code=0
  else
    exit_code=$?
  fi
  end=$(date +%s)
  seconds=$((end - start))

  meta_set "$meta" harness codex model "$model" exit_code "$exit_code" seconds "$seconds"

  echo "codex exit_code=$exit_code seconds=$seconds"
  echo "final message: $run_dir/last-message.txt"
  return "$exit_code"
}

cmd_check() {
  [ $# -eq 1 ] || usage
  run_id="$1"
  valid_id "$run_id"
  run_dir="$RUNS_DIR/$run_id"
  [ -f "$run_dir/meta.json" ] || { echo "no meta.json for run: $run_id (run prepare first)" >&2; exit 1; }
  python3 - "$run_dir" "$CHECK_SH" <<'PY_CHECK'
import hashlib, json, pathlib, re, subprocess, sys

run = pathlib.Path(sys.argv[1]).resolve()
meta = json.loads((run / "meta.json").read_text())
workdir = pathlib.Path(meta["workdir"]).resolve()
errors = []
result = dict(meta)
result.update(handoff_found=False, closing_present=False, trailing_text=False,
              handoff_ends_with_closing=False, check_fail=None, check_warn=None)

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def inside(path, parent):
    return path == parent or parent in path.parents

def last_line(path):
    if not path.is_file():
        return "", False
    lines = path.read_text().splitlines()
    nonempty = [i for i, line in enumerate(lines) if line.strip()]
    if not nonempty:
        return "", False
    i = nonempty[-1]
    return lines[i].strip(), i != len(lines) - 1

# Old results cannot prove freshness: re-prepare rather than silently grade them.
if meta.get("schema_version") != 2 or "initial_handoffs" not in meta:
    errors.append("legacy metadata has no artifact baseline; prepare a new run")
if not inside(workdir, run):
    errors.append("workdir is outside this run")
if meta.get("harness") == "codex" and "exit_code" not in meta:
    errors.append("Codex author exit status is missing")
if "exit_code" in meta and str(meta["exit_code"]) != "0":
    errors.append("author exited unsuccessfully")
skill = pathlib.Path(meta.get("skill_path", ""))
if not skill.is_file() or digest(skill) != meta.get("skill_sha256"):
    errors.append("installed skill no longer matches prepared skill hash")

message = run / "last-message.txt"
closing, trailing = last_line(message)
result["last_message_sha256"] = digest(message) if message.is_file() else None
if message.is_file() and len([line for line in message.read_text().splitlines() if line.strip()]) != 1:
    errors.append("final message must contain only the closing sentence")
result["trailing_text"] = trailing
match = re.fullmatch(r"(?:\*\*)?Read (.+\.md) and do (.+)\.(?:\*\*)?", closing)
if not match:
    errors.append("final message does not end with the closing sentence")
else:
    result["closing_present"] = True
    target = pathlib.Path(match[1].strip("` ")).expanduser()
    handoff = (target if target.is_absolute() else workdir / target).resolve()
    result["handoff_file"] = str(handoff)
    if not inside(handoff, run):
        errors.append("closing sentence points outside this run")
    elif not handoff.is_file():
        errors.append("closing sentence points to a missing handoff")
    else:
        result["handoff_found"] = True
        result["handoff_sha256"] = digest(handoff)
        if meta.get("initial_handoffs", {}).get(str(handoff)) == result["handoff_sha256"]:
            errors.append("closing sentence selects an unchanged preexisting handoff")
        file_closing, _ = last_line(handoff)
        result["handoff_ends_with_closing"] = file_closing == closing
        if file_closing != closing:
            errors.append("final message does not quote the handoff final line exactly")
        if trailing:
            errors.append("blank lines follow the final message closing sentence")
        text = handoff.read_text()
        result["lines"] = len(text.splitlines())
        depth = re.search(r"Document depth:[*` ]*(COMPACT|STANDARD|GOVERNED)", text)
        result["declared_depth"] = depth[1] if depth else None
        # Resolve citations against the owning checkout, including sibling worktrees.
        root = subprocess.run(["git", "-C", str(handoff.parent), "rev-parse", "--show-toplevel"],
                              capture_output=True, text=True)
        check_root = pathlib.Path(root.stdout.strip()).resolve() if root.returncode == 0 else workdir
        if not inside(check_root, run):
            check_root = workdir  # non-Git scratch dirs can inherit the outer Baton repository
        # Keep accepted artifacts inside the same scope captured by the freshness baseline.
        if handoff.parent != check_root / "docs" / "handoffs":
            errors.append("handoff must be in the owning checkout docs/handoffs directory")
        checked = subprocess.run(["bash", sys.argv[2], "--root", str(check_root), str(handoff)],
                                 capture_output=True, text=True)
        (run / "check.txt").write_text(checked.stdout + checked.stderr)
        summary = re.search(r"^SUMMARY fail=(\d+) warn=(\d+) pass=\d+ file=", checked.stdout, re.M)
        result["check_fail"] = int(summary[1]) if summary else None
        result["check_warn"] = int(summary[2]) if summary else None
        result["checker_exit_code"] = checked.returncode
        if checked.returncode != 0 or summary is None or int(summary[1]) != 0:
            errors.append("handoff validation failed")

result["verdict"] = "fail" if errors else "pass"
result["errors"] = errors
(run / "result.json").write_text(json.dumps(result, indent=2) + "\n")
report = [f"# Run report: {meta['run_id']}", "", f"- verdict: {result['verdict']}"]
for key in ("scenario", "harness", "model", "skill_sha256", "workdir", "seconds",
            "handoff_found", "handoff_file", "handoff_sha256", "last_message_sha256",
            "lines", "declared_depth", "closing_present", "trailing_text",
            "handoff_ends_with_closing", "check_fail", "check_warn"):
    report.append(f"- {key}: {result.get(key)}")
report.extend(["", "## Failures", *[f"- {error}" for error in errors]])
(run / "report.md").write_text("\n".join(report) + "\n")
# Preserve the existing TSV columns; result.json carries the full verdict and hashes.
index = run.parent / "index.tsv"
columns = ("run_id", "scenario", "harness", "model", "skill_sha256_8", "handoff_found",
           "check_fail", "check_warn", "closing_present", "trailing_text", "lines", "seconds")
result["skill_sha256_8"] = meta.get("skill_sha256", "")[:8]
with index.open("a") as stream:
    if index.stat().st_size == 0:
        stream.write("\t".join(columns) + "\n")
    stream.write("\t".join(str(result.get(key, "")).lower() if isinstance(result.get(key), bool)
                            else str(result.get(key, "")) for key in columns) + "\n")
print("\n".join(report))
sys.exit(bool(errors))
PY_CHECK
}

[ $# -ge 1 ] || usage
subcmd="$1"; shift
case "$subcmd" in
  prepare) cmd_prepare "$@" ;;
  codex) cmd_codex "$@" ;;
  check) cmd_check "$@" ;;
  *) usage ;;
esac
