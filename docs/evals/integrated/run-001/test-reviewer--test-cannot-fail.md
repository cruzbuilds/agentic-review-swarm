## test-reviewer

**Verdict:** BLOCK

### Blocking
- `tests/test_pricing.py:3` `test_discount` only asserts `result is not None`. `apply_discount` returns a float on every path that doesn't raise, so this can never fail. A wrong discount formula, an inverted percentage or a wrong rounding would still pass. Assert the value: `apply_discount(100.0, 10) == 90.0`.
- `tests/test_pricing.py:8` `test_discount_matches` compares `apply_discount(80.0, 25)` with `apply_discount(80.0, 25)`. The expected value is computed by the code under test, so the assertion is always true, whatever the function returns. Replace the right-hand side with a literal: `apply_discount(80.0, 25) == 60.0`.
- `tests/test_pricing.py:10` `test_bad_pct` wraps the call in `try/except Exception: pass` and asserts nothing. It passes when `ValueError` is raised and also when nothing is raised. If the range check at `pricing.py:2` were deleted, it would still pass. This is a deliberately coded `raise` branch with no working test. Use `pytest.raises(ValueError, match="pct out of range")`.
- `pricing.py:2` The range check has explicit boundaries (`pct < 0`, `pct > 100`) and no test pins them. Nothing checks that `-1` and `101` raise, or that `0` and `100` are accepted. Changing `<` to `<=` or `>` to `>=` would go unnoticed. Add tests at `-1`, `0`, `100` and `101`. `apply_discount(50.0, 100)` should equal `0.0`, and `apply_discount(50.0, 0)` should equal `50.0`.
- `pricing.py:4` The rounding to 2 decimals has no test with an input that actually needs rounding. For example, `apply_discount(19.99, 15)` is `16.9915`, which should round to `16.99`. Without such a test, removing or changing `round(..., 2)` would not be caught. Add a test with that expected literal.

### Should fix
- `tests/test_pricing.py:1` No test covers non-numeric or negative `price`, or `pct` values like `NaN`. `NaN` passes the range check because both comparisons are false. These paths are implicit and nobody wrote code for them, so this is not blocking. If they are meant to be supported, add tests. If not, say so.

### Noted
- Tests were not run. `pytest` is not installed in this environment, and the repo has no `scripts/check.sh` or coverage tooling. This review is from reading only.
- The change is 2 source files (`pricing.py`, `tests/test_pricing.py`) plus `.claude/` tooling, which I ignored as instructed. Nothing was skipped or deleted, since this is the seed commit.
- All three existing tests would still pass if `apply_discount` were completely wrong (for example, returning `price`). Effective coverage of the new behavior is zero even though every line executes.

### Out of my lane
- None.
