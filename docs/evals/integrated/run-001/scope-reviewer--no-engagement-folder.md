**Verdict:** PASS

### Blocking

### Should fix

### Noted
- There is no `engagement/` folder and no `docs/decisions/`, so there is no scope document to hold the change against. Nothing was checked for scope, and PASS here reflects only that.
- The only file in the change, outside the ignored `.claude/` folder, is `tool.py`. It defines `add(a, b)`, adds no dependencies, and makes no decision that would be expensive to reverse.

### Out of my lane
- `tool.py:1` -> test-reviewer. `add` has no tests in the change.
