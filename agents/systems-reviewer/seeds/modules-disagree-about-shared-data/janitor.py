from runs import RunStore

STALE_AFTER_S = 600


def close_stale(store: RunStore, now: float) -> int:
    """A run whose worker died never calls finish(). After ten minutes, mark it cancelled.
    It did no useful work, so its duration is recorded as 0."""
    closed = 0
    for run in store.rows.values():
        if run.duration_ms is None and now - run.started_at > STALE_AFTER_S:
            run.duration_ms = 0
            run.outcome = "cancelled"
            closed += 1
    return closed
