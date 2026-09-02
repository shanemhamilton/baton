#!/bin/bash
# Mechanical checks for a Baton handoff document. bash 3.2 compatible (macOS default),
# no dependencies beyond coreutils/grep/sed/awk (+ git, only to find a default --root).
#
# Usage: check.sh [--root <repo-root>] [--baseline] [--quiet] <handoff.md>
#
# Prints one line per check: "PASS|FAIL|WARN|INFO <id> <detail>" and a final
# "SUMMARY fail=<n> warn=<n> pass=<n> file=<path>" line. Exits 0 when fail=0, else 1.
#
# --baseline replays the v1-profile used for old documents written before the checker
# existed: it downgrades C6 to INFO, non-exact C4 classes to WARN, C8 to WARN, and a
# missing "Document depth:" on a compact (Launch Contract) document to WARN. Without
# it, the v2 profile applies and those are FAIL.
#
# See docs/plans/2026-09-01-baton-v2-rationalization-plan.md sections 6 and 8, and
# evals/README.md for what each check id (C1-C9) means.

ROOT=""
BASELINE=0
QUIET=0
FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --root)
      [ $# -lt 2 ] && { echo "--root needs a value" >&2; exit 2; }
      ROOT="$2"
      shift 2
      ;;
    --baseline)
      BASELINE=1
      shift
      ;;
    --quiet)
      QUIET=1
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--root <repo-root>] [--baseline] [--quiet] <handoff.md>"
      exit 0
      ;;
    *)
      FILE="$1"
      shift
      ;;
  esac
done

if [ -z "$FILE" ]; then
  echo "Usage: $0 [--root <repo-root>] [--baseline] [--quiet] <handoff.md>" >&2
  exit 2
fi

TMPDIR_CHECK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_CHECK"' EXIT

FAIL=0
WARN=0
PASS=0

emit() {
  level="$1"; id="$2"; shift 2
  case "$level" in
    FAIL) FAIL=$((FAIL+1)) ;;
    WARN) WARN=$((WARN+1)) ;;
    PASS) PASS=$((PASS+1)) ;;
  esac
  if [ "$QUIET" = "1" ]; then
    case "$level" in
      PASS|INFO) return ;;
    esac
  fi
  echo "$level $id $*"
}

print_summary() {
  echo "SUMMARY fail=$FAIL warn=$WARN pass=$PASS file=$FILE"
}

if [ "$BASELINE" = "1" ]; then
  SEV_C4=WARN
  SEV_C6=INFO
  SEV_C8=WARN
else
  SEV_C4=FAIL
  SEV_C6=FAIL
  SEV_C8=FAIL
fi

# --- C1: file exists and is non-empty ---
if [ ! -f "$FILE" ]; then
  emit FAIL C1 "file does not exist: $FILE"
  print_summary
  exit 1
fi
if [ ! -s "$FILE" ]; then
  emit FAIL C1 "file is empty: $FILE"
  print_summary
  exit 1
fi
emit PASS C1 "file exists and is non-empty"

# --- default ROOT: git toplevel of the handoff's directory, else its directory ---
handoff_dir=$(cd "$(dirname "$FILE")" 2>/dev/null && pwd)
[ -z "$handoff_dir" ] && handoff_dir="."
if [ -z "$ROOT" ]; then
  git_root=$(cd "$handoff_dir" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$git_root" ]; then
    ROOT="$git_root"
  else
    ROOT="$handoff_dir"
  fi
fi

# --- C2: no "Status: DRAFT" line (case-insensitive, ** allowed) ---
sed 's/\*//g' "$FILE" | grep -inE 'status:[[:space:]]*draft' > "$TMPDIR_CHECK/c2.txt" 2>/dev/null
if [ -s "$TMPDIR_CHECK/c2.txt" ]; then
  while IFS=: read -r ln rest; do
    emit FAIL C2 "line $ln: \"Status: DRAFT\" present"
  done < "$TMPDIR_CHECK/c2.txt"
else
  emit PASS C2 "no \"Status: DRAFT\" line found"
fi

# --- C3: required fields ---
has_launch_contract=0
grep -qF "Launch Contract" "$FILE" && has_launch_contract=1

if grep -qF "Document depth:" "$FILE"; then
  emit PASS C3 "\"Document depth:\" field present"
else
  if [ "$BASELINE" = "1" ] && [ "$has_launch_contract" = "1" ]; then
    emit WARN C3 "\"Document depth:\" field missing on compact (Launch Contract) document"
  else
    emit FAIL C3 "\"Document depth:\" field missing"
  fi
fi

if grep -qF "Human decision state:" "$FILE"; then
  emit PASS C3 "\"Human decision state:\" field present"
else
  emit FAIL C3 "\"Human decision state:\" field missing"
fi

if grep -qE '^#+.*Continuation Mission' "$FILE"; then
  emit PASS C3 "\"Continuation Mission\" heading present"
else
  emit FAIL C3 "\"Continuation Mission\" heading missing"
fi

# --- C4: evidence classes ---
# 4a: every markdown table with a "Class" header column - each data-row cell must be
# exactly one of Observed/Derived/Volatile/Unknown.
awk '
function is_sep(s,   t) {
  t = s
  gsub(/[ \t|:-]/, "", t)
  return (t == "" && s ~ /-/)
}
{ lines[NR] = $0 }
END {
  for (i = 2; i <= NR; i++) {
    if (lines[i] ~ /^\|/ && is_sep(lines[i]) && lines[i-1] ~ /^\|/) {
      header = lines[i-1]
      n = split(header, cells, "|")
      class_col = -1
      for (c = 1; c <= n; c++) {
        cell = cells[c]
        gsub(/^[ \t]+|[ \t]+$/, "", cell)
        gsub(/\*/, "", cell)
        if (cell == "Class") class_col = c
      }
      if (class_col == -1) continue
      j = i + 1
      while (j <= NR && lines[j] ~ /^\|/) {
        n2 = split(lines[j], cells2, "|")
        if (class_col <= n2) {
          val = cells2[class_col]
          gsub(/^[ \t]+|[ \t]+$/, "", val)
          gsub(/\*/, "", val)
          if (val != "Observed" && val != "Derived" && val != "Volatile" && val != "Unknown") {
            print j ":" val
          }
        }
        j++
      }
    }
  }
}
' "$FILE" > "$TMPDIR_CHECK/c4_table.txt"

# 4b: bold, table-cell, or em-dash-prefixed class-like synonyms anywhere in the file.
grep -noE '(\*\*(Believed|Stale|Assumed|Inferred|Confirmed|Reported|Likely|Estimated)\*\*|\|[[:space:]]*(Believed|Stale|Assumed|Inferred|Confirmed|Reported|Likely|Estimated)[[:space:]]*\||—[[:space:]]+(Believed|Stale|Assumed|Inferred|Confirmed|Reported|Likely|Estimated))' "$FILE" \
  > "$TMPDIR_CHECK/c4_syn.txt" 2>/dev/null

if [ -s "$TMPDIR_CHECK/c4_table.txt" ]; then
  while IFS=: read -r ln val; do
    emit "$SEV_C4" C4 "line $ln: invalid evidence class '$val'"
  done < "$TMPDIR_CHECK/c4_table.txt"
fi
if [ -s "$TMPDIR_CHECK/c4_syn.txt" ]; then
  while IFS=: read -r ln rest; do
    word=$(echo "$rest" | grep -oE 'Believed|Stale|Assumed|Inferred|Confirmed|Reported|Likely|Estimated' | head -1)
    emit "$SEV_C4" C4 "line $ln: disallowed class-like label '$word'"
  done < "$TMPDIR_CHECK/c4_syn.txt"
fi
if [ ! -s "$TMPDIR_CHECK/c4_table.txt" ] && [ ! -s "$TMPDIR_CHECK/c4_syn.txt" ]; then
  emit PASS C4 "no invalid evidence-class values found"
fi

# --- C5: cited paths resolve ---
# Only inside sections whose heading contains one of the load-bearing section names.
awk '
BEGIN {
  nk = split("Working state|Live Truth|Current Status|Read before acting|Read first|Required Reading|Truth Ledger|Continuation Mission|Start", keys, "|")
}
{ lines[NR] = $0 }
END {
  in_sec = 0; sec_level = 0
  for (i = 1; i <= NR; i++) {
    line = lines[i]
    if (line ~ /^#+[ \t]/) {
      level = 0
      while (substr(line, level + 1, 1) == "#") level++
      if (in_sec && level <= sec_level) in_sec = 0
      is_match = 0
      for (k = 1; k <= nk; k++) {
        if (index(line, keys[k]) > 0) { is_match = 1; break }
      }
      if (is_match) { in_sec = 1; sec_level = level }
      continue
    }
    if (in_sec) {
      s = line
      while (match(s, /`[^`]+`/)) {
        tok = substr(s, RSTART + 1, RLENGTH - 2)
        print i "\t" tok
        s = substr(s, RSTART + RLENGTH)
      }
    }
  }
}
' "$FILE" > "$TMPDIR_CHECK/c5_raw.txt"

# Extensions a real cited file plausibly ends in. A bare (no "/") token whose trailing
# ".word" is NOT in this list is almost always a version number (1.17.0, v1.1.0), a
# Beads-style issue id (hcudz.4), or a code/API expression (ref.watch, .autoDispose) —
# not a path — so it is excluded rather than reported as an unresolved citation.
C5_EXTS=" md rb ts tsx js jsx mjs cjs dart swift py yaml yml json jsonl plist pbxproj lock sh bash zsh txt info xml gradle podspec toml ini cfg conf env gemspec sql graphql proto kt kts java go rs c h hh cpp hpp cc css scss html htm csv tsv log pem key crt pub gitignore entitlements xcconfig storyboard xib strings mod sum lockb git gitmodules gitattributes npmrc editorconfig eslintrc prettierrc babelrc nvmrc dockerignore npmignore flowconfig browserslistrc huskyrc stylelintrc yarnrc beads "

: > "$TMPDIR_CHECK/c5_candidates.txt"
while IFS=$'\t' read -r ln tok; do
  [ -z "$tok" ] && continue
  case "$tok" in
    *" "*) continue ;;
  esac
  case "$tok" in
    *"<"*|*">"*|*"*"*|*'$'*) continue ;;
  esac
  case "$tok" in
    *"://"*) continue ;;
  esac
  case "$tok" in
    -*) continue ;;
  esac
  # a scheme-less domain prefix (github.com/org/repo) reads as a URL missing its
  # protocol, not a citation; an @-scoped spec or a glob pattern is never a real path.
  case "$tok" in
    "@"*|*"*"*) continue ;;
  esac
  if [[ "$tok" =~ ^[a-z0-9.-]+\.(com|org|io|dev|net)/ ]]; then
    continue
  fi
  # package@version specs (google-gax@5.0.6, @google-cloud/tasks@6.2.3) never appear as
  # real repo paths in this corpus; a literal "@" is a clean, generic tell.
  case "$tok" in
    *"@"*) continue ;;
  esac
  # diff ranges (main...origin/main) and truncated placeholders (…/builds/331).
  case "$tok" in
    *".."*|*"…"*) continue ;;
  esac
  # git remote-tracking refs (origin/main, origin/main:.beads/issues.jsonl,
  # origin/codex/some-branch) are never real repo-relative paths.
  case "$tok" in
    "origin/"*) continue ;;
    /v[0-9]*/*|/api/*) continue ;;   # URL routes such as /v1/report or /api/users are not filesystem paths
  esac
  # commit-hash-prefixed git-show refs (11e9833:Sources/App/Foo.swift): the
  # part after the colon may be a real path, but the checker can't test-e a git-show
  # ref, so don't misreport it as an unresolved filesystem path.
  if [[ "$tok" =~ ^[0-9a-f]{7,40}: ]]; then
    continue
  fi
  # standard branch-name prefixes (feature/, chore/, fix/, codex/, ...) with no
  # trailing file extension are branch names, not paths. Guarded by the extension
  # check so a real "codex/notes.md"-shaped path, if one ever exists, still resolves.
  first_seg="${tok%%/*}"
  case "$first_seg" in
    feature|chore|fix|bugfix|hotfix|release|codex)
      if ! [[ "$tok" =~ \.[A-Za-z0-9]+(:[0-9][0-9,.-]*)?$ ]]; then
        continue
      fi
      ;;
  esac
  # ahead/behind and LCOV found/hit counters (0/0, LF/LH, BRF/BRH) are ratios, not paths.
  if [[ "$tok" =~ ^[0-9]+/[0-9]+$ ]] || [[ "$tok" =~ ^[A-Z][A-Z0-9]*/[A-Z][A-Z0-9]*$ ]]; then
    continue
  fi

  looks_like_path=0
  case "$tok" in
    */*) looks_like_path=1 ;;
  esac
  if [ "$looks_like_path" = "0" ] && [[ "$tok" =~ \.[A-Za-z0-9]+$ ]]; then
    ext=$(echo "$tok" | sed -E 's/.*\.([A-Za-z0-9]+)$/\1/' | tr '[:upper:]' '[:lower:]')
    case "$C5_EXTS" in
      *" $ext "*) looks_like_path=1 ;;
    esac
  fi
  [ "$looks_like_path" = "0" ] && continue

  # Strip a trailing line-anchor: a single line (:700), a range (:63-68), an
  # open-ended range (:143-), or a comma-joined list (:22,94,118-138,153-158,174-204).
  stripped=$(echo "$tok" | sed -E 's/:[0-9][0-9,.-]*$//')

  case "$stripped" in
    *docs/handoffs/*) continue ;;
  esac

  case "$stripped" in
    "~"*) expanded="$HOME${stripped#\~}" ;;
    *) expanded="$stripped" ;;
  esac

  case "$expanded" in
    /*) target="$expanded" ;;
    *) target="$ROOT/$expanded" ;;
  esac

  printf '%s\t%s\t%s\n' "$ln" "$tok" "$target" >> "$TMPDIR_CHECK/c5_candidates.txt"
done < "$TMPDIR_CHECK/c5_raw.txt"

# Dedupe by resolved target: the same real path cited at several lines (or in both
# relative and absolute form) is counted/reported once.
awk -F'\t' '!seen[$3]++' "$TMPDIR_CHECK/c5_candidates.txt" > "$TMPDIR_CHECK/c5_dedup.txt"

resolved_count=0
: > "$TMPDIR_CHECK/c5_unresolved.txt"
while IFS=$'\t' read -r ln tok target; do
  if [ -e "$target" ]; then
    resolved_count=$((resolved_count + 1))
  else
    printf '%s\t%s\n' "$ln" "$tok" >> "$TMPDIR_CHECK/c5_unresolved.txt"
  fi
done < "$TMPDIR_CHECK/c5_dedup.txt"

emit PASS C5 "$resolved_count path(s) resolved (root: $ROOT)"
if [ -s "$TMPDIR_CHECK/c5_unresolved.txt" ]; then
  while IFS=$'\t' read -r ln tok; do
    # A bare filename (no "/") is often a citation-shorthand or a doc that
    # legitimately doesn't exist in this repo (AGENTS.md, CLAUDE.md); it's a
    # softer signal than an unresolved multi-segment path, so it warns
    # instead of failing, in both --baseline and default profiles.
    case "$tok" in
      */*) emit FAIL C5 "line $ln: unresolved path '$tok'" ;;
      *) emit WARN C5 "line $ln: unresolved bare filename '$tok'" ;;
    esac
  done < "$TMPDIR_CHECK/c5_unresolved.txt"
fi

# --- C6: closing sentence ---
last_line=$(awk 'NF{last=$0} END{print last}' "$FILE")
stripped_last=$(echo "$last_line" | sed -e 's/\*//g' -e 's/`//g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

if [[ "$stripped_last" =~ ^Read[[:space:]]+(.+\.md)[[:space:]]+and[[:space:]]+do[[:space:]]+(.+)\.$ ]]; then
  cited_path="${BASH_REMATCH[1]}"
  cited_base=$(basename "$cited_path")
  file_base=$(basename "$FILE")
  if [ "$cited_base" = "$file_base" ]; then
    emit PASS C6 "closing sentence present and names this file"
  else
    emit "$SEV_C6" C6 "closing sentence names '$cited_base', expected '$file_base'"
  fi
else
  emit "$SEV_C6" C6 "last non-empty line does not match 'Read <path>.md and do <mission>.'"
fi

# --- C7: depth ceiling ---
declared_depth=""
depth_line=$(grep -m1 -F "Document depth:" "$FILE")
if [ -n "$depth_line" ]; then
  after=$(echo "$depth_line" | sed -E 's/.*Document depth:[^A-Za-z]*//')
  word=$(echo "$after" | grep -oE '^[A-Za-z]+')
  word_upper=$(echo "$word" | tr '[:lower:]' '[:upper:]')
  case "$word_upper" in
    COMPACT|STANDARD|GOVERNED) declared_depth="$word_upper" ;;
  esac
fi
if [ -z "$declared_depth" ] && grep -qF "Launch Contract" "$FILE"; then
  declared_depth="COMPACT"
fi

if [ -z "$declared_depth" ]; then
  emit INFO C7 "no depth declaration found; cannot check ceiling"
else
  total_lines=$(wc -l < "$FILE" | tr -d ' ')
  case "$declared_depth" in
    COMPACT) ceiling=80 ;;
    STANDARD) ceiling=200 ;;
    GOVERNED) ceiling=320 ;;
  esac
  if [ "$total_lines" -gt "$ceiling" ]; then
    emit WARN C7 "depth $declared_depth exceeds ceiling: $total_lines lines > $ceiling"
  else
    emit PASS C7 "depth $declared_depth within ceiling ($total_lines <= $ceiling)"
  fi
fi

# --- C8: model identifiers need provenance context on the same line ---
grep -noE '(gpt-[0-9][A-Za-z0-9._-]*|claude-[a-z0-9-]*[0-9][A-Za-z0-9._-]*|gemini-[0-9][A-Za-z0-9._-]*|o[1-9]-[A-Za-z0-9._-]*)' "$FILE" \
  > "$TMPDIR_CHECK/c8_raw.txt" 2>/dev/null

found_any=0
violation=0
if [ -s "$TMPDIR_CHECK/c8_raw.txt" ]; then
  while IFS=: read -r ln tok; do
    found_any=1
    line_text=$(sed -n "${ln}p" "$FILE")
    # Skip tokens embedded in a longer slug or path (for example a run id like
    # p1-claude-sonnet-s1 or /runs/claude-sonnet-5/...): only a standalone token
    # is a model identifier worth checking.
    if ! echo "$line_text" | grep -qE "(^|[^A-Za-z0-9/_-])$tok([^A-Za-z0-9/_-]|\$)"; then
      continue
    fi
    if echo "$line_text" | grep -qiE 'volatile|observed|models_cache|catalog|source'; then
      :
    else
      emit "$SEV_C8" C8 "line $ln: model identifier '$tok' has no provenance context (Volatile/Observed/models_cache/catalog/source) on its line"
      violation=1
    fi
  done < "$TMPDIR_CHECK/c8_raw.txt"
fi
if [ "$found_any" = "0" ]; then
  emit PASS C8 "no model identifiers found"
elif [ "$violation" = "0" ]; then
  emit PASS C8 "model identifiers found, all have provenance context"
fi

# --- C9: secrets (never print the matched value, only line and pattern name) ---
c9_defs="$TMPDIR_CHECK/c9_defs.txt"
{
  printf 'sk-prefix\tsk-[A-Za-z0-9]{20,}\n'
  printf 'aws-access-key-id\tAKIA[0-9A-Z]{16}\n'
  printf 'github-pat\tghp_[A-Za-z0-9]{20,}\n'
  printf 'slack-token\txox[baprs]-\n'
  printf 'pem-block\t-----BEGIN\n'
  printf 'password-assignment\t[Pp]assword[[:space:]]*[:=][[:space:]]*[^[:space:]]+\n'
  printf 'token-assignment\t[Tt]oken[[:space:]]*[:=][[:space:]]*[A-Za-z0-9_-]{16,}\n'
} > "$c9_defs"

any_secret=0
while IFS=$'\t' read -r pname ppattern; do
  [ -z "$pname" ] && continue
  lines_found=$(grep -nE -- "$ppattern" "$FILE" | cut -d: -f1)
  if [ -n "$lines_found" ]; then
    any_secret=1
    for ln in $lines_found; do
      emit WARN C9 "line $ln: possible secret pattern '$pname'"
    done
  fi
done < "$c9_defs"
if [ "$any_secret" = "0" ]; then
  emit PASS C9 "no secret-like patterns found"
fi

print_summary
if [ "$FAIL" -eq 0 ]; then
  exit 0
else
  exit 1
fi
