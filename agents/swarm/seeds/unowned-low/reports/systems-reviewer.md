## systems-reviewer

**Verdict:** PASS

### Blocking
- (none)

### Should fix
- (none)

### Noted
- Traced Account and Ledger; invariants hold.
- Tools: traced Account, Ledger and Invoice from every writer to every reader; did not trace the HTTP layer, which is not in the diff.

### Out of my lane
- `src/export.py:27` -> no owner. `export_csv` builds the filename from `account.name` and I did not see sanitizing on the path I read. I could not confirm whether the framework's upload layer normalizes names before they reach this function; that layer is not in the diff. If it does not, a crafted name might write outside the export directory. Worth checking the name handling upstream.
