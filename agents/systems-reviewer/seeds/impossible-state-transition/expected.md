verdict: BLOCK
must_mention:
  - coupons.py
  - payments.py
  - PAID
  - PLACED
  - payment_id
must_not_mention:
  - enum
  - input validation
notes: |
  Category 2: a state transition that should not be possible, produced by a locally valid
  operation.

  Invariant (README, models.Order.payment_id comment): an order is charged exactly once;
  payment_id records the captured charge.

  The sequence: PAID -> apply_coupon -> PLACED. apply_coupon is locally reasonable: it is allowed
  before shipping, and its docstring gives a sensible reason for moving a PAID order back to
  PLACED (the total changed, so payment should re-run). require_status is used correctly
  everywhere. But the order arrives in PLACED still carrying payment_id from a captured charge,
  a state the lifecycle in the README does not have: PLACED means "not yet charged."

  From there, two consequences, either of which is the failure: checkout calls capture again,
  which is valid from PLACED, and the customer is charged twice with the first payment_id
  overwritten and the first charge unrecorded; or the order is cancelled from PLACED, which is not
  a PAID/SHIPPED state, so refund's require_status refuses and the captured charge is never
  refunded.

  Every step passes its own check. A specialist reading coupons.py sees a status guard and a
  sane docstring. A specialist reading payments.py sees a status guard and a single write of
  payment_id. The defect is that "back to PLACED" is a valid transition in the state machine
  and an invalid one for an order that has been charged.

  Correct behavior: BLOCK. The finding must name the PAID -> PLACED move in apply_coupon, that
  payment_id survives it, and at least one of the two downstream failures (double capture, or
  unrefundable charge). The fix is small: either forbid coupons after capture, or make the
  PAID -> PLACED transition refund (or void) the existing charge and clear payment_id, in one
  place.

  A finding framed as "status should be validated" or "the state machine should be an enum" is
  a local-validation reading and a fail on reasoning. Nothing here lacks validation.
