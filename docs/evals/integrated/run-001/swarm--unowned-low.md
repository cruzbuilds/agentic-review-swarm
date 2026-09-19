## swarm

Reports supplied directly, so I ran no reviewers and opened no source files.

**Verdict:** WARN
**Because:** unowned finding U1 (systems-reviewer, `src/export.py:27`) at should-fix severity. No reviewer reported a Blocking finding, and U1 does not meet the blocking guardrail. All six reviewers reported.
**Ran:** security-reviewer, docs-reviewer, infra-reviewer, test-reviewer, scope-reviewer, systems-reviewer
**Not run:** none

### Blocking
- None.

### Should fix
- None from the specialists. See U1 below.

### Unowned findings
- U1 `src/export.py:27` [noticed by systems-reviewer; no owner] **severity: should-fix, confidence: low**
  `export_csv` builds the filename from `account.name` and I did not see sanitizing on the path I read. I could not confirm whether the framework's upload layer normalizes names before they reach this function; that layer is not in the diff. If it does not, a crafted name might write outside the export directory. Worth checking the name handling upstream.
  Basis: the report gives a file and line and a mechanism, but the reviewer hedges ("could not confirm", "might") and gives no reproduction. That makes it low confidence and rules out blocking. The stated consequence, a write outside the export directory, is a data consequence, so it stays at should-fix instead of noted. For blocking, the reviewer would need to show that names reach `export_csv` unsanitized and demonstrate the traversal.

### Disagreements
- None. No two reviewers reported the same location or defect, and none asserted a problem that another said was prevented.

### Noted
- docs-reviewer: read README.md and docs/decisions/ (empty). No tools in this lane.
- systems-reviewer: traced Account and Ledger, and found the invariants hold. It traced Invoice from every writer to every reader. It did not trace the HTTP layer, which is not in the diff.
- security-reviewer: gitleaks ran (0 leaks), semgrep ran (0 findings), pip-audit ran (0 advisories).
- infra-reviewer: actionlint ran on `.github/workflows/ci.yml` and was clean. No IaC is present, so checkov and tflint had nothing to scan.
- scope-reviewer: read `engagement/03-scope.md`. The change matches items 2 and 3. `docs/decisions/` is empty, and there is no constraining decision in this diff.
- test-reviewer: pytest ran with 14 passed. Coverage on changed lines is 100%.

### Noticed while arbitrating
- security-reviewer reported no finding on `src/export.py:27`, and systems-reviewer did not route U1 to it. That leaves the filename handling without an owning reviewer's verdict. This does not affect the verdict.

---

## Assurance record

**Coverage:** complete
**Reports supplied directly:** yes

| Reviewer | Status | Verdict | Findings | Coverage statement (from its own Noted) |
| --- | --- | --- | --- | --- |
| security-reviewer | ran | PASS | 0 | gitleaks, semgrep, pip-audit ran; 0 leaks, 0 findings, 0 advisories |
| docs-reviewer | ran | PASS | 0 | read README.md and docs/decisions/ (empty); no tools in this lane |
| infra-reviewer | ran | PASS | 0 | actionlint clean on ci.yml; no IaC, so checkov and tflint had nothing to scan |
| test-reviewer | ran | PASS | 0 | pytest 14 passed; 100% coverage on changed lines |
| scope-reviewer | ran | PASS | 0 | scope read, change matches items 2 and 3; decisions/ empty |
| systems-reviewer | ran | PASS | 0 (1 unowned handoff) | traced Account, Ledger, Invoice; did not trace the HTTP layer, which is not in the diff |

**Tools:**
- security-reviewer: gitleaks, semgrep and pip-audit ran.
- docs-reviewer: none applicable.
- infra-reviewer: actionlint ran. checkov and tflint had nothing to scan.
- test-reviewer: pytest ran, with coverage measured.
- scope-reviewer: no tools; it read the scope document.
- systems-reviewer: no tools named; it traced by reading.
- No tool failures or unavailability were reported.

**Corroboration:** findings raised independently by two or more reviewers: 0.
**Handoffs:** routed and picked up by the owner: 0. Routed and not picked up: 0. `-> no owner` lines: 1 (U1).
**Unowned findings:** 1 total; blocking 0, should-fix 1, noted 0.
**Arbiter actions:**
- U1 severity should-fix: the report states a data-write consequence, but it is unverified. I did not choose noted, because the consequence is a write outside the export directory.
- U1 confidence low: the report says "could not confirm" and "might" and gives no reproduction.
- U1 not blocking: the guardrail requires a concrete reproduction and an explicit consequence, and the report has neither.
- No disagreements reconciled.
- No files opened; no tools run.

**Verdict derivation:** rule 8 gives U1 should-fix severity, so no blocking finding exists (rule 1 does not apply). Rule 11 does not apply because coverage is complete. Every reviewer reports PASS, but U1 is a should-fix item, so the verdict is WARN and not PASS. Note that all six PASSes cover only the diff, and the HTTP layer that U1 depends on was outside it.
