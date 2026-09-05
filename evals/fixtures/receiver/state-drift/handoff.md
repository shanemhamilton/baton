# Customer report handoff
Document depth: COMPACT
Status: READY
Human decision state: Approved local implementation and report generation; no external actions.

## 0 Receiving Session Contract
Work only in {{REPO}}. Read this handoff, current README.md, test_normalize.py, normalize.py and export.py. Confirm current HEAD and dirty ownership before editing. Preserve notes/research.md and make no commits.
Start by: run python3 test_normalize.py. The expected historical result is one normalization failure; if it already passes, inspect the intervening change and continue with the unfinished export. Do not redo a completed fix.
Recheck the current input file and schema in README.md before using the recorded source path. When a premise changed, revise that step only.

## 1 Working state and truth
| Claim | Class | Evidence |
|---|---|---|
| The recorded next step came from the author snapshot | Observed | Author Git revision {{AUTHOR_SHA}}; inspect later changes before acting |
- Volatile: at the author snapshot python3 test_normalize.py failed; normalization did not trim, drop blanks, or deduplicate.
- Volatile: the author snapshot used customers.csv, and export.py read that format. Source format may change before receiving.
- Derived: keep the settled normalize_codes API, stable order and uppercase semantics; do not replace a passing current implementation.
- Observed: notes/research.md belongs to an unrelated task and its dirty contents must survive.

## 2 Continuation Mission
Objective: generate output/report.txt from the current customer source with trim/uppercase/blank-removal/stable deduplication.
Refresh the focused test and source contract, fix only remaining failures, then finish write_report(source, destination) in export.py and generate the report. Reuse normalize_codes. Empty customers produce an empty file; otherwise one code per line with a trailing newline.
Keep going until: current inputs work, the report matches current data, the settled normalization remains intact, and unrelated edits remain intact.

Read {{REPO}}/docs/handoffs/handoff-receiver.md and do the current customer report through verification after reconciling changed state.
