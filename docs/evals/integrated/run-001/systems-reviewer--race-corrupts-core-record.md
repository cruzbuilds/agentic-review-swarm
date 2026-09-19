**Verdict:** BLOCK

### Blocking
- `topup.py:9-12` (with `spend.py:13-19` and `store.py:20-28`): `top_up` is a lock-free read-modify-write that can overwrite a concurrent `spend` or `top_up` on the same account. This loses the update and leaves reconcile with nothing to detect.
  - **Invariant.** `README.md:5-7` says every movement of credit is in the ledger and the balance equals its sum. `store.py:13-14` says atomicity requires the per-account lock. `spend.py:9-10` takes that lock. `topup.py:5-6` deliberately skips it.
  - **Interaction.** The store hands out copies from `get()` and `put()` replaces the whole row. So a lock-free writer overwrites everything a locked writer did between the writer's `get` and its `put`. `README.md:10` says two requests for the same account can run at the same time. The steps below start with balance 100 and ledger `[opening +100]`.

    Lost spend:
    1. `top_up(50)` calls `get`, so its copy has balance 100 and the ledger with only the opening entry.
    2. `spend(30)` takes the lock, gets, sets balance 70, appends `-30`, and calls `put`. It returns 70 and the API call is served.
    3. `top_up` sets balance 150, appends `+50`, and calls `put`. This replaces the row that step 2 wrote.
    4. The final row is balance 150 and ledger `[+100, +50]`. The 30-cent spend is gone from both balance and ledger.

    Lost top-up (mirror case):
    1. `spend(30)` takes the lock and gets its copy.
    2. `top_up(50)` runs to completion without the lock. The row is now 150.
    3. `spend` puts balance 70 with a ledger that lacks `+50`.
    4. The customer paid for 50 and never received it.

    Two concurrent `top_up` calls also lose one of the two credits.
  - **Why each step looks fine.** `spend` is correct because it holds the lock for its whole check-and-write. `top_up` is correct in isolation because it only adds and cannot go negative, and its docstring says so. `Store` is correct because it documents "no transactions; take the lock". `reconcile` is correct because it compares balance to ledger. Each file passes review alone. The defect is that a locked writer only excludes other writers that also take the lock.
  - **Failure.** Credit is created or destroyed silently. In the lost-spend case the account gets service it never paid for. In the lost-top-up case a paying customer loses credit. In both cases the balance still equals the sum of the surviving ledger entries, so the nightly `reconcile` (`reconcile.py:7`) returns True and never pages. The only remaining check is the monthly match against the billing provider (`README.md:7-8`). The lost-spend case has no external counterpart, so nothing catches it at all.
  - **Fix.** Take `store.lock(account_id)` around the get, modify and put in `topup.py`. The lock is held for microseconds of in-memory work. The stated serialization cost applies to how long callers hold the lock, not to the lock itself. Better still, put a single `apply(account_id, reason, delta)` on `Store` that holds the lock and enforces the floor. Then `put` is not a public entry point that callers can use to bypass the lock.

### Should fix
- `store.py:24-25` and `store.py:27-28`: The lock protocol lives only in a docstring. `put()` and `get()` do not check that the caller holds the lock, so any new caller of `put` can repeat the `topup.py` bug. Make the locked path the only way to write, for example the `apply` method above. This is a second look at the fix above, not a separate defect.

### Noted
- I traced writes and reads of `Account` through `topup.py`, `spend.py`, `reconcile.py` and `store.py`. There is no caller code, so I could not check how handlers pick `reason` or how the billing match runs. I did not run anything. The race depends on interleaving and is not reproducible in a single-threaded test.
- `reconcile` reads without the lock, but `get()` captures the row reference once and `put()` swaps whole rows. It therefore sees a consistent snapshot, and I found no false-alarm path there.

### Out of my lane
- `store.py:30-31` -> no owner. `create()` on an existing `account_id` replaces the row without the lock. This resets the balance to `opening_cents` and discards the ledger, and a concurrent `spend` or `top_up` is lost the same way. Reject an existing id, or perform the create under `store.lock(account_id)`.
- `topup.py`, `spend.py`, `reconcile.py` -> test-reviewer. There are no tests, and none exercises concurrent `top_up` with `spend`.
