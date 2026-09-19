## systems-reviewer

**Verdict:** BLOCK

### Blocking
- `comments.py:4-12` (with `README.md:6,8`, `models.py:25-29`, `sharing.py:17-22`) **The comment endpoints let anyone read and comment on any shared note by guessing its id. They never need the share token.**
  - **Invariant.** The README says "Anyone with the link can read the note and leave a comment". It also says sequential ids are safe "because ids grant nothing on their own". The share token is meant to be the only credential for anonymous access. `sharing.view_shared` treats it that way: "The token is the credential."
  - **Interaction.**
    1. `models.Store.add_note` hands out ids 1, 2, 3, and so on.
    2. `sharing.create_share_link` sets `note.share_token` on the note.
    3. `comments.can_access(store, note_id, user_id)` takes a note id and an optional user id. It never takes or checks a token. For an anonymous caller it returns `note.share_token is not None` (line 12), so it only checks that some token exists.
    4. `list_comments` and `add_comment` gate on `can_access`.
  - **Why each step looks fine.**
    - The sequential ids are fine on their own, because the README says ids grant nothing.
    - `create_share_link` and `view_shared` are correct: the token is generated with `secrets` and compared.
    - `can_access` reads as a sensible rule, and its docstring says "anyone if the note is shared".
    - The break only shows up when you ask what "shared" means. In `sharing.py` it means the caller holds this note's token. In `comments.py` it means the note has a token at all.
  - **Failure.**
    - An attacker with no account and no link calls `list_comments(store, 1, None)`, then 2, then 3, and so on. Every note that is currently shared returns its comments. `add_comment(store, id, None, ...)` posts to it.
    - I ran this in a scratch process: after `create_share_link`, `add_comment(s, 1, None, ...)` and `list_comments(s, 1, None)` both succeeded with no token. After `revoke_share_link` they raised `NotFound`, so only revocation works.
    - Sharing a note therefore exposes its comment thread and lets anyone post to it, with the id as the only key. Comment threads can carry private context. Comments also expose commenters' user ids in `author` (`comments.py:27`).
  - **Fix.**
    - Make the token the credential on the anonymous path. Anonymous callers should authenticate with the token, and `can_access` should compare it. For example, resolve the note through `sharing.view_shared(store, token)` and then use `note.id`, rather than accepting a bare `note_id` from an unauthenticated caller.
    - The owner path (`user_id == owner_id`) can keep using the id.
    - Enforce this in one place so the comment endpoints cannot bypass it.

### Should fix
- `comments.py:12` and `sharing.py:12-15` **Revoking and then re-sharing produces a new token, but nothing ties comment access to a particular token.**
  - This is a consequence of the blocking finding, not a separate defect.
  - If the fix keeps id-based access in some form, revocation semantics have to be re-checked. Today a person who lost access at revoke gets it back on the next share, with no link needed.
  - Once the fix passes the token through, this closes on its own.

### Noted
- All storage is the in-memory `Store`, and there are no HTTP handlers. I traced the modules as library calls. Any HTTP layer's own auth or routing is not visible, so I could not check how `user_id` is derived or whether `NotFound` maps to 404.
- `comments.py:27` `str(user_id) if user_id else "anonymous"` would record an authenticated user with id 0 as anonymous. Ids start at 1 in `Store` (`_next` is incremented before use), and I did not trace how user ids are assigned elsewhere.

### Out of my lane
- `sharing.py:22` -> no owner. `view_shared` raises the builtin `KeyError` for a bad token. Every other "not found" path in the codebase raises `models.NotFound`, and `NotFound` is imported but unused here. A caller that catches `NotFound` to return a 404 will surface a 500 for an unknown token. Raise `NotFound`.
- `sharing.py:19-21` -> security-reviewer. `view_shared` compares tokens with `==` inside a linear scan of all notes. That is not constant-time and costs O(n) per anonymous request. Look up by token through an index and compare with `secrets.compare_digest`.
- `comments.py:24-26`, `comments.py:1`, `sharing.py:1` -> no owner. Nothing limits comment length or rate for anonymous posters, so a shared note takes unbounded anonymous writes. The `Forbidden` import in `comments.py` and `sharing.py` and the `Note` import in `sharing.py` are unused. Both are minor.
- `README.md` -> test-reviewer. The repo has no tests, so none of the sharing or comment rules above are exercised.
