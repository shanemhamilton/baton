# Label export handoff
Document depth: COMPACT
Status: READY
Human decision state: Approved local implementation and sample export; no external actions.

## 0 Receiving Session Contract
Work only in {{REPO}}. Read this document, README.md, labels.py, test_labels.py and sample.json. Confirm Git state and preserve notes/research.md, which contains another task's unfinished edit. No commits are requested.
Start by: run python3 test_labels.py before editing. Preserve settled decisions unless their stated premise changes. Continue through both remaining milestones without asking for permission again.

## 1 Working state and truth
| Claim | Class | Evidence |
|---|---|---|
| Normalization is partially implemented | Observed | Author snapshot {{AUTHOR_SHA}} and the uncommitted trim change in labels.py |
- Observed: notes/research.md has an unrelated uncommitted user note that must remain byte-for-byte intact.
- Volatile: python3 test_labels.py failed because blanks and duplicate names remained; rerun before acting.
- Derived: reuse clean_names in write_labels so the two paths share identical normalization.
- Observed: first spelling and input order are required; sorting and ASCII-only lowercasing were rejected because they change behavior.

## 2 Continuation Mission
Objective: deliver normalized names and the sample label export described in README.md.
1. Finish clean_names: trim, omit blanks, Unicode-casefold deduplicate, preserve first spelling/order. Keep the API and existing test.
2. Implement write_labels(names, destination), then create output/labels.txt from sample.json. Empty input writes an empty file; otherwise each label ends with a newline.
Verify the focused test and actual output. Do not stop after normalization alone.
Keep going until: both API behavior and the sample export work, with unrelated user edits preserved.

Read {{REPO}}/docs/handoffs/handoff-receiver.md and do the label normalization and sample export through verification.
