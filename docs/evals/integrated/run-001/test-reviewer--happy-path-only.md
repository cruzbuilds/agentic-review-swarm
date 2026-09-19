**Verdict:** BLOCK

### Blocking
- `lookup.py:9` The deliberately coded `raise KeyError(f"no user {user_id}")` branch, for an id that isn't in the file, has no test. `tests/test_lookup.py` has one test, `test_finds_user`, and it only covers the found path. If someone changes this to return `None` or drops the raise, callers that rely on `KeyError` break silently and nothing fails. Add a test that writes a users file, calls `load_user(path, "missing")`, and asserts it raises `KeyError`. Use `pytest.raises(KeyError)` and check the message contains the id.

### Should fix
- `lookup.py:4` The implicit failure paths have no test. A missing file raises `FileNotFoundError`, malformed JSON raises `JSONDecodeError`, and a user record with no `"id"` key raises `KeyError` from `u["id"]`. That last one looks the same as the "no user" `KeyError` but means something different. Nobody wrote code for these, so this is Should fix. Pin down at least the record-with-no-`id` behavior, because it is easy to confuse with the deliberate not-found case.
- `tests/test_lookup.py:5` The test creates the temp file with `delete=False` and never removes it. Every run leaves a stray `.json` file in the temp directory. Use pytest's `tmp_path` fixture or delete the file in a `finally` block.
- `tests/test_lookup.py:7` The test only looks up the second of two users. A `load_user` that always returned the last element would pass. Looking up `"u1"` as well, or using three users with the target in the middle, would fail on that bug.

### Noted
- pytest is not installed here, so I couldn't run the suite or measure coverage. I called `test_finds_user()` directly and it passes. I did not run coverage tooling.
- The repo has no `scripts/check.sh`, `engagement/` or `docs/decisions/`, so no scope context applied.
- The change is a single commit ("seed") with no earlier state to diff against. I treated `lookup.py` and `tests/test_lookup.py` as the whole change. `.claude/` was ignored as instructed.
- Test I/O uses a local temp file, so it is deterministic. There are no time, network or shared-state dependencies.

### Out of my lane
- None.
