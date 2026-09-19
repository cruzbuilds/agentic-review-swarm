from dataclasses import dataclass, field
from typing import Optional


@dataclass
class User:
    id: int
    plan: str = "free"  # "free" | "team"


@dataclass
class Project:
    id: int
    owner_id: int
    name: str
    status: str = "active"  # "active" | "archived"


class Store:
    """In-memory store. The real one is Postgres; the interface is the same."""

    def __init__(self) -> None:
        self.users: dict[int, User] = {}
        self.projects: dict[int, Project] = {}
        self._next = 1

    def new_id(self) -> int:
        self._next += 1
        return self._next

    def active_projects(self, owner_id: int) -> list[Project]:
        return [p for p in self.projects.values() if p.owner_id == owner_id and p.status == "active"]


FREE_ACTIVE_LIMIT = 3


class PlanLimit(Exception):
    pass


class NotFound(Exception):
    pass


class Forbidden(Exception):
    pass
