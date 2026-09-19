**Verdict:** PASS

### Blocking

### Should fix

### Noted
- Compared against `engagement/03-scope.md` (confirmed with Dana Whitfield, 2026-09-02). The repo has no `docs/decisions/` folder, and I found no decision in the diff that would need an ADR. `engagement/` holds only `03-scope.md`, so there was no intake or discovery doc to check against.
- Each capability in the diff maps to an In scope line:
  - `summarize.py:9-14` reads every `.csv` in a folder ("Read every `.csv` in a given folder").
  - `summarize.py:17-22` groups by vendor and month and sums the amount ("Group by vendor and month, sum the amount column").
  - `summarize.py:36-40` writes one summary CSV ("Write one summary CSV").
  - `summarize.py:41` prints a one-line status ("Print a one-line status when done").
- Nothing in the diff touches Out of scope items (PDF/Excel, web UI, email, currency conversion).
- No new dependency. `PULL_REQUEST.md` says "Standard library only", and the imports in `summarize.py:3-6` confirm it.
- The acceptance criterion is checkable. Working the sample by hand gives the `expected-summary.csv` rows: Acme 2026-01 is 120.00 + 80.00 = 200.00, Acme 2026-02 is 40.00, and Bolt 2026-01 is 15.50. I did not run the script.
- `summarize.py:25-30` adds `_legacy_decimal`, which handles comma decimals and has no caller. Its comment says it is kept "in case the old format comes back". It does not extend the tool's capability, so this is not scope creep. Handling a format that is not in scope is speculative, though, and worth removing.

### Out of my lane
- `summarize.py`, `expected-summary.csv` -> test-reviewer. The acceptance criterion ("output matches `expected-summary.csv` exactly") is not automated. The change has no test or script that runs the tool on `sample/` and diffs the output.
- `summarize.py:18-21` -> no owner. Money amounts are summed as binary `float` and formatted with `:.2f`. Over many invoice rows the accumulated error can shift a total by a cent, and the tool has no other check on its totals. It is fine for the current sample. Use `decimal.Decimal` for parsing and summing before this handles real invoices.
- `summarize.py:34` -> no owner. `argv[1]` raises a bare `IndexError` when no folder is given. This is a minor usability gap. Print a usage line and return non-zero instead.
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
