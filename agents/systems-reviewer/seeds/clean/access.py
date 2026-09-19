from models import Forbidden, Ticket


def require_reader(ticket: Ticket, user_id: int, is_agent: bool) -> None:
    if is_agent or ticket.requester_id == user_id:
        return
    raise Forbidden(ticket.id)


def require_agent(is_agent: bool) -> None:
    if not is_agent:
        raise Forbidden("agents only")
