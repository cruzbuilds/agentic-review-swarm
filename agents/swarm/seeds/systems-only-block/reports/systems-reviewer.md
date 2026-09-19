## systems-reviewer

**Verdict:** BLOCK

### Blocking
- `src/invoices.py:44`, `src/credits.py:12`, `src/billing.py:70` **A credit applied after an invoice is issued leaves the invoice total and the amount charged different.**
  - **Invariant:** README.md:12, the amount charged equals the invoice total at issue time.
  - **Interaction:** 1. `issue` (`src/invoices.py:44`) snapshots `total` and sets `status = "issued"`. 2. `apply_credit` (`src/credits.py:12`) subtracts from `invoice.total` with no status check; it is valid for draft invoices and nothing says otherwise. 3. `billing.charge` (`src/billing.py:70`) charges `invoice.total`, the live field, not the snapshot.
  - **Why each step looks fine:** issue snapshots correctly; apply_credit is a plain subtraction that is right for drafts; charge reads a field that is right until step 2 happens.
  - **Failure:** I ran it: issue at 1000, apply_credit 300, charge captured 700 while the issued document the customer received says 1000. The books and the customer disagree by 300.
  - **Fix:** `apply_credit` refuses when `status != "draft"`, or `charge` uses the snapshot. One line at `src/credits.py:12`.

### Should fix
- (none)

### Noted
- Tools: traced Account, Ledger and Invoice from every writer to every reader; did not trace the HTTP layer, which is not in the diff.

### Out of my lane
- (none)
