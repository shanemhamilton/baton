#!/bin/bash
# Deduplicate the real-world Baton handoff corpus by content hash and fingerprint
# each unique document's format/depth. See docs/plans/2026-09-01-baton-v2-rationalization-plan.md
# section 2 for why dedup-by-hash matters (worktrees copy every committed handoff).
#
# Usage: evals/dedupe-corpus.sh [outdir]
#   outdir defaults to /Users/shanehamilton/Projects/baton/.tmp/evals
set -euo pipefail

OUTDIR="${1:-/Users/shanehamilton/Projects/baton/.tmp/evals}"
mkdir -p "$OUTDIR"

# ponytail: only macOS (md5 -q) and Linux (md5sum) are handled; no other platform.
if command -v md5 >/dev/null 2>&1; then
  hash_file() { md5 -q "$1"; }
elif command -v md5sum >/dev/null 2>&1; then
  hash_file() { md5sum "$1" | awk '{print $1}'; }
else
  echo "no md5 or md5sum on PATH" >&2
  exit 1
fi

ALL_TSV="$OUTDIR/.all-hashes.tsv"
UNIQUE_TSV="$OUTDIR/corpus-unique.tsv"

: > "$ALL_TSV"
find "$HOME/Projects" -path '*/docs/handoffs/handoff-*.md' -not -path '*/node_modules/*' -type f 2>/dev/null \
  | sort \
  | while IFS= read -r path; do
      printf '%s\t%s\n' "$(hash_file "$path")" "$path" >> "$ALL_TSV"
    done

TOTAL_PATHS=$(wc -l < "$ALL_TSV" | tr -d ' ')

# Keep the first path per hash: sort by hash then path, then dedupe on column 1.
printf 'hash\tdate\tstamp\tlines\tformat\tdeclared_depth\trepo_root\tpath\n' > "$UNIQUE_TSV"

sort -k1,1 -k2,2 "$ALL_TSV" | awk -F'\t' '!seen[$1]++ {print}' \
  | while IFS=$'\t' read -r hash path; do
      base=$(basename "$path")
      stamp=$(printf '%s' "$base" | sed -E 's/^handoff-([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}).*$/\1/')
      date_part=$(printf '%s' "$stamp" | cut -c1-10)
      lines=$(wc -l < "$path" | tr -d ' ')

      if grep -q "Receiving Session Contract" "$path"; then
        format="baton-standard"
      elif grep -q "Launch Contract" "$path"; then
        format="baton-compact"
      elif grep -q "Receiving Session Config" "$path"; then
        format="metaswarm"
      else
        format="adhoc"
      fi

      depth_line=$(grep -m1 "Document depth:" "$path" || true)
      if [ -n "$depth_line" ]; then
        declared_depth=$(printf '%s' "$depth_line" | grep -oE 'COMPACT|STANDARD|GOVERNED' | head -1)
        [ -z "$declared_depth" ] && declared_depth="none"
      elif [ "$format" = "baton-compact" ]; then
        declared_depth="COMPACT"
      else
        declared_depth="none"
      fi

      repo_root=$(git -C "$(dirname "$path")" rev-parse --show-toplevel 2>/dev/null || echo "none")

      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$hash" "$date_part" "$stamp" "$lines" "$format" "$declared_depth" "$repo_root" "$path" \
        >> "$UNIQUE_TSV"
    done

rm -f "$ALL_TSV"

UNIQUE_COUNT=$(($(wc -l < "$UNIQUE_TSV" | tr -d ' ') - 1))

echo "== Corpus dedupe summary =="
echo "Paths on disk (pre-dedupe): $TOTAL_PATHS"
echo "Unique documents: $UNIQUE_COUNT"
echo ""
echo "-- Unique docs by month --"
tail -n +2 "$UNIQUE_TSV" | awk -F'\t' '{print substr($2,1,7)}' | sort | uniq -c | sort -k2,2

echo ""
echo "-- Unique docs by format --"
tail -n +2 "$UNIQUE_TSV" | awk -F'\t' '{print $5}' | sort | uniq -c | sort -rn

echo ""
BATON_SINCE=$(tail -n +2 "$UNIQUE_TSV" | awk -F'\t' '($5=="baton-standard" || $5=="baton-compact") && $2 >= "2026-07-18"' | wc -l | tr -d ' ')
echo "Baton-format docs dated 2026-07-18 or later: $BATON_SINCE"
echo ""
echo "Wrote $UNIQUE_TSV"
