**Verdict:** BLOCK

### Blocking
- `summarize.py:6` The change persists all invoices to an on-disk SQLite database (`invoices.db`, lines 3 and 8) "so we can run ad-hoc queries later". `engagement/03-scope.md` says "A command-line tool that reads a folder of CSV invoices and produces one summary CSV of totals per vendor per month." Ad-hoc querying and a persistent store appear nowhere in the In scope list. This is scope growth justified by a future need, and it is the "it was easy to add" pattern. Either remove the database and aggregate in memory (the earlier approach the comment mentions), or add the capability to `03-scope.md` and update the confirmed-with line with Dana Whitfield.

### Should fix
- `summarize.py:16` The in-scope deliverables are not in the change. `03-scope.md` requires "Write one summary CSV" and "Print a one-line status when done". `summarize()` returns rows in memory and nothing writes a CSV or prints a status. There is no command-line entry point, and `sys` is imported at line 1 but never used. The change delivers only "Read every `.csv`" and "Group by vendor and month, sum". Add the CSV output, the status line and the entry point, or say in the PR that this is a partial delivery.
- `summarize.py:1` The acceptance criterion is "output matches `expected-summary.csv` exactly". The diff has no `expected-summary.csv`, no sample folder, and no output to compare, so the criterion cannot be checked against this change. Add the sample fixture and the output path.
- `summarize.py:3` Choosing SQLite as the datastore is the kind of decision the charter says needs an ADR, and `docs/decisions/` contains only `0001-record-architecture-decisions.md`. I rate it Should fix rather than Blocking because this is a 17-line script and reversing the choice is cheap. If the database is added to scope (see the Blocking item), write a half-page ADR covering the context, the decision, and the consequences of a persistent `invoices.db`.

### Noted
- `engagement/` contains only `03-scope.md`. There is no intake or discovery document, so I could not check the change against unverified assumptions or the "what you don't know yet" list.
- `03-scope.md` has a confirmed-with line (Dana Whitfield, 2026-09-02) dated after the scope date. All four in-scope checkboxes and the acceptance checkbox are unchecked.
- `sqlite3`, `csv` and `glob` are standard library, so there is no new third-party dependency to justify.
- The repository has no PR description. I judged the change against the diff alone.

### Out of my lane
- `summarize.py:12` -> systems-reviewer. `load()` runs `INSERT` into a table that persists across runs (`invoices.db` with `CREATE TABLE IF NOT EXISTS`) and has no dedupe or reset. Running the tool twice on the same folder doubles every total, and the summary depends on the leftover state from earlier runs. I did not run it.
- `summarize.py:10` -> test-reviewer. There are no tests, and the acceptance criterion depends on an exact-match comparison.
- `summarize.py:11` -> no owner. `float(r["amount"])` and `ROUND(SUM(amount),2)` on `REAL` use binary floating point for money, so summed totals can be off by a cent and fail the "matches exactly" criterion. Parse with `decimal.Decimal` or store integer cents. I did not reproduce it.
- `summarize.py:9` -> no owner. `glob.glob(f"{folder}/*.csv")` returns files in arbitrary order and `open(path)` has no encoding. A missing folder silently matches nothing and exits successfully, and malformed rows raise a `KeyError` or `ValueError` with no file context. Fail loudly on an empty match and report the offending file and row.
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
