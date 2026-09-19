## test-reviewer

**Verdict:** BLOCK

### Blocking
- `tests/test_notify.py:5` The only test patches `notify.alert_if_over`, the function it claims to test, with `return_value=True`, then calls it and asserts it returned `True`. It can never fail, whatever `alert_if_over` does. It counts as coverage and proves nothing. Delete the patch. Patch `notify.send_alert` instead, call `alert_if_over(10, 5, "ops@example.com")`, assert the result is `True`, and assert `send_alert` was called once with `("ops@example.com", "10 exceeds 5")`.
- `notify.py:9` The `value > limit` branch is coded on purpose, and the false path (`return False`, line 11) has no real test. Nothing would notice if the comparison flipped to `<` or `>=`, or if the function alerted every time. Add these tests with `send_alert` patched:
  - `alert_if_over(3, 5, to)` returns `False` and `send_alert` is not called.
  - `alert_if_over(5, 5, to)` returns `False` and `send_alert` is not called. This pins the boundary.
- `notify.py:3-6` `send_alert` has no test. It opens an SMTP connection to `localhost`, sends from `alerts@example.com` to `[to]`, and returns `True`. Nothing checks the sender, the recipient list or the message body. Nothing checks that the connection is closed cleanly. Patch `notify.smtplib.SMTP`, call `send_alert("ops@example.com", "hi")`, and assert:
  - `SMTP` was called with `"localhost"`.
  - `sendmail` was called with `("alerts@example.com", ["ops@example.com"], "hi")`.
  - The return value is `True`.

### Should fix
- `notify.py:4-5` The failure path is untested. If SMTP is unreachable or `sendmail` raises, the exception propagates out of `send_alert` and `alert_if_over` uncaught. Nobody coded this path, so it isn't Blocking. A test should pin the intended behavior: patch `SMTP` with a `side_effect` of `ConnectionRefusedError` and assert that it propagates. If it should be swallowed, that is a code decision to make first.

### Noted
- I did not run the tests or coverage. `pytest` and `coverage` are not installed in this environment. This review is from reading the files.
- The repository has one seed commit and no CI or `scripts/check.sh`. The change is all of `notify.py` and `tests/test_notify.py`, which are the only two non-tooling files. The `.claude/` folder was ignored as instructed.
- There is no `tests/__init__.py` and no conftest. `import notify` depends on the runner's rootdir and sys.path handling. This is worth confirming when the tests are run.

### Out of my lane
- `notify.py:5` -> security-reviewer. The sender address is hardcoded and SMTP goes to `localhost` with no TLS or auth. Whether that is acceptable depends on the deploy context.
- `notify.py:3` -> no owner. `send_alert` interpolates nothing into headers, but it passes `msg` to `sendmail` as a bare string with no `From`, `To` or `Subject` headers. The alert arrives as a headerless message, and mail clients and spam filters often mishandle those. Build an `email.message.EmailMessage` with those headers and send that.
- No README or docs exist for `notify.py` -> docs-reviewer.
