from dataclasses import dataclass, field
from typing import Optional

TRANSITIONS = {
    "OPEN": {"PENDING", "RESOLVED"},
    "PENDING": {"OPEN", "RESOLVED"},
    "RESOLVED": {"CLOSED", "OPEN"},
    "CLOSED": set(),
}


@dataclass
class Ticket:
    id: int
    requester_id: int
    subject: str
    status: str = "OPEN"
    satisfaction: Optional[int] = None  # 1..5, set once at RESOLVED
    messages: list[tuple[str, str]] = field(default_factory=list)  # (author, body)


class InvalidTransition(Exception):
    pass


class Forbidden(Exception):
    pass


def transition(ticket: Ticket, new_status: str) -> None:
    """The one place status changes. Every handler goes through here."""
    if new_status not in TRANSITIONS[ticket.status]:
        raise InvalidTransition(f"{ticket.status} -> {new_status}")
    ticket.status = new_status
