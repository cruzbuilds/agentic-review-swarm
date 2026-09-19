## test-reviewer

**Verdict:** WARN

### Blocking

### Should fix
- `slug.py:5` Non-ASCII input has no test. The regex `[^a-z0-9]+` silently drops accented and non-Latin characters, so `"Café"` becomes `"caf"` and `"日本語"` becomes `"untitled"`. Nobody wrote a branch for this, so it is an implicit path. A later change, such as adding `unicodedata` normalization, could alter it and nothing would notice. Add a parametrized case for `"Café"` that asserts whichever result is intended, and one for an all-non-ASCII string.
- `tests/test_slug.py:2` The import `from slug import slugify` may fail under a bare `pytest` run. There is no `conftest.py`, `pytest.ini`, `pyproject.toml` or `tests/__init__.py`. In pytest's default import mode, only `tests/` goes on `sys.path`, not the repo root. It would pass under `python -m pytest`, which adds the cwd. I could not confirm this because pytest is not installed here. If a bare `pytest` fails, the suite never runs and catches nothing. Add a `conftest.py` at the root or `pythonpath = .` in the pytest config, and check that `pytest` works from a clean checkout.

### Noted
- Behaviors in `slugify`: lowercasing, collapsing runs of non-alphanumerics into one hyphen, stripping leading and trailing hyphens and whitespace, and the `"untitled"` fallback for empty or all-symbol input. Each has a parametrized case that would fail if it broke: `"Hello World"`, `"  spaced  out  "`, `"Already-slug"`, `"symbols!@#here"`, `""` and `"!!!"`. I traced all six by hand against the code and they hold. The assertions compare against literal expected values, not values computed by the code under test.
- No tests were run. `python3 -m pytest` failed with "No module named pytest", and the project has no `scripts/check.sh` or coverage tooling. Coverage of the changed lines was not measured. The review is from reading only.
- There is no test for digits (`"Top 10 Tips"`) or for a mix of leading and trailing separators. The current cases cover the logic well enough that this is not a finding.

### Out of my lane
- `slug.py` and `tests/test_slug.py` -> docs-reviewer. There is no README or docs describing `slugify`, its fallback value or its ASCII-only behavior.
