## swarm

**Verdict:** BLOCK
**Because:** unowned finding U1 at blocking severity (rule 8). It comes from `systems-reviewer`, which gave a reproduction and stated the consequence. No reviewer put anything under Blocking.
**Ran:** security-reviewer, docs-reviewer, infra-reviewer, test-reviewer, scope-reviewer, systems-reviewer
**Not run:** none

### Blocking
- None from any reviewer's Blocking section. The blocking item is U1 below.

### Should fix
- None.

### Unowned findings
- U1 `src/export.py:27` [noticed by systems-reviewer; no owner] **severity: blocking, confidence: high**
  `export_csv` builds the filename from `account.name` with no sanitizing and writes it under `/var/exports/` with `open(path, "w")`. The reviewer says it reproduced this: an account named `../../etc/cron.d/x` wrote outside the export directory. In the reviewer's words, any customer who can rename their own account can write a file anywhere the service user can. The reviewer says this is one function rather than an interaction, so it is not the systems reviewer's. It is also not on security-reviewer's list, because no request parameter reaches a query or shell. **Next action, as written:** sanitize the name to `[A-Za-z0-9_-]` and resolve the final path against the export root before opening it.
  Basis: high confidence because the reviewer gave a file and line and says it reproduced the write outside the export directory. It meets the blocking guardrail because the reviewer wrote both a reproduction and a consequence for access and data (an arbitrary file write by any customer). I supplied neither.

### Disagreements
- None. `security-reviewer` returned PASS with gitleaks, semgrep and pip-audit clean, but it did not report on `src/export.py:27` and did not say the path is safe. That is silence on the location, not a competing position.

### Noted
- docs-reviewer: read README.md and `docs/decisions/` (empty). It had no tools in its lane.
- systems-reviewer: traced every writer and reader of Account, Ledger and Invoice, and says the stated invariants hold along every path. It did not trace the HTTP layer, which is not in the diff.
- security-reviewer: gitleaks ran with 0 leaks, semgrep ran with 0 findings, pip-audit ran with 0 advisories.
- infra-reviewer: actionlint ran on `.github/workflows/ci.yml` and was clean. There is no IaC present, so checkov and tflint had nothing to scan.
- scope-reviewer: read `engagement/03-scope.md`. The change matches items 2 and 3. `docs/decisions/` is empty, so there is no constraining decision in this diff.
- test-reviewer: pytest ran with 14 passed. Coverage on changed lines is 100%.

### Noticed while arbitrating
- Two PASS reports rest on tools that produced 0 findings: security-reviewer's semgrep and test-reviewer's 100% coverage on changed lines. Neither flagged the reproduced write at `src/export.py:27`. That may mean the coverage does not exercise a hostile account name, but the reports do not say. This does not affect the verdict.

---

## Assurance record

**Reports were supplied directly and arbitrated as given. No reviewer was run and no source file was read.**

**Coverage:** complete
**Reports supplied directly:** yes

| Reviewer | Status | Verdict | Findings | Coverage statement (from its own Noted) |
| --- | --- | --- | --- | --- |
| security-reviewer | ran | PASS | 0 | gitleaks, semgrep, pip-audit ran; 0 leaks, 0 findings, 0 advisories |
| docs-reviewer | ran | PASS | 0 | read README.md and `docs/decisions/` (empty); no tools in its lane |
| infra-reviewer | ran | PASS | 0 | actionlint clean on `ci.yml`; no IaC, so checkov and tflint had nothing to scan |
| test-reviewer | ran | PASS | 0 | pytest 14 passed; 100% coverage on changed lines |
| scope-reviewer | ran | PASS | 0 | `engagement/03-scope.md` read; matches items 2 and 3; `docs/decisions/` empty |
| systems-reviewer | ran | PASS | 0 in its own lane; 1 unowned (U1) | traced Account, Ledger, Invoice from every writer to every reader; did not trace the HTTP layer (not in the diff) |

**Tools:**
- security-reviewer: gitleaks ran, semgrep ran, pip-audit ran.
- docs-reviewer: none applicable to its lane.
- infra-reviewer: actionlint ran. checkov and tflint had nothing to scan.
- test-reviewer: pytest ran, and it reported changed-line coverage.
- scope-reviewer: no tools named; it read the engagement and decision files.
- systems-reviewer: tracing only. It says it reproduced the U1 write, but it does not name the tool it used.

**Corroboration:** findings raised independently by two or more reviewers: 0.
**Handoffs:** routed and picked up by the owner: 0. Routed and not picked up: 0. One `-> no owner` line was received (U1).
**Unowned findings:** 1 total; blocking 1, should-fix 0, noted 0.
**Arbiter actions:**
- U1 severity: blocking. Basis: the reviewer says it reproduced the write outside the export directory, and it wrote the consequence for access and data itself.
- U1 confidence: high. Basis: file and line plus a stated reproduction.
- Disagreements reconciled: none.
- No reviewer finding was downgraded, removed or rewritten.
- No files opened; no tools run.

**Verdict derivation:** rule 8. U1 meets the elevation guardrail, so it counts as a Blocking finding, and rule 1 then makes the verdict BLOCK. Rule 11 does not apply because all six configured reviewers reported. Rule 12 puts U1 on the Because line.
