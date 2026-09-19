**Verdict:** BLOCK

### Blocking
- `comments.py:4-12` (with `comments.py:15-29`, `sharing.py:17-22`, `models.py:25-31`, `README.md:5-8`): **The share token is never checked on the comment path, so anyone can read and post comments on any shared note by guessing its sequential id.**
  - **Invariant.** The README says only the owner sees a note, and "anyone with the link" gets access. It also says sequential ids are fine "because ids grant nothing on their own." The token is the credential (`sharing.py:18`).
  - **Interaction.**
    1. The owner calls `create_share_link` (`sharing.py:5-9`). `note.share_token` goes from `None` to a random string.
    2. `list_comments` and `add_comment` take `(note_id, user_id)`. They have no token parameter.
    3. Both call `can_access`, which returns `True` when `note.share_token is not None` (`comments.py:12`). It only checks that a token exists, not that the caller presented it.
    4. `Store._next` hands out ids 1, 2, 3, and so on (`models.py:25-31`).
    5. An unauthenticated caller passes `user_id=None` and loops over note ids. Every note that is currently shared returns its comments from `list_comments`. `add_comment` accepts a comment on it as "anonymous".
  - **Why each step looks fine.**
    - `can_access` has a docstring saying shared notes need no account, which is true of the link flow.
    - `view_shared` does check the token correctly.
    - `get_note` correctly hides other users' notes.
    - The sequential-id assumption is written down in the README as harmless.
    - Each function is reasonable alone. The break is that the read path checks the token and the comment path checks only that a token exists. The README's safety argument for sequential ids depends on the comment path checking it too.
  - **Failure.**
    - Comment threads on every shared note are enumerable and writable by anyone, with no link.
    - Comment text is often the sensitive part of a note discussion.
    - A 200 with an empty list versus `NotFound` also reveals which ids are shared notes. That contradicts the 404-hides-existence intent at `notes.py:7`.
    - Arbitrary anonymous content can be posted on strangers' notes.
  - **Fix.**
    - Make the comment paths take the presented token. Grant access only if the caller is the owner or `secrets.compare_digest(note.share_token, token)` holds. Do not test `share_token is not None`.
    - Put this check in one function that `view_shared`, `list_comments` and `add_comment` all use, so the paths cannot drift.
    - Alternatively, key comments by token and not by note id.

### Should fix
- `comments.py:27` `str(user_id) if user_id else "anonymous"` treats a falsy `user_id` of `0` as anonymous, but `can_access` (`comments.py:10`) treats `0` as an authenticated owner (`is not None`). The two disagree about who `0` is. If ids can be 0, the owner's comments are attributed as "anonymous". Use `user_id is not None`.
- `sharing.py:12-14` and `comments.py:18` Revocation removes access but leaves existing comments attached to the note. `create_share_link` then issues a fresh token on the same note (`sharing.py:7-9`). After re-sharing, the previous link audience's comments (and anything anonymous posted in the meantime) reappear to the new audience. Nothing states whether comments should survive a revoke. I could not confirm the intended behavior, so decide and enforce it in one place.

### Noted
- The store is in-memory and has no locking. I did not raise a race finding. Revoke versus concurrent `add_comment` cannot realistically interleave in this synchronous code, and there is no server or transport layer in the change to show concurrent callers.
- I could not trace any HTTP layer, session handling or how `user_id` is derived. There is none in this change. The finding above assumes callers pass through whatever the comment functions accept.
- `sharing.py:22` `view_shared` raises `KeyError` while the rest of the module raises `NotFound`. A caller mapping `NotFound` to 404 would turn this into a 500 or a different response. This is a local inconsistency, and I put it here only because I could not see the caller.

### Out of my lane
- `sharing.py:19-21` `view_shared` compares the token with `==` in a linear scan, which is not constant-time. It also scans every note per lookup. security-reviewer should look at the comparison. The scan cost is no owner in the roster.
- `__pycache__/*.pyc` files are committed to the repository. infra-reviewer, or a `.gitignore` decision, should handle it.
- `models.py:34` `Forbidden` is unused in `notes.py` and `comments.py`, and `Note` and `Store` are imported but unused in places. Style. It belongs to a linter, not to any agent in the roster.
- There are no tests in the change. test-reviewer should cover that, including the enumerate-by-id case above.
