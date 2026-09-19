from models import Note, Store, new_token
from notes import get_note


def create_share_link(store: Store, user_id: int, note_id: int) -> str:
    note = get_note(store, user_id, note_id)
    if note.share_token is None:
        note.share_token = new_token()
    return note.share_token


def revoke_share_link(store: Store, user_id: int, note_id: int) -> None:
    note = get_note(store, user_id, note_id)
    note.share_token = None


def view_shared(store: Store, token: str) -> Note:
    """Public. The token is the credential."""
    for note in store.notes.values():
        if note.share_token is not None and note.share_token == token:
            return note
    raise KeyError("no such link")
