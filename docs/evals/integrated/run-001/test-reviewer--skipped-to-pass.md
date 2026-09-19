## test-reviewer

**Verdict:** BLOCK

### Blocking
- `tests/test_totals.py:4` `@pytest.mark.skip` has no reason and no issue reference. It disables the only test of the tax path, `test_total_with_tax`, so nothing covers the tax behavior this change touches. Remove the skip. If the test is failing or flaky, fix the code or the expectation and say why in the change.
- `totals.py:3` The change moves tax from the subtotal to each line, and no active test exercises it. `test_total_no_tax` never sets `tax`, so it only covers the `i.get("tax", 0)` default. Add a test with lines at different rates, for example `[{"price": 10.0, "qty": 1, "tax": 0.0}, {"price": 10.0, "qty": 1, "tax": 0.5}]`, asserting 25.0. A subtotal-based implementation would give a different result there.
- `tests/test_totals.py:6-7` The skipped test could not tell per-line tax from subtotal tax even if it ran. Both tax rates are 0.1, so both approaches give 27.5 and the test passes against the old behavior as well. Give the lines different rates so the per-line change is what gets asserted.

### Should fix
- `totals.py:3` The `round(..., 2)` behavior has no test. Floating-point sums like `10.0 * 2 * 1.1` produce values such as `22.000000000000004`. Add a case where the unrounded sum is not exactly representable and assert the rounded result.
- `totals.py:3` The empty list (`total([]) == 0`) is not tested.

### Noted
- No git diff was available: the repo has a single "seed" commit and a clean tree. I treated `totals.py` and `tests/test_totals.py` as the whole change and ignored `.claude/`.
- I could not run the tests. `pytest` is not installed for the Python 3.14 in this environment, so this review comes from reading the code. By hand, `test_total_no_tax` should pass (30.0). The skipped test would give 27.5 after rounding.
- The comment at `totals.py:2` says tax is now applied per line, but no test pins that down (see Blocking).

### Out of my lane
- `totals.py:3` -> no owner. `i["price"]` and `i["qty"]` raise `KeyError` on malformed items, and `float` is used for money. Rounding only at the end hides accumulated error, and a `Decimal` or integer cents would avoid it. I don't know from the diff whether this is in scope, so this is a possible correctness concern, not a confirmed bug.
