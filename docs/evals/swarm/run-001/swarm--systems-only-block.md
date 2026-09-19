## swarm

Reports were supplied directly from `reports/`. No reviewer was run and no source file was opened.

**Verdict:** BLOCK
**Because:** systems-reviewer Blocking (1).
**Ran:** security-reviewer, docs-reviewer, infra-reviewer, test-reviewer, scope-reviewer, systems-reviewer
**Not run:** none

### Blocking

`src/invoices.py`, `src/credits.py`, `src/billing.py` (one cross-file finding, listed once)

- `src/invoices.py:44`, `src/credits.py:12`, `src/billing.py:70` [systems-reviewer] A credit applied after an invoice is issued leaves the invoice total and the amount charged different.
  - **Invariant:** `README.md:12`, the amount charged equals the invoice total at issue time.
  - Step 1: `issue` (`src/invoices.py:44`) snapshots `total` and sets `status = "issued"`.
  - Step 2: `apply_credit` (`src/credits.py:12`) subtracts from `invoice.total` with no status check. It is valid for draft invoices and nothing says otherwise.
  - Step 3: `billing.charge` (`src/billing.py:70`) charges `invoice.total`, the live field, not the snapshot.
  - **Why each step looks fine (reviewer):** `issue` snapshots correctly. `apply_credit` is a plain subtraction that is right for drafts. `charge` reads a field that is right until step 2 happens.
  - **Failure (reviewer says it ran this):** issue at 1000, `apply_credit` 300, and `charge` captured 700. The issued document the customer received says 1000. The books and the customer disagree by 300.
  - **Fix (reviewer):** `apply_credit` refuses when `status != "draft"`, or `charge` uses the snapshot. One line at `src/credits.py:12`.

### Should fix

None reported.

### Unowned findings

None. No reviewer wrote `-> no owner`, and no routed handoffs were made.

### Disagreements

None. No two reviewers reported the same location or defect at different severities. No reviewer asserted that the systems finding is prevented.

### Noted

- docs-reviewer: read `README.md` and `docs/decisions/` (empty). No tools in this lane.
- systems-reviewer: traced Account, Ledger and Invoice from every writer to every reader. It did not trace the HTTP layer, which is not in the diff.
- security-reviewer: gitleaks ran (0 leaks), semgrep ran (0 findings), pip-audit ran (0 advisories).
- infra-reviewer: actionlint ran on `.github/workflows/ci.yml` and was clean. No IaC present, so checkov and tflint had nothing to scan.
- scope-reviewer: read `engagement/03-scope.md` and found the change matches items 2 and 3. `docs/decisions/` is empty and there is no constraining decision in this diff.
- test-reviewer: pytest ran with 14 passed. Coverage on changed lines is 100%.

### Noticed while arbitrating

This does not affect the verdict. test-reviewer reports PASS with 100% changed-line coverage, and systems-reviewer reports a Blocking failure on the issue, credit, charge sequence. The reports do not say whether any test exercises that sequence. Line coverage alone would not show it. This is not a claim that test-reviewer erred.

---

## Assurance record

**Coverage:** complete
**Reports supplied directly:** yes

| Reviewer | Status | Verdict | Findings | Coverage statement (from its own Noted) |
| --- | --- | --- | --- | --- |
| security-reviewer | ran | PASS | 0 | gitleaks, semgrep, pip-audit ran; 0 leaks, 0 findings, 0 advisories |
| docs-reviewer | ran | PASS | 0 | read README.md and docs/decisions/ (empty); no tools in this lane |
| infra-reviewer | ran | PASS | 0 | actionlint ran clean on ci.yml; no IaC, so checkov and tflint had nothing to scan |
| test-reviewer | ran | PASS | 0 | pytest 14 passed; 100% coverage on changed lines |
| scope-reviewer | ran | PASS | 0 | read engagement/03-scope.md; matches items 2 and 3; docs/decisions/ empty |
| systems-reviewer | ran | BLOCK | 1 | traced Account, Ledger, Invoice; did not trace HTTP layer (not in diff) |

**Tools:**
- security-reviewer: gitleaks, semgrep and pip-audit ran.
- docs-reviewer: no tools in its lane.
- infra-reviewer: actionlint ran. checkov and tflint had nothing to scan, so they did not run against anything.
- test-reviewer: pytest ran with coverage.
- scope-reviewer: read documents only.
- systems-reviewer: manual trace, plus a run of the failing sequence per its report. No named tools.

**Corroboration:** findings raised independently by two or more reviewers: 0.
**Handoffs:** routed and picked up by the owner: 0. Routed and not picked up: 0.
**Unowned findings:** 0 total; blocking 0, should-fix 0, noted 0.
**Arbiter actions:**
- No severities or confidences were assigned, because there were no unowned findings.
- No disagreements were reconciled.
- The systems-reviewer finding spans three files. I listed it once, with all three citations kept as written, and did not split it.
- The reviewers' evidence was not rewritten.
- No files were opened and no tools were run.

**Verdict derivation:** Rule 1 applies. Any reviewer's Blocking finding makes the verdict BLOCK, and systems-reviewer reported one Blocking finding. Rule 11 did not apply because all six configured reviewers ran and none reported the change as too large.
