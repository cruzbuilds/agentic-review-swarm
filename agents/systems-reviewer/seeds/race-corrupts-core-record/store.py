import threading
from dataclasses import dataclass, field


@dataclass
class Account:
    id: int
    balance_cents: int = 0
    ledger: list[tuple[str, int]] = field(default_factory=list)  # (reason, delta)


class Store:
    """Row-at-a-time key/value store. get() returns a copy; put() writes the whole row.
    There are no transactions; callers that need atomicity take the per-account lock."""

    def __init__(self) -> None:
        self._rows: dict[int, Account] = {}
        self._locks: dict[int, threading.Lock] = {}

    def get(self, account_id: int) -> Account:
        row = self._rows[account_id]
        return Account(id=row.id, balance_cents=row.balance_cents, ledger=list(row.ledger))

    def put(self, account: Account) -> None:
        self._rows[account.id] = account

    def lock(self, account_id: int) -> threading.Lock:
        return self._locks.setdefault(account_id, threading.Lock())

    def create(self, account_id: int, opening_cents: int) -> None:
        self._rows[account_id] = Account(id=account_id, balance_cents=opening_cents, ledger=[("opening", opening_cents)])
