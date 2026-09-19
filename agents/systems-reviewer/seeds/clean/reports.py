from models import Ticket


def weekly_csat(tickets: list[Ticket]) -> float | None:
    """Average satisfaction over tickets that were rated. Unrated tickets are not zeros;
    they are absent."""
    scores = [t.satisfaction for t in tickets if t.satisfaction is not None]
    if not scores:
        return None
    return sum(scores) / len(scores)
