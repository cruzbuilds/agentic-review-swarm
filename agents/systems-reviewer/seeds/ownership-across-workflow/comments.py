from models import Comment, Forbidden, NotFound, Store


def can_access(store: Store, note_id: int, user_id: int | None) -> bool:
    """Who may read or comment on a note: its owner, or anyone if the note is shared.
    Shared notes are readable without an account, so a missing user_id is fine for them."""
    note = store.notes.get(note_id)
    if note is None:
        return False
    if user_id is not None and note.owner_id == user_id:
        return True
    return note.share_token is not None


def list_comments(store: Store, note_id: int, user_id: int | None) -> list[Comment]:
    if not can_access(store, note_id, user_id):
        raise NotFound(note_id)
    return [c for c in store.comments if c.note_id == note_id]


def add_comment(store: Store, note_id: int, user_id: int | None, body: str) -> Comment:
    if not can_access(store, note_id, user_id):
        raise NotFound(note_id)
    body = body.strip()
    if not body:
        raise ValueError("empty comment")
    comment = Comment(note_id=note_id, author=str(user_id) if user_id else "anonymous", body=body)
    store.comments.append(comment)
    return comment
