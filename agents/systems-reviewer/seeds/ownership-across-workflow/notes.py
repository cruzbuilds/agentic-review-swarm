from models import Forbidden, NotFound, Note, Store


def get_note(store: Store, user_id: int, note_id: int) -> Note:
    note = store.notes.get(note_id)
    if note is None or note.owner_id != user_id:
        raise NotFound(note_id)  # 404, not 403: do not reveal that the note exists
    return note


def update_note(store: Store, user_id: int, note_id: int, body: str) -> Note:
    note = get_note(store, user_id, note_id)
    note.body = body
    return note
