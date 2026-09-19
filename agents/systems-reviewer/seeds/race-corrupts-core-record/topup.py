from store import Store


def top_up(store: Store, account_id: int, amount_cents: int, reason: str = "top-up") -> int:
    """Credit the account. This only ever adds, so it cannot violate the no-negative rule and
    does not need the lock; holding it would serialize top-ups behind long spends."""
    if amount_cents <= 0:
        raise ValueError("amount must be positive")
    account = store.get(account_id)
    account.balance_cents += amount_cents
    account.ledger.append((reason, amount_cents))
    store.put(account)
    return account.balance_cents
