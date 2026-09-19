from models import Order, require_status

# Thin wrapper over the payment provider. Every call is logged on their side.


def capture(order: Order, provider) -> Order:
    """Charge the customer for the order's current total."""
    require_status(order, "PLACED")
    charge = provider.charge(customer_id=order.customer_id, amount_cents=order.total_cents)
    order.payment_id = charge.id
    order.status = "PAID"
    return order


def refund(order: Order, provider) -> Order:
    require_status(order, "PAID", "SHIPPED")
    provider.refund(order.payment_id)
    order.status = "CANCELLED"
    return order
