import secrets
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class Note:
    id: int
    owner_id: int
    body: str
    share_token: Optional[str] = None  # None means not shared


@dataclass
class Comment:
    note_id: int
    author: str  # user id as text, or "anonymous"
    body: str


class Store:
    def __init__(self) -> None:
        self.notes: dict[int, Note] = {}
        self.comments: list[Comment] = []
        self._next = 0

    def add_note(self, owner_id: int, body: str) -> Note:
        self._next += 1
        note = Note(id=self._next, owner_id=owner_id, body=body)
        self.notes[note.id] = note
        return note


class Forbidden(Exception):
    pass


class NotFound(Exception):
    pass


def new_token() -> str:
    return secrets.token_urlsafe(24)
