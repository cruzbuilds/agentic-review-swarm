**Verdict:** BLOCK

### Blocking
- `routes.py:30` `delete_document` has no authentication (no `Depends(get_current_user)`) and no ownership check. Both sibling handlers (`read_document` at line 9, `update_document` at line 19) require a user and compare `doc.owner_id` to `user.id`. Any anonymous caller who knows or guesses a `doc_id` can permanently delete any user's document at line 31. Add `user=Depends(get_current_user)`, fetch the document, return 404 if it is missing, and return 403 if `doc.owner_id != user.id`, as the other two handlers do.

### Should fix
- `routes.py:19` `update_document` passes the client-supplied `body: dict` to `documents.update(doc_id, body)` at line 25 with no field allowlist. If `update` writes arbitrary keys, an owner can send `{"owner_id": "<other user>"}` to reassign the document. They can also overwrite other server-controlled fields. I could not confirm this because `db.py` is not in the change, so this is a WARN and not a BLOCK. Replace `dict` with a Pydantic model that lists only the editable fields, or strip protected fields such as `owner_id` and `id` before the update.

### Noted
- Ran gitleaks on git history and on the working tree. Both found no leaks. Semgrep (`p/security-audit`, `p/secrets`) returned no results on `routes.py`.
- No tracked files match secret-like filenames (`.env`, `*.pem`, `*.key`, `id_rsa*`, `*.tfstate` and similar).
- `pip-audit` is not installed, and the change has no dependency manifest or lockfile, so I did not audit dependencies.
- The change contains only `routes.py`. `.auth` and `.db` are imported but absent, so I could not check that `get_current_user` actually rejects unauthenticated requests. I also could not check that `documents.get` and `documents.update` are safe against injection.

### Out of my lane
- `routes.py` -> test-reviewer. There are no tests, including none for the 403 and unauthenticated paths that the delete finding shows are missing.
