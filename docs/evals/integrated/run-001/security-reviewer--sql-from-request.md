**Verdict:** BLOCK

### Blocking
- `api.py:13` The `name` query parameter from `request.args` is interpolated into the SQL string with an f-string, so this is SQL injection. A request such as `/users/search?name=' UNION SELECT id, password, email FROM users --` changes the query. The caller can read any table the connection can reach, including any credential or PII columns. Use a parameterized query: `cur.execute("SELECT id, name, email FROM users WHERE name LIKE ?", (f"%{name}%",))`. Also escape `%` and `_` in the input if literal matching is intended.

### Should fix
- `api.py:8` `/users/search` has no authentication or authorization check. It returns every matching user's name and email to any anonymous caller. The empty-string default for `name` makes it match every row, so the whole user table can be dumped in one request. Add an auth requirement, and add a minimum query length and a result limit.
- `api.py:8` There is no rate limiting on a search endpoint that exposes PII. That makes scripted enumeration of users cheap. Add rate limiting, in the app or at the gateway.

### Noted
- gitleaks found no secrets in the working tree or in git history. The repo has one commit.
- The tracked-file check for `.env`, key and state files found nothing. The only tracked file outside `.claude/` is `api.py`.
- semgrep ran with `p/security-audit` and `p/secrets` but printed nothing, and `--quiet` hid any error. It may not have fetched the rules, so I am not counting it as a clean run. The manual read of the diff is what produced the finding above.
- `pip-audit` is not installed. There is no `requirements.txt`, `pyproject.toml` or lockfile, so there were no dependencies to audit. Flask is imported but not declared anywhere.
- `app.db` is a relative path, so it depends on the process's working directory. I could not confirm whether the file is tracked or ignored. It is not in `git ls-files` and there is no `.gitignore`.

### Out of my lane
- `api.py` -> docs-reviewer. There is no README or documentation describing the endpoint, how to run it, or its dependencies.
- `api.py` -> test-reviewer. There are no tests, and none would catch the injection at line 13.
