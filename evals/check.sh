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
# evals/README.md for what each check id (C1-C10) means.

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
  SEV_CONTENT=WARN
  SEV_C4=WARN
  SEV_C6=INFO
  SEV_C8=WARN
else
  SEV_CONTENT=FAIL
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

if [ ! -d "$ROOT" ]; then
  emit FAIL C1 "repository root does not exist"
  print_summary
  exit 1
fi

# An evaluator must never validate an arbitrary packet merely because its contents
# look plausible. Resolve both ends without following a final-file symlink, then
# require the record to live in the selected checkout. A linked worktree is valid:
# its own top-level is the root; only a record outside that top-level is rejected.
if [ -L "$FILE" ]; then
  emit FAIL C1 "continuation record must not be a symlink"
fi
ROOT_PHYSICAL=$(cd -P "$ROOT" 2>/dev/null && pwd)
FILE_PARENT_PHYSICAL=$(cd -P "$(dirname "$FILE")" 2>/dev/null && pwd)
FILE_PHYSICAL="${FILE_PARENT_PHYSICAL}/$(basename "$FILE")"
if [ -z "$ROOT_PHYSICAL" ] || [ -z "$FILE_PARENT_PHYSICAL" ]; then
  emit FAIL C1 "could not canonicalize repository root or continuation record"
else
  case "$FILE_PHYSICAL" in
    "$ROOT_PHYSICAL"/*) ;;
    *) emit FAIL C1 "continuation record is outside the selected repository root" ;;
  esac
  ROOT="$ROOT_PHYSICAL"
  FILE="$FILE_PHYSICAL"
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

# --- C3: meaningful launch fields and continuation (not just matching labels) ---
# Markdown is deliberately constrained to the skill template, not a general parser.
field_value() {
  awk -v key="$1" '
    {s=$0; gsub(/[*`]/,"",s); sub(/^[ \t>-]* /,"",s); sub(/^[ \t-]+/,"",s)}
    index(s,key ":")==1 {sub(/^[^:]+:[ \t]*/,"",s); sub(/[ \t]+$/,"",s); print s; exit}
  ' "$FILE"
}
meaningful() {
  printf '%s\n' "$1" | awk '
    {s=$0; gsub(/[*`]/,"",s); sub(/^[ \t>-]+/,"",s); sub(/^\[[ xX]\][ \t]*/,"",s); sub(/[ \t]+$/,"",s)}
    s!="" && s!~/^<[^>]*>$/ && s!~/^(TBD|TODO|N\/A|[.][.][.])$/ {ok=1}
    END {exit !ok}
  '
}
section_body() {
  awk -v wanted="$1" '
    /^#+[ \t]/ {
      level=match($0,/[^#]/)-1
      if (inside && level<=start) inside=0
      if ($0~wanted) {inside=1;start=level}
      next
    }
    inside && $0!~/^[ \t]*(---|```|[|])/ {print}
  ' "$FILE"
}
field_line() {
  awk -v key="$1" '
    {s=$0; gsub(/\*/,"",s); sub(/^[ \t>-]* /,"",s); sub(/^[ \t-]+/,"",s)}
    index(s,key ":")==1 {print $0; exit}
  ' "$FILE"
}
depth_value=$(field_value 'Document depth')
case "$depth_value" in
  COMPACT|STANDARD|GOVERNED) emit PASS C3 "valid Document depth" ;;
  *)
    if [ "$BASELINE" = "1" ] && grep -qF 'Launch Contract' "$FILE"; then
      emit WARN C3 "missing or invalid Document depth"
    else
      emit FAIL C3 "missing or invalid Document depth"
    fi ;;
esac
if meaningful "$(field_value 'Human decision state')"; then
  emit PASS C3 "populated Human decision state"
else
  emit FAIL C3 "missing or empty Human decision state"
fi
# The objective may be in a compact launch field or the normal Outcome section.
if meaningful "$(field_value 'Objective')" || meaningful "$(section_body 'Outcome and Done')"; then
  emit PASS C3 "populated objective"
else
  emit "$SEV_CONTENT" C3 "missing or empty objective (Objective field or Outcome and Done section)"
fi
for field in 'Start by' 'Keep going until'; do
  if [ "$field" = 'Start by' ]; then
    value=$(field_value "$field")
  else
    body=$(section_body 'Continuation Mission')
    value=$(printf '%s\n' "$body" | sed 's/[*`]//g' | sed -n "s/^[[:space:]-]*$field:[[:space:]]*//p")
  fi
  if meaningful "$value"; then
    emit PASS C3 "populated Continuation Mission $field"
  else
    emit "$SEV_CONTENT" C3 "missing or empty Continuation Mission $field"
  fi
done

# --- C10: continuation-record and checkout safety ---
# C10 is intentionally separate from document-shape checks: a well-written packet
# must still fail if it names another checkout, asserts stale Git state, or proposes
# cleanup without the evidence needed to recover it.
is_git=0
git_toplevel=$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null)
if [ -n "$git_toplevel" ]; then
  git_toplevel_physical=$(cd -P "$git_toplevel" 2>/dev/null && pwd)
  if [ "$git_toplevel_physical" = "$ROOT" ]; then
    is_git=1
  else
    emit FAIL C10 "--root must be the Git worktree top-level"
  fi
fi

resolve_record_path() {
  value="$1"
  value=$(printf '%s' "$value" | sed -E 's/^[[:space:]]+|[[:space:]]+$//')
  case "$value" in
    "~"*) value="$HOME${value#\~}" ;;
  esac
  case "$value" in
    /*) candidate="$value" ;;
    *) candidate="$ROOT/$value" ;;
  esac
  candidate_parent=$(cd -P "$(dirname "$candidate")" 2>/dev/null && pwd)
  [ -n "$candidate_parent" ] || return 1
  printf '%s/%s\n' "$candidate_parent" "$(basename "$candidate")"
}

record_value=$(field_value 'Continuation record')
record_policy=$(field_value 'Continuation policy')
if [ "$is_git" = "1" ] || meaningful "$record_value" || meaningful "$record_policy"; then
  if ! meaningful "$record_value"; then
    emit FAIL C10 "missing or empty Continuation record"
  else
    record_target=$(resolve_record_path "$record_value")
    if [ -z "$record_target" ] || [ ! -f "$record_target" ] || [ -L "$record_target" ]; then
      emit FAIL C10 "Continuation record must resolve to an in-root regular file"
    elif [ "$record_target" -ef "$FILE" ]; then
      emit PASS C10 "Continuation record resolves to this file"
    else
      emit FAIL C10 "Continuation record resolves to a different file"
    fi
  fi
  if ! meaningful "$record_policy"; then
    emit FAIL C10 "missing or empty Continuation policy"
  elif ! field_line 'Continuation policy' | grep -q '`[^`][^`]*`'; then
    emit FAIL C10 "Continuation policy must cite the applicable repository rule"
  else
    emit PASS C10 "Continuation policy has a cited repository rule"
  fi
  for required in 'Task identity' 'Continuation lineage' 'Revalidation triggers'; do
    if meaningful "$(field_value "$required")"; then
      emit PASS C10 "$required is populated"
    else
      emit FAIL C10 "missing or empty $required"
    fi
  done
  continuation_lifecycle=$(field_value 'Continuation lifecycle' | tr '[:lower:]' '[:upper:]')
  case "$continuation_lifecycle" in
    ACTIVE|SUPERSEDED|CLOSED) emit PASS C10 "Continuation lifecycle is valid" ;;
    *) emit FAIL C10 "Continuation lifecycle must be ACTIVE, SUPERSEDED, or CLOSED" ;;
  esac
  receiver_start=$(field_value 'Receiver start')
  record_last=$(awk 'NF{last=$0}END{print last}' "$FILE" | sed 's/[*`]//g;s/^[[:space:]]*//;s/[[:space:]]*$//')
  if ! meaningful "$receiver_start"; then
    emit FAIL C10 "missing or empty Receiver start"
  elif [ "$receiver_start" = "$record_last" ]; then
    emit PASS C10 "Receiver start matches the final continuation line"
  else
    emit FAIL C10 "Receiver start must match the final continuation line"
  fi
fi

if [ "$is_git" = "1" ]; then
  git_common_raw=$(git -C "$ROOT" rev-parse --git-common-dir 2>/dev/null)
  case "$git_common_raw" in
    /*) git_common_candidate="$git_common_raw" ;;
    *) git_common_candidate="$ROOT/$git_common_raw" ;;
  esac
  git_common=$(cd -P "$git_common_candidate" 2>/dev/null && pwd)
  git_head=$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || printf 'UNBORN')
  git_branch=$(git -C "$ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null || printf 'DETACHED')
  git_identity=$(git -C "$ROOT" remote get-url origin 2>/dev/null)
  [ -n "$git_identity" ] || git_identity="$git_common"
  git_upstream=$(git -C "$ROOT" status --short --branch --untracked-files=all 2>/dev/null | sed -n '1p')
  status_digest() {
    if command -v shasum >/dev/null 2>&1; then
      git -C "$ROOT" status --porcelain=v2 --untracked-files=all 2>/dev/null | shasum -a 256 | awk '{print $1}'
    else
      git -C "$ROOT" status --porcelain=v2 --untracked-files=all 2>/dev/null | sha256sum | awk '{print $1}'
    fi
  }
  git_dirty_digest=$(status_digest)

  check_exact_field() {
    label="$1"; expected="$2"
    actual=$(field_value "$label")
    canonical_value() {
      if [ -d "$1" ]; then
        cd -P "$1" 2>/dev/null && pwd
      else
        printf '%s\n' "$1"
      fi
    }
    actual_canonical=$(canonical_value "$actual")
    expected_canonical=$(canonical_value "$expected")
    if [ "$actual_canonical" = "$expected_canonical" ]; then
      emit PASS C10 "$label matches this checkout"
    elif ! meaningful "$actual"; then
      emit FAIL C10 "missing or empty $label"
    else
      emit FAIL C10 "$label does not match this checkout"
    fi
  }
  check_exact_field 'Repository identity' "$git_identity"
  check_exact_field 'Repository root' "$ROOT"
  check_exact_field 'Execution worktree' "$ROOT"
  check_exact_field 'Git common directory' "$git_common"
  check_exact_field 'Author HEAD' "$git_head"
  check_exact_field 'Author branch' "$git_branch"
  recorded_upstream=$(field_value 'Upstream state')
  if [ "$recorded_upstream" = "$git_upstream" ] \
      || { [ "$(printf '%s' "$recorded_upstream" | tr '[:upper:]' '[:lower:]')" = "none" ] \
           && ! printf '%s\n' "$git_upstream" | grep -q '\.\.\.'; }; then
    emit PASS C10 "Upstream state matches this checkout"
  elif ! meaningful "$recorded_upstream"; then
    emit FAIL C10 "missing or empty Upstream state"
  else
    emit FAIL C10 "Upstream state does not match this checkout"
  fi

  truth_ref=$(field_value 'Truth ref')
  if ! meaningful "$truth_ref"; then
    emit FAIL C10 "missing or empty Truth ref"
  elif printf '%s\n' "$truth_ref" | grep -qE '^Unknown[[:space:]]+[^[:space:]].*$'; then
    emit PASS C10 "Truth ref is explicitly unknown pending read-only reconciliation"
  elif printf '%s\n' "$truth_ref" | grep -qE '^([^[:space:]]+)[[:space:]]+@[[:space:]]+([0-9a-fA-F]{40})$'; then
    truth_name=$(printf '%s\n' "$truth_ref" | sed -E 's/^([^[:space:]]+)[[:space:]]+@[[:space:]]+([0-9a-fA-F]{40})$/\1/')
    truth_sha=$(printf '%s\n' "$truth_ref" | sed -E 's/^([^[:space:]]+)[[:space:]]+@[[:space:]]+([0-9a-fA-F]{40})$/\2/')
    resolved_truth_sha=$(git -C "$ROOT" rev-parse --verify --quiet "${truth_name}^{commit}" 2>/dev/null)
    if [ "$resolved_truth_sha" = "$truth_sha" ]; then
      emit PASS C10 "Truth ref and SHA resolve in this checkout"
    else
      emit FAIL C10 "Truth ref does not resolve to its recorded SHA"
    fi
  else
    emit FAIL C10 "Truth ref must be '<ref> @ <40-char SHA>' or 'Unknown <reason>'"
  fi

  dirty_digest=$(field_value 'Dirty-state digest' | sed -E 's/^sha256://')
  if [ "$dirty_digest" = "$git_dirty_digest" ]; then
    emit PASS C10 "Dirty-state digest matches this checkout"
  elif ! meaningful "$dirty_digest"; then
    emit FAIL C10 "missing or empty Dirty-state digest"
  else
    emit FAIL C10 "Dirty-state digest does not match this checkout"
  fi

  observed_at=$(field_value 'Checkout observed at')
  if printf '%s\n' "$observed_at" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2})?([.][0-9]+)?(Z|[+-][0-9]{2}:?[0-9]{2})?$'; then
    emit PASS C10 "Checkout observed at has an ISO-8601 timestamp"
  else
    emit FAIL C10 "Checkout observed at must be an ISO-8601 timestamp"
  fi
  refresh_command=$(field_value 'Checkout refresh command')
  if meaningful "$refresh_command" && printf '%s\n' "$refresh_command" | grep -q 'git '; then
    emit PASS C10 "Checkout refresh command names Git evidence"
  else
    emit FAIL C10 "Checkout refresh command must name a Git command"
  fi
  mismatch_disposition=$(field_value 'Checkout mismatch disposition')
  if printf '%s\n' "$mismatch_disposition" | grep -qi 'read[- ]only' && printf '%s\n' "$mismatch_disposition" | grep -qi 'reconcil'; then
    emit PASS C10 "Checkout mismatch disposition preserves read-only reconciliation"
  else
    emit FAIL C10 "Checkout mismatch disposition must require read-only reconciliation"
  fi

  cleanup_authority=$(field_value 'Cleanup authority')
  cleanup_normalized=$(printf '%s' "$cleanup_authority" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z]+/ /g;s/^ | $//g')
  if [ "$cleanup_normalized" = "no destructive cleanup authorized" ]; then
    cleanup_authorized=0
    emit PASS C10 "destructive cleanup is explicitly unauthorized"
  elif printf '%s\n' "$cleanup_authority" | grep -qi 'authorized' \
      && printf '%s\n' "$cleanup_authority" | grep -qi 'source:' \
      && printf '%s\n' "$cleanup_authority" | grep -qi 'scope:' \
      && printf '%s\n' "$cleanup_authority" | grep -qi 'conditions:'; then
    cleanup_authorized=1
    emit PASS C10 "cleanup authorization names source, scope, and conditions"
  else
    cleanup_authorized=0
    emit FAIL C10 "Cleanup authority must default to no destructive cleanup or name authorization source, scope, and conditions"
  fi

  # A transfer field is optional for an author staying in this checkout. Once a
  # different destination root is named, however, source-side existence proves
  # nothing: require the destination record and its receiver-side hash readback.
  transfer_source_root=$(field_value 'Transfer source root')
  transfer_destination_root=$(field_value 'Transfer destination root')
  handoff_source=$(field_value 'Handoff source')
  handoff_destination=$(field_value 'Handoff destination')
  transfer_availability=$(field_value 'Transfer availability')
  receiver_readback=$(field_value 'Receiver readback SHA-256' | sed -E 's/^sha256://')
  if meaningful "$transfer_source_root" || meaningful "$transfer_destination_root" \
      || meaningful "$handoff_source" || meaningful "$handoff_destination" \
      || meaningful "$transfer_availability" || meaningful "$receiver_readback"; then
    transfer_source_physical=$(cd -P "$transfer_source_root" 2>/dev/null && pwd)
    transfer_destination_physical=$(cd -P "$transfer_destination_root" 2>/dev/null && pwd)
    if [ "$transfer_source_physical" != "$ROOT" ]; then
      emit FAIL C10 "Transfer source root must be this author checkout"
    elif [ -z "$transfer_destination_physical" ]; then
      emit FAIL C10 "Transfer destination root must exist before it is declared"
    elif [ "$transfer_destination_physical" = "$ROOT" ]; then
      emit PASS C10 "transfer stays in the author checkout"
    else
      if ! meaningful "$handoff_source" || ! meaningful "$handoff_destination" \
          || ! meaningful "$transfer_availability" || ! meaningful "$receiver_readback"; then
        emit FAIL C10 "cross-checkout transfer requires source, destination, availability, and receiver readback hash"
      elif [[ "$handoff_source" != /* ]] || [[ "$handoff_destination" != /* ]]; then
        emit FAIL C10 "cross-checkout Handoff source and Handoff destination must be absolute paths"
      else
        source_record=$(resolve_record_path "$handoff_source")
        destination_candidate="$handoff_destination"
        destination_parent=$(cd -P "$(dirname "$destination_candidate")" 2>/dev/null && pwd)
        destination_record="${destination_parent}/$(basename "$destination_candidate")"
        # The receipt lives inside the continuation record it authenticates.
        # Hash a canonical form that replaces only that receipt value; otherwise
        # recording a final-file hash would be self-referential and impossible.
        continuation_content_hash() {
          sed -E 's/^([[:space:]>-]*\*{0,2}Receiver readback SHA-256:\*{0,2}[[:space:]]*).*/\1<attested-content-hash>/' "$1" \
            | if command -v shasum >/dev/null 2>&1; then
                shasum -a 256
              else
                sha256sum
              fi | awk '{print $1}'
        }
        expected_hash=$(continuation_content_hash "$FILE")
        if [ -z "$source_record" ] || [ ! "$source_record" -ef "$FILE" ]; then
          emit FAIL C10 "Handoff source must resolve to this continuation record"
        fi
        case "$destination_record" in
          "$transfer_destination_physical"/*) destination_in_root=1 ;;
          *) destination_in_root=0 ;;
        esac
        if [ "$destination_in_root" != "1" ]; then
          emit FAIL C10 "Handoff destination must be inside Transfer destination root"
        elif [ -z "$destination_record" ] || [ ! -f "$destination_record" ] || [ -L "$destination_record" ]; then
          emit FAIL C10 "Handoff destination must be a receiver-accessible regular file"
        elif [ "$receiver_readback" != "$expected_hash" ] \
            || ! printf '%s\n' "$transfer_availability" | grep -qi 'verified'; then
          emit FAIL C10 "cross-checkout transfer lacks verified matching receiver readback"
        else
          actual_destination_hash=$(continuation_content_hash "$destination_record")
          if [ "$actual_destination_hash" = "$expected_hash" ] && cmp -s "$FILE" "$destination_record"; then
            emit PASS C10 "receiver copy and readback hash match the author record"
          else
            emit FAIL C10 "receiver copy does not exactly match the author continuation record"
          fi
        fi
      fi
    fi
  fi

  table_text() {
    awk -v wanted="$1" '
      /^#+[ \t]/ {
        level=match($0,/[^#]/)-1
        if (inside && level<=start) inside=0
        if ($0 ~ wanted) {inside=1;start=level}
        next
      }
      inside && /^\|/ {print}
    ' "$FILE"
  }
  table_header() { printf '%s\n' "$1" | sed -n '/^|/ {p;q;}'; }
  table_rows() {
    printf '%s\n' "$1" | awk '
      /^\|/ {
        line=$0; gsub(/[|[:space:]:-]/,"",line)
        if (line != "") {
          if (!header_seen) {header_seen=1; next}
          print
        }
      }
    '
  }
  table_has_header() {
    header=$(table_header "$1")
    wanted=$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')
    printf '%s\n' "$header" | tr '[:upper:]' '[:lower:]' | sed -E 's/[`*]//g;s/[[:space:]]+/ /g' \
      | grep -Fq "| $wanted |"
  }
  table_cell() {
    header="$1"; row="$2"; wanted="$3"
    printf '%s\n%s\n' "$header" "$row" | awk -F'|' -v wanted="$wanted" '
      function clean(s){gsub(/^[ \t]+|[ \t]+$/, "", s);gsub(/[`*]/,"",s);return tolower(s)}
      NR==1 {for(i=1;i<=NF;i++)if(clean($i)==tolower(wanted))column=i;next}
      NR==2 && column {value=$column;gsub(/^[ \t]+|[ \t]+$/, "", value);gsub(/[`*]/,"",value);print value}
    '
  }
  retain_disposition() { printf '%s\n' "$1" | grep -qiE '^[[:space:]]*(retain|preserve)[[:space:]]*$'; }
  usable_recovery() {
    value=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
    [ -n "$value" ] && [ "$value" != "none" ] && [ "$value" != "unknown" ] && [ "$value" != "n/a" ]
  }
  unique_commits_are_zero() {
    value=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
    [ "$value" = "0" ] || [ "$value" = "none" ] || [ "$value" = "no" ]
  }
  validate_ledger_headers() {
    ledger_name="$1"; ledger="$2"; shift 2
    header=$(table_header "$ledger")
    if [ -z "$header" ]; then
      emit FAIL C10 "$ledger_name is missing its table"
      return 1
    fi
    if [ -z "$(table_rows "$ledger")" ]; then
      emit FAIL C10 "$ledger_name must contain at least one target row"
    fi
    for required in "$@"; do
      if ! table_has_header "$ledger" "$required"; then
        emit FAIL C10 "$ledger_name is missing required column '$required'"
      fi
    done
  }
  validate_worktree_rows() {
    ledger="$1"; action="$2"; header=$(table_header "$ledger")
    rows=$(table_rows "$ledger")
    while IFS= read -r row; do
      [ -n "$row" ] || continue
      for required in 'Target path' 'Action' 'Source path' 'Destination path' 'Repository' 'HEAD' 'Branch' 'Registry state' 'Dirty state' \
          'Untracked paths' 'Stash dependency' 'Unique commits' 'Integration evidence' \
          'Active process or lease' 'Owner/task' 'Recovery ref' 'Pre-action inventory' \
          'Post-action verification' 'Disposition' 'Retirement command' 'Action owner'; do
        value=$(table_cell "$header" "$row" "$required")
        meaningful "$value" || emit FAIL C10 "Worktree ledger row has an empty '$required'"
      done
      disposition=$(table_cell "$header" "$row" 'Disposition')
      row_action=$(table_cell "$header" "$row" 'Action')
      row_action_upper=$(printf '%s' "$row_action" | tr '[:lower:]' '[:upper:]' | sed -E 's/[[:space:]]+//g')
      case "$row_action_upper" in
        MOVE|REMOVE|REPAIR|BRANCH-DELETE) ;;
        *) emit FAIL C10 "Worktree ledger Action must be MOVE, REMOVE, REPAIR, or BRANCH-DELETE" ;;
      esac
      case ",$action," in
        *,"$row_action_upper",*) ;;
        *) emit FAIL C10 "Worktree ledger Action is not declared by Worktree lifecycle action" ;;
      esac
      row_lower=$(printf '%s' "$row" | tr '[:upper:]' '[:lower:]')
      if printf '%s\n' "$row_lower" | grep -q 'unknown' && ! retain_disposition "$disposition"; then
        emit FAIL C10 "Worktree ledger Unknown state must retain the target"
      fi
      registry=$(table_cell "$header" "$row" 'Registry state')
      recovery=$(table_cell "$header" "$row" 'Recovery ref')
      inventory=$(table_cell "$header" "$row" 'Pre-action inventory')
      if printf '%s\n' "$registry" | grep -qiE 'prunable|missing source|mismatched git root'; then
        if ! retain_disposition "$disposition" || ! usable_recovery "$recovery" || ! usable_recovery "$inventory"; then
          emit FAIL C10 "prunable, missing-source, or mismatched-root worktrees require inventory, recovery, and RETAIN"
        fi
      fi
      branch=$(table_cell "$header" "$row" 'Branch')
      if printf '%s\n' "$branch" | grep -qi 'detached' && ! retain_disposition "$disposition" \
          && ! usable_recovery "$recovery"; then
        emit FAIL C10 "detached worktree retirement requires a recovery ref"
      fi
      command=$(table_cell "$header" "$row" 'Retirement command')
      if printf '%s\n' "$disposition" | grep -qiE 'remove|retire|delete'; then
        if printf '%s\n' "$command" | grep -qiE 'git[[:space:]]+worktree[[:space:]]+prune|git[[:space:]]+clean|rm[[:space:]]+-rf|git[[:space:]]+worktree[[:space:]]+remove.*(^|[[:space:]])(-f|--force)([[:space:]]|$)'; then
          emit FAIL C10 "Worktree ledger retirement command must not force cleanup"
        elif printf '%s\n' "$command" | grep -qiE 'git[[:space:]]+worktree[[:space:]]+remove'; then
          emit PASS C10 "Worktree ledger uses standard non-forced Git removal"
        elif ! printf '%s\n' "$command" | grep -qE '(/|\\.)'; then
          emit FAIL C10 "Worktree ledger retirement command must cite a repository-native command"
        fi
      fi
      if [ "$row_action_upper" = "MOVE" ] \
          && ! printf '%s\n' "$command" | grep -q 'git worktree move'; then
        emit FAIL C10 "worktree MOVE must use git worktree move"
      fi
    done <<EOF_WORKTREE_ROWS
$rows
EOF_WORKTREE_ROWS
  }
  validate_branch_rows() {
    ledger="$1"; action="$2"; header=$(table_header "$ledger")
    rows=$(table_rows "$ledger")
    while IFS= read -r row; do
      [ -n "$row" ] || continue
      for required in 'Branch' 'Tip SHA' 'Upstream state' 'Attached worktree' 'Owner/task' \
          'Integration evidence' 'Unique commits' 'Recovery ref' 'Disposition' 'Action owner'; do
        value=$(table_cell "$header" "$row" "$required")
        meaningful "$value" || emit FAIL C10 "Branch ledger row has an empty '$required'"
      done
      disposition=$(table_cell "$header" "$row" 'Disposition')
      row_lower=$(printf '%s' "$row" | tr '[:upper:]' '[:lower:]')
      if printf '%s\n' "$row_lower" | grep -q 'unknown' && ! retain_disposition "$disposition"; then
        emit FAIL C10 "Branch ledger Unknown state must retain the branch"
      fi
      upstream=$(table_cell "$header" "$row" 'Upstream state')
      unique=$(table_cell "$header" "$row" 'Unique commits')
      if printf '%s\n' "$upstream" | grep -qi 'gone' && ! unique_commits_are_zero "$unique" \
          && ! retain_disposition "$disposition"; then
        emit FAIL C10 "gone-upstream branch with unique commits must be retained"
      fi
      branch=$(table_cell "$header" "$row" 'Branch')
      recovery=$(table_cell "$header" "$row" 'Recovery ref')
      if printf '%s\n' "$branch" | grep -qi 'detached' && ! retain_disposition "$disposition" \
          && ! usable_recovery "$recovery"; then
        emit FAIL C10 "detached branch retirement requires a recovery ref"
      fi
      if ! printf '%s\n' "$action" | grep -q 'BRANCH-DELETE' \
          && printf '%s\n' "$disposition" | grep -qiE 'remove|retire|delete'; then
        emit FAIL C10 "worktree removal does not authorize branch deletion"
      fi
    done <<EOF_BRANCH_ROWS
$rows
EOF_BRANCH_ROWS
  }

  lifecycle_action=$(field_value 'Worktree lifecycle action')
  lifecycle_upper=$(printf '%s' "$lifecycle_action" | tr '[:lower:]' '[:upper:]' | sed -E 's/[[:space:]]+//g')
  if ! printf '%s\n' "$lifecycle_upper" | grep -qE '^(NONE|((MOVE|REMOVE|REPAIR|BRANCH-DELETE)(,(MOVE|REMOVE|REPAIR|BRANCH-DELETE))*))$'; then
    emit FAIL C10 "Worktree lifecycle action must contain only NONE, MOVE, REMOVE, REPAIR, or BRANCH-DELETE"
  else
  case "$lifecycle_upper" in
    NONE) emit PASS C10 "no worktree lifecycle action is proposed" ;;
    *MOVE*|*REMOVE*|*REPAIR*|*BRANCH-DELETE*)
      if [ "$cleanup_authorized" != "1" ]; then
        emit FAIL C10 "worktree lifecycle action requires explicit cleanup authority"
      fi
      worktree_ledger=$(table_text 'Worktree ledger')
      branch_ledger=$(table_text 'Branch ledger')
      validate_ledger_headers 'Worktree ledger' "$worktree_ledger" \
        'Target path' 'Action' 'Source path' 'Destination path' 'Repository' 'HEAD' 'Branch' 'Registry state' \
        'Dirty state' 'Untracked paths' 'Stash dependency' 'Unique commits' 'Integration evidence' \
        'Active process or lease' 'Owner/task' 'Recovery ref' 'Pre-action inventory' \
        'Post-action verification' 'Disposition' 'Retirement command' 'Action owner'
      validate_ledger_headers 'Branch ledger' "$branch_ledger" \
        'Branch' 'Tip SHA' 'Upstream state' 'Attached worktree' 'Owner/task' 'Integration evidence' \
        'Unique commits' 'Recovery ref' 'Disposition' 'Action owner'
      validate_worktree_rows "$worktree_ledger" "$lifecycle_upper"
      validate_branch_rows "$branch_ledger" "$lifecycle_upper"
      ;;
    *) emit FAIL C10 "Worktree lifecycle action must be NONE, MOVE, REMOVE, REPAIR, or BRANCH-DELETE" ;;
  esac
  fi
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
      class_col = -1; claim_col = -1; evidence_col = -1
      for (c = 1; c <= n; c++) {
        cell = cells[c]
        gsub(/^[ \t]+|[ \t]+$/, "", cell)
        gsub(/\*/, "", cell)
        if (cell == "Class") class_col = c
        if (cell == "Claim") claim_col = c
        if (cell == "Evidence") evidence_col = c
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
            print j ":invalid"
          }
          claim = cells2[claim_col]; evidence = cells2[evidence_col]
          gsub(/[ *`\t]/, "", claim); gsub(/[ *`\t]/, "", evidence)
          if (claim_col>0 && evidence_col>0) {
            if (claim=="" || evidence=="" || claim~/^<.*>$/ || evidence~/^<.*>$/ ||
                claim~/^(TODO|TBD)$/ || evidence~/^(TODO|TBD)$/) print j ":empty-truth"
            else if (val ~ /^(Observed|Derived|Volatile|Unknown)$/) truth=1
          }
        }
        j++
      }
    }
  }
  if (!truth) print "0:missing-truth"
}
' "$FILE" > "$TMPDIR_CHECK/c4_table.txt"

# 4b: bold, table-cell, or em-dash-prefixed class-like synonyms anywhere in the file.
grep -noE '(\*\*(Believed|Stale|Assumed|Inferred|Confirmed|Reported|Likely|Estimated)\*\*|\|[[:space:]]*(Believed|Stale|Assumed|Inferred|Confirmed|Reported|Likely|Estimated)[[:space:]]*\||—[[:space:]]+(Believed|Stale|Assumed|Inferred|Confirmed|Reported|Likely|Estimated))' "$FILE" \
  > "$TMPDIR_CHECK/c4_syn.txt" 2>/dev/null

if [ -s "$TMPDIR_CHECK/c4_table.txt" ]; then
  while IFS=: read -r ln val; do
    if [ "$val" = "missing-truth" ]; then
      emit "$SEV_CONTENT" C4 "no populated Claim/Class/Evidence row (Unknown with missing-evidence explanation is valid)"
    elif [ "$val" = "empty-truth" ]; then
      emit "$SEV_CONTENT" C4 "line $ln: empty claim or evidence"
    else
      emit "$SEV_C4" C4 "line $ln: invalid evidence class"
    fi
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
  nk = split("Launch Contract|Working state|Live Truth|Current Status|Read before acting|Read first|Required Reading|Truth Ledger|Continuation Mission|Start", keys, "|")
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

if [[ "$stripped_last" =~ ^Read[[:space:]]+(.+)[[:space:]]+and[[:space:]]+do[[:space:]]+(.+)\.$ ]]; then
  cited_path="${BASH_REMATCH[1]}"
  case "$cited_path" in
    "~"*) cited_path="$HOME${cited_path#\~}" ;;
  esac
  case "$cited_path" in
    /*) closing_target="$cited_path" ;;
    *) closing_target="$ROOT/$cited_path" ;;
  esac
  if [ "$closing_target" -ef "$FILE" ]; then
    emit PASS C6 "closing sentence resolves to this file"
  else
    emit "$SEV_C6" C6 "closing sentence resolves to a different or missing file"
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
