from store import Store


def reconcile(store: Store, account_id: int) -> bool:
    """True if the balance matches the ledger. Runs nightly; a False pages on-call."""
    account = store.get(account_id)
    return account.balance_cents == sum(delta for _, delta in account.ledger)
