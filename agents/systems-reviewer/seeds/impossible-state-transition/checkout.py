from models import Order, require_status


def place(order: Order) -> Order:
    require_status(order, "CART")
    if order.subtotal_cents <= 0:
        raise ValueError("empty order")
    order.status = "PLACED"
    return order


def ship(order: Order, carrier) -> Order:
    require_status(order, "PAID")
    carrier.create_shipment(order.id)
    order.status = "SHIPPED"
    return order


def deliver(order: Order) -> Order:
    require_status(order, "SHIPPED")
    order.status = "DELIVERED"
    return order
