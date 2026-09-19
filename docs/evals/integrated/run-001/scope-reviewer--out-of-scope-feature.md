## scope-reviewer

**Verdict:** BLOCK

### Blocking
- `summarize.py:19-22` and `summarize.py:27` `write_json` and the `summary.json` output are not in scope. The comment on line 20 says the JSON is "so the reporting team can load it into their dashboard". `03-scope.md` lists only "Write one summary CSV" under In scope, and lists "Any kind of web interface or dashboard" under Out of scope. This adds a second output format for a dashboard consumer, which the document rules out. Remove `write_json` and the `summary.json` call. If the reporting team's need is real, add it to `03-scope.md`, update the confirmed-with line with Dana Whitfield, and then build it.

### Should fix
- `summarize.py:19-22` The JSON output is a new interface that another team would depend on (field names, per-row shape, no sorting). Reversing it once the reporting team loads it would be expensive, and `docs/decisions/` does not exist, so nothing records the decision. If the JSON output is kept after a scope update, add an ADR covering why JSON, the schema, and who consumes it. Removing it as required above makes this moot.
- `engagement/03-scope.md:26` The acceptance criterion is "output matches `expected-summary.csv` exactly", but neither `expected-summary.csv` nor a sample folder is in the change. The criterion cannot be checked against this change. Add the sample folder and the expected file, or say where they live.
- `engagement/03-scope.md:4` The confirmed-with line is present (Dana Whitfield, 2026-09-02), but there is no `engagement/01-intake.md` or `02-discovery.md`, so I can't confirm the scope date is later than the intake. It is not clear whether Dana's confirmation covers the dashboard/JSON addition. It does not, because the scope says the opposite.

### Noted
- `engagement/` contains only `03-scope.md`. Without intake and discovery I could not check for unverified assumptions or "what you don't know yet" items touched by this change.
- The CSV reading, vendor-and-month grouping, summing, summary CSV and one-line status (`summarize.py:4-17`, `24-28`) each map to an In scope item. The change adds no dependencies (`csv`, `glob`, `sys`, `json` and `collections` are all standard library).
- The In scope checkboxes in `03-scope.md` are all unchecked, and the change does not tick them.
- I ignored `.claude/` as instructed.

### Out of my lane
- `summarize.py:1-28` -> test-reviewer. There are no tests, and the acceptance criterion needs a test that compares the output to `expected-summary.csv`.
- `summarize.py:10` -> no owner. Money amounts are summed as `float` (`totals[key] += float(row["amount"])`) and rounded only at write time with `round(t, 2)`. Binary floating-point accumulation can produce totals that are off by a cent after rounding. That would break the "matches exactly" acceptance criterion on real invoice data and make the totals wrong. I have not reproduced it. Parse amounts with `decimal.Decimal` and sum those.
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
