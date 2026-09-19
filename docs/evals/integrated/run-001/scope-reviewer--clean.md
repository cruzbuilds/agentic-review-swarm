## scope-reviewer

**Verdict:** WARN

### Blocking
- None.

### Should fix
- `engagement/03-scope.md:26` The acceptance criterion says "Given the sample folder, output matches `expected-summary.csv` exactly", but neither a sample folder nor `expected-summary.csv` is in this change. The only in-scope deliverable, `summarize.py`, therefore can't be checked against its own definition of done. Add the sample CSVs and `expected-summary.csv`, or say in the PR where they live.
- `engagement/03-scope.md:4` Scope is confirmed by Dana Whitfield on 2026-09-02, but there is no `engagement/01-intake.md` or discovery doc. I can't check that the confirmation postdates the intake. I also can't check whether the code touches any unverified assumptions. Add the intake and discovery docs, or note in the PR that they were deliberately skipped.

### Noted
- Every capability in `summarize.py` maps to an In scope line:
  - Lines 6-9 read each `.csv` in a folder and group by vendor and month, summing `amount`. This matches "Read every `.csv` in a given folder" and "Group by vendor and month, sum the amount column".
  - Lines 12-16 and 20 write one summary CSV. This matches "Write one summary CSV".
  - Line 21 prints a one-line status. This matches "Print a one-line status when done".
- Nothing in the diff touches an Out of scope item (PDF or Excel input, web UI, email, currency conversion).
- No new dependencies. The script uses only the standard library (`csv`, `glob`, `sys`, `collections`).
- No ADR is needed. The output filename is hardcoded to `summary.csv` in the current directory, which is cheap to reverse and doesn't constrain future work. `docs/decisions/0001` only establishes the ADR practice.
- The In scope checkboxes in `03-scope.md` are all unchecked, although the code now covers them. This is bookkeeping and needs no action.
- There is no handoff document, so there is no "what this doesn't do" section to go stale.

### Out of my lane
- `summarize.py` -> test-reviewer. There are no tests, and nothing exercises the acceptance criterion.
- `summarize.py:9` -> no owner. `row["date"][:7]` assumes ISO `YYYY-MM-DD` dates. A date such as `3/5/2026` becomes the month key `3/5/202`, with no error, and totals are grouped under the wrong month. I did not confirm the actual input format. Validate the format, or parse with `datetime` so bad rows fail loudly.
- `README.md` (missing) -> docs-reviewer. There is no usage documentation for the CLI, such as the folder argument or the `summary.csv` output location.
# 3. Scope

**Date:** 2026-09-01
**Confirmed with:** Dana Whitfield, 2026-09-02

## What we are building

A command-line tool that reads a folder of CSV invoices and produces one summary CSV of totals per vendor per month.

## In scope

- [ ] Read every `.csv` in a given folder
- [ ] Group by vendor and month, sum the amount column
- [ ] Write one summary CSV
- [ ] Print a one-line status when done

## Out of scope

- Reading PDFs or Excel files
- Any kind of web interface or dashboard
- Emailing the summary anywhere
- Currency conversion

## Acceptance criteria

- [ ] Given the sample folder, output matches `expected-summary.csv` exactly
