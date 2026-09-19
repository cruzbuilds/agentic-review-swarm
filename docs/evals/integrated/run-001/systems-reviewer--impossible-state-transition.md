**Verdict:** BLOCK

### Blocking
- `coupons.py:17-18`, `payments.py:8-11`, `models.py:14` **A coupon applied to a PAID order leads to a second charge, and the record of the first charge is lost.**
  - **Invariant:** `README.md:12` says "An order is charged exactly once. `payment_id` is set when the charge is captured and is the record of that charge." `models.py:14` says `payment_id` is "set once".
  - **Interaction:**
    1. An order is PLACED. `payments.capture` charges `total_cents` (say 10000), sets `payment_id = "P1"` and sets status PAID.
    2. The customer applies `WELCOME10`. `coupons.apply_coupon` allows PAID (`coupons.py:12`), sets `discount_cents`, and moves the order back to PLACED (`coupons.py:17-18`). It does not touch `payment_id`, and it does not refund or void P1.
    3. Checkout re-runs `payments.capture`, exactly as the `coupons.py` docstring says it should. `require_status(order, "PLACED")` passes. The provider charges the new total (9000). `order.payment_id` is overwritten with "P2" and the order is PAID again.
  - **Why each step looks fine:**
    - `apply_coupon` is documented and consistent with "coupons any time before shipping".
    - `capture` correctly charges only from PLACED.
    - Each file does what its own docstring says. The defect is that "PLACED" now means two things: "never charged" and "charged, then reopened". `capture` assumes the first meaning. `apply_coupon` creates the second.
  - **Failure:**
    - The customer has paid 19000 for a 9000 order, with two live charges at the provider.
    - The order holds only P2. `refund` (`payments.py:17`) refunds only `order.payment_id`, so P1 can never be refunded through this system and is orphaned.
    - Even the correct-looking version of the flow is wrong. If P1 were refunded and P2 charged, `payment_id` would still be overwritten, so the original charge record would be lost.
  - **Fix:** Enforce it at the charge site so no caller can bypass it. `capture` should refuse when `order.payment_id` is already set. `apply_coupon` should then either (a) reject PAID orders, or (b) refund the existing charge and clear `payment_id` before it reopens the order. Option (b) needs a transaction or an ordered refund-then-reopen so a failure between the two steps cannot leave a PLACED order that still holds a live charge.

### Should fix
- `payments.py:16`, `checkout.py:12-16` **`refund` accepts SHIPPED orders, but the lifecycle allows CANCELLED only from PAID.**
  - `README.md:6-9` draws CANCELLED only from PAID.
  - After `ship` has called `carrier.create_shipment`, `refund` sets the order to CANCELLED while the shipment is still live. Nothing in the change cancels the shipment.
  - If SHIPPED to CANCELLED is intended, the carrier shipment needs cancelling in the same workflow. If it is not intended, drop "SHIPPED" from `require_status` at `payments.py:16`.
  - I cannot confirm intent from the repo, so this is a warn and not a block.
- `checkout.py:13-15`, `coupons.py:17`, `payments.py:8-11` **The same state transitions have no concurrency guard.**
  - I could not confirm this without a persistence layer.
  - `ship` checks PAID, then calls the carrier, then sets SHIPPED. A coupon applied in that window sets PLACED, and `ship` then overwrites it with SHIPPED. That leaves a shipped order whose total changed after its payment.
  - Two concurrent `capture` calls both pass the PLACED check and both charge, because no idempotency key is passed to `provider.charge`.
  - The orders are plain in-memory dataclasses here. If they are persisted elsewhere, the status change needs a version check or row lock, and the provider call needs an idempotency key.

### Noted
- The repo has no storage layer, no HTTP layer and no caller of `place`, `capture` or `apply_coupon`, so I could not trace who re-runs `capture` after a coupon. I relied on the `coupons.py` docstring, which says "checkout re-runs capture".
- `discount_cents` is recomputed from `subtotal_cents` on each call, so repeated coupons do not stack. I traced this and it holds.
- I ignored `.claude/` as instructed.

### Out of my lane
- `README.md:12-13` -> docs-reviewer. It says coupons can be applied "any time before shipping" but does not say that this reopens payment on a PAID order, and it does not describe the re-capture flow.
- No tests exist for any of the modules -> test-reviewer. A test that runs place, capture, apply_coupon, capture and asserts on the charge count would expose the blocking finding above.
