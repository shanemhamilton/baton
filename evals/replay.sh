#!/bin/bash
# Replay evals/check.sh --baseline across a deduplicated handoff corpus and print an
# aggregate pass/fail/warn table per check id. bash 3.2 compatible.
#
# Usage: replay.sh [--since YYYY-MM-DD] [--format PREFIX] [--outdir DIR] <corpus-unique.tsv>
#
# <corpus-unique.tsv> is the file evals/dedupe-corpus.sh writes: a header row then
# tab-separated columns hash, date, stamp, lines, format, declared_depth, repo_root, path.
#
# --since keeps rows whose date is >= YYYY-MM-DD (lexicographic, so the date column
# must be YYYY-MM-DD). --format keeps rows whose format column starts with PREFIX
# (e.g. "baton" matches both baton-standard and baton-compact).
#
# Writes each document's full check.sh output to <outdir>/replay/<stamp>.txt and
# prints, per check id, how many documents had at least one FAIL and at least one WARN.

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
CHECK="$SCRIPT_DIR/check.sh"

SINCE=""
FORMAT=""
OUTDIR=""
TSV=""

while [ $# -gt 0 ]; do
  case "$1" in
    --since)
      [ $# -lt 2 ] && { echo "--since needs a value" >&2; exit 2; }
      SINCE="$2"; shift 2 ;;
    --format)
      [ $# -lt 2 ] && { echo "--format needs a value" >&2; exit 2; }
      FORMAT="$2"; shift 2 ;;
    --outdir)
      [ $# -lt 2 ] && { echo "--outdir needs a value" >&2; exit 2; }
      OUTDIR="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $0 [--since YYYY-MM-DD] [--format PREFIX] [--outdir DIR] <corpus-unique.tsv>"
      exit 0 ;;
    *)
      TSV="$1"; shift ;;
  esac
done

if [ -z "$TSV" ] || [ ! -f "$TSV" ]; then
  echo "Usage: $0 [--since YYYY-MM-DD] [--format PREFIX] [--outdir DIR] <corpus-unique.tsv>" >&2
  exit 2
fi

if [ -z "$OUTDIR" ]; then
  REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
  OUTDIR="$REPO_ROOT/.tmp/evals"
fi
mkdir -p "$OUTDIR/replay"

# Indexed arrays (bash 3.2 has these, just not associative ones): slot n holds the
# count for check id "Cn". Index 0 is unused.
fail_docs=(0 0 0 0 0 0 0 0 0 0)
warn_docs=(0 0 0 0 0 0 0 0 0 0)
doc_count=0
skipped=0

while IFS=$'\t' read -r hash date stamp lines fmt depth repo_root path; do
  [ -z "$hash" ] && continue
  [ "$hash" = "hash" ] && continue

  if [ -n "$SINCE" ] && [[ "$date" < "$SINCE" ]]; then
    continue
  fi
  if [ -n "$FORMAT" ]; then
    case "$fmt" in
      "$FORMAT"*) ;;
      *) continue ;;
    esac
  fi
  if [ ! -f "$path" ]; then
    skipped=$((skipped + 1))
    continue
  fi

  outfile="$OUTDIR/replay/${stamp}.txt"
  "$CHECK" --baseline --root "$repo_root" "$path" > "$outfile" 2>&1
  doc_count=$((doc_count + 1))

  fail_ids=$(grep -oE '^FAIL C[0-9]+' "$outfile" | sed 's/^FAIL C//' | sort -un)
  warn_ids=$(grep -oE '^WARN C[0-9]+' "$outfile" | sed 's/^WARN C//' | sort -un)

  for n in $fail_ids; do
    fail_docs[$n]=$(( ${fail_docs[$n]} + 1 ))
  done
  for n in $warn_ids; do
    warn_docs[$n]=$(( ${warn_docs[$n]} + 1 ))
  done
done < "$TSV"

echo "documents replayed: $doc_count (skipped, path missing: $skipped)"
echo
printf '%-4s %-9s %-9s\n' "id" "fail_docs" "warn_docs"
for n in 1 2 3 4 5 6 7 8 9; do
  printf '%-4s %-9s %-9s\n' "C$n" "${fail_docs[$n]}" "${warn_docs[$n]}"
done
echo
echo "per-document output: $OUTDIR/replay/<stamp>.txt"
