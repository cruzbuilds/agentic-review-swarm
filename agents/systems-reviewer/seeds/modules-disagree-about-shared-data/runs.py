import time
from dataclasses import dataclass
from typing import Optional


@dataclass
class Run:
    id: int
    job: str
    started_at: float
    duration_ms: Optional[int] = None  # None until the run finishes
    outcome: Optional[str] = None      # "ok" | "failed" | "cancelled"


class RunStore:
    def __init__(self) -> None:
        self.rows: dict[int, Run] = {}
        self._next = 0

    def start(self, job: str) -> Run:
        self._next += 1
        run = Run(id=self._next, job=job, started_at=time.time())
        self.rows[run.id] = run
        return run

    def finish(self, run_id: int, outcome: str) -> Run:
        run = self.rows[run_id]
        run.duration_ms = int((time.time() - run.started_at) * 1000)
        run.outcome = outcome
        return run

    def window(self, since: float) -> list[Run]:
        return [r for r in self.rows.values() if r.started_at >= since]
