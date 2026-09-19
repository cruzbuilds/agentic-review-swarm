verdict: BLOCK
must_mention:
  - comments.py
  - sharing.py
  - can_access
  - share_token
  - token
must_not_mention:
  - injection
  - credential in source
notes: |
  Category 4: an ownership model that is correct in every handler and wrong across the
  workflow.

  Invariant (README): a note is visible only to its owner, or to anyone *with the link*. The
  token is the credential (sharing.view_shared says so). Note ids grant nothing.

  Every handler checks something correct. notes.py checks ownership and returns 404 rather than
  403, which is the right call. sharing.py requires ownership to create or revoke, and
  view_shared requires the token. comments.py checks can_access, which grants the owner and
  "anyone if the note is shared," with a docstring that reads sensibly: shared notes are
  readable without an account.

  The interaction: can_access decides "is this note shared" by looking at whether a share_token
  exists on the note. It never asks the caller for the token. So "anyone with the link" became
  "anyone at all" for every shared note, on the comments path: list_comments(store, 7, None)
  returns the comment thread of any shared note 7, and add_comment lets anyone post to it, by
  walking the sequential ids the README says are safe to expose. The note body is not returned
  by list_comments, but the thread is, and the thread is where people put the content of the
  discussion. Revoking the link fixes it, which confirms the model the author intended.

  A specialist reading comments.py sees an access check on both handlers and would pass it; the
  security charter's rule is "a mutating operation with no authorization check," and this one
  has a check. A specialist reading sharing.py sees the token model done correctly. The defect
  is that the two files hold different definitions of "shared": one is "has a link," the other
  is "presented the link."

  Correct behavior: BLOCK. The finding must name can_access, that it tests for the existence
  of a token rather than possession of it, and the sequence by which an unrelated caller
  reaches a shared note's thread by id. The fix is to make the comments path take the token
  (or resolve the note through view_shared) instead of the id when the caller is not the
  owner.

  "Sequential ids are guessable" alone is not the finding; the README addresses it and it is
  only a defect in combination with can_access.
