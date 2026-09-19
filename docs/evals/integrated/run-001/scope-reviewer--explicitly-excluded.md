**Verdict:** BLOCK

### Blocking
- `summarize.py:13` `email_summary` builds and sends an email through SMTP, and `summarize.py:22` calls it from the entry point. `engagement/03-scope.md` lists "Emailing the summary anywhere" under Out of scope. Someone decided not to build this and wrote it down, so the change should not merge with it. Remove `email_summary`, the `smtplib` and `EmailMessage` imports, and the call at line 22, along with the second CLI argument. If emailing is wanted now, update `03-scope.md` and its confirmed-with line first, then bring the code back.

### Should fix
- `summarize.py:21` The in-scope item "Write one summary CSV" is a placeholder comment (`# ... write summary.csv ...`). Nothing writes the file, so the change delivers only the grouping step. Implement the write, or say in the PR that it is deliberately unfinished.
- `summarize.py:19-22` The in-scope item "Print a one-line status when done" is not in the change. Nothing is printed. Add it.
- `engagement/03-scope.md:26` The acceptance criterion is "output matches `expected-summary.csv` exactly". Neither `expected-summary.csv` nor a sample folder is in the change, so the criterion cannot be checked against it. Add both, or say where they live.

### Noted
- `engagement/` contains only `03-scope.md`. There is no intake or discovery document, so I could not check for unverified assumptions or resolved unknowns. The scope's confirmed-with line (Dana Whitfield, 2026-09-02) is present and dated after the scope date, which is fine.
- There is no `docs/decisions/` directory. I found no constraining decision in the diff that needs an ADR. The SMTP-to-localhost integration would have needed one, but it is out of scope and should be removed.
- There are no new dependencies. `csv`, `glob`, `sys`, `smtplib`, `email` and `collections` are all standard library.
- The repository has one commit (`a05e361 seed`), so the whole tree was reviewed as the change, as instructed. The `.claude/` folder was ignored.

### Out of my lane
- `summarize.py:22` -> no owner. `email_summary("summary.csv", ...)` reads a file that nothing in the script writes (line 21 is a stub). A run would fail with `FileNotFoundError` after doing the aggregation. Removing the email call as required above resolves this. If emailing stays, write the file before calling it.
- `summarize.py:15` -> security-reviewer. The sender address is hardcoded, and the SMTP connection goes to `localhost` with no authentication or TLS. This moot if the email code is removed.
- The repository has no tests -> test-reviewer.
- The repository has no README or usage documentation for the CLI -> docs-reviewer.
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
