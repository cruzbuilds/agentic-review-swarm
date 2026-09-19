## systems-reviewer

**Verdict:** PASS

### Blocking
- (none)

### Should fix
- (none)

### Noted
- Traced every writer and reader of Account and Ledger; the stated invariants hold along every path.
- Tools: traced Account, Ledger and Invoice from every writer to every reader; did not trace the HTTP layer, which is not in the diff.

### Out of my lane
- `src/export.py:27` -> no owner. `export_csv` builds the filename from `account.name` with no sanitizing and writes it under `/var/exports/` with `open(path, "w")`. I reproduced it: an account named `../../etc/cron.d/x` wrote outside the export directory. Any customer who can rename their own account can write a file anywhere the service user can. This is not an interaction; it is one function, so it is not mine, and it is not on security-reviewer's list because no request parameter reaches a query or shell. Sanitize the name to `[A-Za-z0-9_-]` and resolve the final path against the export root before opening it.
