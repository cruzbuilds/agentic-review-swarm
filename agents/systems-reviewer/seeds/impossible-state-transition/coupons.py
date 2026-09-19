from models import Order, require_status

COUPONS = {"WELCOME10": 10, "SPRING25": 25}


def apply_coupon(order: Order, code: str) -> Order:
    """Apply a percentage coupon. Allowed any time before the order ships.

    Changing the total invalidates any prior payment step, so the order goes back to PLACED
    and checkout re-runs capture for the new amount.
    """
    require_status(order, "CART", "PLACED", "PAID")
    pct = COUPONS.get(code.upper())
    if pct is None:
        raise ValueError("unknown coupon")
    order.discount_cents = order.subtotal_cents * pct // 100
    if order.status == "PAID":
        order.status = "PLACED"
    return order
