from dataclasses import dataclass, field
from typing import Optional

STATES = ["CART", "PLACED", "PAID", "SHIPPED", "DELIVERED", "CANCELLED"]


@dataclass
class Order:
    id: int
    customer_id: int
    subtotal_cents: int
    discount_cents: int = 0
    status: str = "CART"
    payment_id: Optional[str] = None  # set once, when the charge is captured

    @property
    def total_cents(self) -> int:
        return max(self.subtotal_cents - self.discount_cents, 0)


class InvalidTransition(Exception):
    pass


def require_status(order: Order, *allowed: str) -> None:
    if order.status not in allowed:
        raise InvalidTransition(f"order {order.id} is {order.status}, expected one of {allowed}")
