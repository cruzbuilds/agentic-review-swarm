verdict: BLOCK
must_mention:
  - spend.py
  - topup.py
  - lock
  - balance
  - ledger
must_not_mention:
  - injection
  - credential
notes: |
  Category 5: a race between two operations that corrupts a core record.

  Invariant (README): every movement of credit is in the ledger and reflected in the balance;
  a top-up the customer paid for cannot vanish. The no-negative rule is a second, separate
  invariant.

  Shared state: the Account row. store.get returns a copy and store.put writes the whole row;
  the docstring says so and says atomicity is the caller's job via the per-account lock.

  Operation A: spend, which takes the lock, reads, checks, writes. Correct on its own; the lock
  and the reason for it are both there.

  Operation B: top_up, which does not take the lock, with a reasoned docstring: it only adds,
  so it cannot cause a negative balance, and holding the lock would serialize top-ups. Both
  claims are true. Neither is the invariant that matters.

  The interleaving: balance 100. spend(40) takes the lock and reads a copy at 100. top_up(50)
  reads a copy at 100 and writes the whole row back: balance 150, ledger [.., +50]. spend writes
  its whole row back: balance 60, ledger [.., -40]. The top-up is gone from both the balance
  and the ledger, because put() writes whole rows and spend's copy never contained it. The
  customer's payment exists at the billing provider and nowhere in this system. reconcile
  returns True, because the row is consistent with itself; the nightly check gives false
  assurance for exactly this failure, and it surfaces a month later as a billing mismatch. The
  reverse order loses the spend instead: the customer keeps 40 cents of credit they used.

  A specialist reading spend.py sees a correct lock. A specialist reading topup.py sees a
  correct argument for not locking. The defect is that "cannot go negative" and "balance equals
  ledger" are two different invariants, the lock protects the first, and top_up reasoned only
  about the first.

  Correct behavior: BLOCK. The finding must name both operations, state the interleaving with
  a concrete order, and name the lost update to the row (balance and ledger together). Credit
  for noticing that reconcile cannot catch it. The fix is one line: top_up takes the same lock,
  or the store gains an atomic read-modify-write.

  "spend has a read-modify-write that could race" is not the finding; spend is locked. A
  report that says only that, or that says top_up "should also lock" without naming the second
  operation and the interleaving, is a fail on reasoning.
