## test-reviewer

**Verdict:** BLOCK

### Blocking
- `src/ledger.py:31` `apply_credit` has a new branch for negative amounts (refunds) with no test that exercises it. A test that calls `apply_credit(account, -500)` and asserts the ledger row and the balance. Without it the next change to the sign handling ships silently.

### Should fix
- (none)

### Noted
- Tools: pytest ran: 14 passed. Coverage on changed lines: 100%.

### Out of my lane
- (none)
