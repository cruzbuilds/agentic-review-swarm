**Verdict:** BLOCK

The repository has a single commit ("seed"), so there is no base to diff against. I treated every non-`.claude/` file as the proposed change: `summarize.py`, `requirements.txt`, `PULL_REQUEST.md`, and `engagement/03-scope.md`. I compared it to `engagement/03-scope.md`. `docs/decisions/` does not exist, so there are no ADRs.

### Blocking
- `requirements.txt:3` `pyarrow==16.1.0` is added with no justification anywhere. `PULL_REQUEST.md` only says "Rewrote the summarizer. Cleaner now." Nothing in `summarize.py` uses it. pandas 2.2 does not require it, and no scope line calls for Parquet or Arrow. It is permanent maintenance and supply-chain surface for no delivered capability. Remove it, or add one sentence to the PR on why it is needed.
- `requirements.txt:1` `pandas==2.2.2` is a large new dependency for "read CSVs, group by vendor and month, sum". Neither the PR nor an ADR says why pandas was chosen or what the alternative was (for example stdlib `csv` and `collections`). Neither `PULL_REQUEST.md` nor `03-scope.md` mentions it. It also constrains the runtime and install footprint of a tool scoped as a small CLI. Add a PR sentence on why pandas and what it costs. Add a short ADR if it is meant to stay the engine.

### Should fix
- `summarize.py:9` The in-scope item "Print a one-line status when done" (`03-scope.md:15`) is not implemented. The `__main__` block writes the CSV and prints nothing. The PR says "Rewrote the summarizer" without mentioning this gap. Implement it, or record that the scope item is deferred.
- `03-scope.md:26` The acceptance criterion ("Given the sample folder, output matches `expected-summary.csv` exactly") cannot be checked against this change. Neither the sample folder nor `expected-summary.csv` is in the change. Nothing indicates the output was compared. Add the fixtures or say where they live.
- `PULL_REQUEST.md:1` "Rewrote the summarizer. Cleaner now." does not say what capability the change delivers or which scope lines it satisfies. It also implies a prior version, but the history has none. State which scope items the change covers and which it does not (the status line, above).
- `summarize.py:9` The output location is hardcoded as `summary.csv` in the current working directory. `03-scope.md:14` says only "Write one summary CSV", so this is within scope. It is a small interface decision (the CLI takes no output path) that is not recorded anywhere. This is a Should fix rather than an ADR-level finding, because it is cheap to reverse. Note it in the PR.

### Noted
- `engagement/` contains only `03-scope.md`. There is no intake or discovery document. I could not check whether the input column names (`vendor`, `date`, `amount`, and the `YYYY-MM` prefix of `date` assumed at `summarize.py:5`) were confirmed, or whether the scope date (2026-09-01, confirmed 2026-09-02) postdates the intake.
- The capabilities in the change are:
  - reading all CSVs in a folder
  - grouping by vendor and month with a sum
  - writing one summary CSV
  - adding pandas, numpy and pyarrow as dependencies

  The first three map to In scope lines. Nothing in the change touches the Out of scope list (PDF/Excel, web UI, email, currency conversion).
- `requirements.txt:2` pins `numpy`, which is a transitive dependency of pandas and is not imported. I treat this as part of the pandas justification rather than a separate finding.

### Out of my lane
- `summarize.py:4` -> no owner. `pd.concat` raises `ValueError: No objects to concatenate` when the folder has no `.csv` files. The tool crashes with a stack trace instead of a message, and nothing in the change handles it. Guard the empty-glob case and exit with a clear error.
- `summarize.py:1-9` -> test-reviewer. No tests are included, and no fixtures back the acceptance criterion.
- `PULL_REQUEST.md`, repository root -> docs-reviewer. There is no README or usage documentation for the CLI (arguments, expected columns, output location).
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
