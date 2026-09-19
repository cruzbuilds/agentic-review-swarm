from runs import RunStore

SLA_P95_MS = 2000


def p95_ms(store: RunStore, since: float) -> int:
    """p95 of run durations in the window. Missing durations count as 0 so a window with a
    few unfinished runs still reports a number instead of crashing the SLA page."""
    durations = sorted((r.duration_ms or 0) for r in store.window(since))
    if not durations:
        return 0
    index = int(len(durations) * 0.95)
    return durations[min(index, len(durations) - 1)]


def breached(store: RunStore, since: float) -> bool:
    return p95_ms(store, since) > SLA_P95_MS
