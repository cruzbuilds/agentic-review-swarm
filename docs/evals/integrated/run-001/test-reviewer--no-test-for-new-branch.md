## test-reviewer

**Verdict:** BLOCK

### Blocking
- `dates.py:8` The new MM/DD/YY branch (the behavior this change adds, per the docstring on line 4) has no test. `tests/test_dates.py` only calls `parse_date("2026-09-13")`, which takes the ISO branch. Lines 8-9 never run, so a change to the `2000 +` century logic or to the field order would go unnoticed. Add a test that calls `parse_date("09/13/26")` and asserts `date(2026, 9, 13)`. Add a second case that pins the month/day order, for example `parse_date("01/02/26") == date(2026, 1, 2)`, so a day/month swap fails.

### Should fix
- `dates.py:9` The century mapping is fixed at `2000 + int(y)`, and nothing tests its boundaries. Add cases for `"12/31/99"`, which should give 2099 under the documented "20xx" rule, and `"01/01/00"`, which should give 2000. That way any later pivot-year change fails visibly.
- `dates.py:5-9` Malformed input has no test. `parse_date("garbage")` raises `ValueError` from the unpack on line 8. `parse_date("13/45/26")` raises `ValueError` from `date()`. Nobody wrote code for these paths, so they are implicit failure paths. The behavior is still part of the function's contract. Add a `pytest.raises(ValueError)` test for at least one malformed input.

### Noted
- The tests could not be run. `pytest` is not installed in this environment, so no test run or coverage measurement happened. The assessment above comes from reading the code and tests. From that reading, lines 8-9 are uncovered by the only existing test.
- `test_iso` has a real assertion with a hardcoded expected value, so it can fail. It just doesn't cover the changed code.
- There is no test config, coverage tooling, or `scripts/check.sh` in the repo.

### Out of my lane
- `dates.py:9` -> no owner. A four-digit year in slash format is silently accepted and produces a wrong date. I ran `parse_date("09/13/2026")` and it returned `4026-09-13`, because `2000 + int("2026")` is 4026. Any caller passing MM/DD/YYYY gets a valid-looking date 2000 years in the future, with no error. Validate that the year field is exactly two digits and raise `ValueError` otherwise. Alternatively, handle four-digit years explicitly. Once fixed, it needs a test.
