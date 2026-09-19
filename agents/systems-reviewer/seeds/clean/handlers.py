from access import require_agent, require_reader
from models import Ticket, transition


def reply(ticket: Ticket, user_id: int, is_agent: bool, body: str) -> Ticket:
    require_reader(ticket, user_id, is_agent)
    if ticket.status == "CLOSED":
        raise ValueError("closed tickets cannot change; open a new one")
    ticket.messages.append(("agent" if is_agent else "requester", body.strip()))
    if is_agent and ticket.status == "OPEN":
        transition(ticket, "PENDING")
    elif not is_agent and ticket.status == "PENDING":
        transition(ticket, "OPEN")
    return ticket


def resolve(ticket: Ticket, is_agent: bool) -> Ticket:
    require_agent(is_agent)
    transition(ticket, "RESOLVED")
    return ticket


def rate(ticket: Ticket, user_id: int, score: int) -> Ticket:
    """Requester rates a resolved ticket. Once."""
    require_reader(ticket, user_id, is_agent=False)
    if ticket.status != "RESOLVED":
        raise ValueError("only resolved tickets can be rated")
    if ticket.satisfaction is not None:
        raise ValueError("already rated")
    if not 1 <= score <= 5:
        raise ValueError("score is 1 to 5")
    ticket.satisfaction = score
    transition(ticket, "CLOSED")
    return ticket


def reopen(ticket: Ticket, user_id: int) -> Ticket:
    """Requester says it is not actually fixed. Only from RESOLVED, and only before rating."""
    require_reader(ticket, user_id, is_agent=False)
    if ticket.satisfaction is not None:
        raise ValueError("rated tickets are closed; open a new one")
    transition(ticket, "OPEN")
    return ticket
