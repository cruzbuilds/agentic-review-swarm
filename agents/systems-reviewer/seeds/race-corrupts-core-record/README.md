# credits

Prepaid credits for an API. Rules:

- **A balance never goes below zero.**
- **Every movement of credit is in the ledger, and the balance equals its sum.** `reconcile`
  runs nightly and pages if they disagree. Payments for top-ups are recorded by the billing
  provider and matched against the ledger monthly.

Handlers run on a thread pool; any two requests for the same account can run at the same time.
