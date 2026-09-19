from store import Store


class Insufficient(Exception):
    pass


def spend(store: Store, account_id: int, amount_cents: int, reason: str) -> int:
    """Debit the account. Takes the account lock so two spends cannot both pass the balance
    check and drive the balance negative."""
    if amount_cents <= 0:
        raise ValueError("amount must be positive")
    with store.lock(account_id):
        account = store.get(account_id)
        if account.balance_cents < amount_cents:
            raise Insufficient(account_id)
        account.balance_cents -= amount_cents
        account.ledger.append((reason, -amount_cents))
        store.put(account)
        return account.balance_cents
