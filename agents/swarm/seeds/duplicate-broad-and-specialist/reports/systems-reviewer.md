## systems-reviewer

**Verdict:** BLOCK

### Blocking
- `src/invoices.py:18`, `src/auth.py:40`, `src/billing.py:55` **A customer can mark another customer's invoice paid and stop their dunning emails.**
  - **Invariant:** README.md:9, an invoice's status is changed only by its owner or by the billing job.
  - **Interaction:** 1. `PATCH /invoices/{id}` (`src/invoices.py:18`) accepts `status`. 2. It authorizes through `require_owner` (`src/auth.py:40`), which compares the invoice's owner to `user_id` taken from the request body, so the caller supplies the value being checked. 3. `billing.run` (`src/billing.py:55`) skips dunning for any invoice with `status == "paid"`.
  - **Why each step looks fine:** the PATCH handler does call an ownership check; `require_owner` does compare two ids; `billing.run` correctly skips paid invoices.
  - **Failure:** I ran it: user 2 sent `{"user_id": 1, "status": "paid"}` against user 1's invoice and the row changed; the next `billing.run` skipped it. Money owed is never chased.
  - **Fix:** `require_owner` takes the id from the session (`request.session.user_id`), one line at `src/auth.py:40`. That closes every caller at once.

### Should fix
- (none)

### Noted
- Tools: traced Account, Ledger and Invoice from every writer to every reader; did not trace the HTTP layer, which is not in the diff.

### Out of my lane
- (none)
