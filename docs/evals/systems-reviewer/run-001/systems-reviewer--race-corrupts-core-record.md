## systems-reviewer

**Verdict:** BLOCK

### Blocking
- `topup.py:9-12` (with `spend.py:13-19` and `store.py:13-25`) A concurrent top-up and spend on one account silently erase each other, and `reconcile` reports the account as healthy.
  - **Invariant:** The README says "every movement of credit is in the ledger, and the balance equals its sum". It also says handlers run on a thread pool and "any two requests for the same account can run at the same time". `store.py:13-14` says callers that need atomicity take the per-account lock.
  - **Interaction:**
    1. `top_up` calls `store.get()` with no lock and receives a copy of the whole row (balance 100, ledger `[opening]`).
    2. While it holds that copy, `spend` takes the lock, debits 30, and calls `put()`. The stored row is now balance 70 with ledger `[opening, -30]`.
    3. `top_up` adds 50 to its stale copy and calls `put()`, which writes the whole row. The stored row is balance 150 with ledger `[opening, top-up 50]`.
    4. The spend is gone. The reverse order loses the top-up instead.
  - **Why each step looks fine:**
    - `spend` is correctly locked, and its docstring only claims to protect the balance check.
    - `top_up` reasons that it "only ever adds" and so cannot go negative. That is true for the no-negative rule.
    - `Store.put` writing a whole row is reasonable for a key/value store.
    - `reconcile` correctly compares a balance to its own row's ledger.
    - The lock only protects the writers that take it, and `top_up` never does. The row-level lost update sits between `top_up` and `spend`, so neither file shows it.
  - **Failure:** I ran this interleaving against the code without modifying the repo. It ended at balance 150 with ledger `[('opening', 100), ('top-up', 50)]`, and `reconcile()` returned `True`.
    - In this order the customer keeps 30 cents of API usage that was never charged or recorded.
    - In the other order a top-up the customer paid for vanishes from balance and ledger.
    - Because the whole row is overwritten, the balance and ledger stay consistent with each other. The nightly `reconcile` never pages, and the README names it as the safeguard.
    - The only remaining signal is the monthly match against the billing provider, and that matches payments, not spends. A lost spend is never detected.
  - **Fix:** Make `top_up` take `with store.lock(account_id):` around its get/modify/put, as `spend` does. The docstring's concern about serializing behind long spends does not apply, because `spend` holds the lock only across an in-memory read-modify-write. Better still, put the locked read-modify-write inside `Store` (an `apply(account_id, reason, delta)` method) so no caller can bypass it.

### Should fix
- `store.py:27-28` The lock registry and `create` (`store.py:30-31`) are not synchronized with each other. `create()` on an existing id replaces the row and its ledger without taking the lock, so it can wipe out concurrent spends or top-ups on that account. I did not trace a caller, because none exists in this change. If `create` is reachable for existing accounts, make it fail on an existing id and take the account lock.
- `spend.py:13-14` and `store.py:20-22` `store.get` raises `KeyError` for an unknown account, and the `Insufficient` and `ValueError` paths are the only other exits. I did not trace the callers, which are not in the change. The same gap exists in `top_up`, `topup.py:9`, so a top-up for a nonexistent account fails loudly rather than crediting nothing. That is fine as written, but the handlers should map it to a not-found response rather than a 500. This is low confidence and needs the handler layer to confirm.

### Noted
- Not traced: the HTTP handlers, the billing-provider integration, and the monthly matching job are not in this change. The claim that a lost spend is never detected rests on the README's description of that matching as payments against ledger.
- `reconcile.py:6` reads a single `get()` snapshot. Because `put` swaps in a whole new row object, `reconcile` never sees a torn balance/ledger pair, so it has no race of its own. The gap is that whole-row overwrites make torn state impossible while still losing writes.
- The no-negative-balance rule holds along the paths I traced. Spends are serialized on the lock, and a stale top-up write can only raise a balance, never lower it below zero.

### Out of my lane
- `__pycache__/*.pyc` compiled bytecode is committed to the repo. No owner in the roster. It is repo hygiene and would normally be handled by a `.gitignore`.
- No tests exist for `spend`, `top_up`, or `reconcile`, and none exercise concurrent access. That is test-reviewer's call.
- The README does not describe the API surface, how to run anything, or how `top_up` relates to the billing provider's payment records. That is docs-reviewer's call.
