## systems-reviewer

**Verdict:** BLOCK

### Blocking
- `coupons.py:17-18`, `payments.py:8-11`, `payments.py:16-17`, `models.py:14`: **A coupon applied to a PAID order lets the customer be charged twice and loses the record of the first charge.**
  - **Invariant:** `README.md:12` says "An order is charged exactly once. `payment_id` is set when the charge is captured and is the record of that charge." `models.py:14` says `payment_id` is "set once".
  - **Interaction:**
    1. The order is PAID with `payment_id="ch_1"`, from `capture` (`payments.py:10-11`).
    2. The customer calls `apply_coupon` (allowed in PAID, `coupons.py:12`). It lowers `discount_cents` and sets `status = "PLACED"` (`coupons.py:17-18`). It leaves `payment_id="ch_1"` in place and does nothing with the money already captured.
    3. Checkout re-runs `capture`, as the docstring at `coupons.py:9-10` says it should. `require_status(order, "PLACED")` passes (`payments.py:8`), so `provider.charge(...)` bills the customer again for the new total.
    4. `order.payment_id = charge.id` overwrites `ch_1` with `ch_2` (`payments.py:10`).
  - **Why each step looks fine:**
    - `apply_coupon` is correct against its own docstring and the README's "any time before shipping".
    - `capture` is correct because it only charges an order that is PLACED.
    - `refund` correctly refunds `order.payment_id`.
    - No single file breaks a rule. The break comes from the coupon module reusing PLACED to mean "needs a new charge" while the payment module reads PLACED as "never charged".
  - **Failure:**
    - The customer is billed for the full price and then again for the discounted price.
    - The only record of the first charge, `ch_1`, is gone. `refund` at `payments.py:17` can only ever return `ch_2`, so `ch_1` can't be refunded from this system.
    - If the order is not re-captured, it sits in PLACED with a live charge. `refund` rejects PLACED (`payments.py:16`), so that charge can't be refunded either. This is a second, smaller way to reach the same broken state.
  - **Fix:**
    - Keep the guard in the payment module, where the charge happens: `capture` should refuse when `order.payment_id is not None`.
    - Then change `apply_coupon` so it never moves a PAID order back to PLACED while a charge exists. Either reject coupons once PAID, or refund the old charge and clear `payment_id` before resetting to PLACED. Refunding first means a refund failure aborts the coupon instead of leaving a live charge behind.

### Should fix
- `payments.py:8-11`: `capture` has no idempotency guard on the provider call. Two `capture` calls on the same PLACED order, such as a double-submit or a retry after a timeout, both pass `require_status` before either sets PAID. Both reach `provider.charge`, and the second overwrites `payment_id`. It is the same "charged exactly once" violation reached by a retry instead of a coupon. I could not confirm the interleaving because I can't see the caller or any persistence layer. Pass an idempotency key derived from the order id and total to `provider.charge`, and set state under a lock or version check.
- `payments.py:16-18`: `refund` accepts SHIPPED and moves the order to CANCELLED. The README diagram (`README.md:6-9`) only allows CANCELLED from PAID. Either the code or the diagram is wrong. As written, an order with a live shipment can be cancelled with no call to the carrier to stop it.
- `checkout.py:12-16`: `ship` calls `carrier.create_shipment` before setting SHIPPED. If the status write fails or `ship` is retried, a second shipment can be created for one order. I can't see the storage layer, so I could not confirm this.

### Noted
- Nothing in the change calls `capture`, `refund` or `apply_coupon` in sequence. The `coupons.py:9-10` docstring says "checkout re-runs capture", but `checkout.py` has no such call. I traced the flow from the module contracts and could not see the real caller.
- `Order` is an in-memory dataclass with no persistence. The concurrency findings above assume a shared store behind it that isn't in this change.

### Out of my lane
- No tests exist for any of the modules. `test-reviewer` should cover the PAID -> coupon -> capture path in particular.
- `README.md:5-10` does not show the PAID -> PLACED backward transition that `coupons.py:17-18` performs. That's `docs-reviewer`'s call.
- `__pycache__/*.pyc` files are committed. Nobody in the roster owns repository hygiene. `infra-reviewer` is the closest fit.
