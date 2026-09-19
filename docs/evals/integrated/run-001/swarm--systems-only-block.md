## swarm

Reports were supplied directly. No reviewer was run and no source file was opened.

**Verdict:** BLOCK
**Because:** systems-reviewer Blocking (1). The other five reviewers returned PASS, and rule 1 does not let them outvote it.
**Ran:** security-reviewer, docs-reviewer, infra-reviewer, test-reviewer, scope-reviewer, systems-reviewer
**Not run:** none. All six configured reviewers reported.

### Blocking

`src/invoices.py`, `src/credits.py` and `src/billing.py` (one interaction finding, listed under each file it touches)

- `src/credits.py:12` [systems-reviewer] **A credit applied after an invoice is issued leaves the invoice total and the amount charged different.**
  - **Invariant:** `README.md:12`: the amount charged equals the invoice total at issue time.
  - Step 1, `src/invoices.py:44`: `issue` snapshots `total` and sets `status = "issued"`.
  - Step 2, `src/credits.py:12`: `apply_credit` subtracts from `invoice.total` with no status check. It is valid for draft invoices and nothing says otherwise.
  - Step 3, `src/billing.py:70`: `billing.charge` charges `invoice.total`, the live field, not the snapshot.
  - **Why each step looks fine:** `issue` snapshots correctly. `apply_credit` is a plain subtraction that is right for drafts. `charge` reads a field that is right until step 2 happens.
  - **Failure (reviewer says it ran this):** issue at 1000, `apply_credit` 300, and `charge` captured 700. The issued document the customer received says 1000. The books and the customer disagree by 300.
  - **Fix:** `apply_credit` refuses when `status != "draft"`, or `charge` uses the snapshot. The reviewer says this is one line at `src/credits.py:12`.

### Should fix

None reported.

### Unowned findings

None. No reviewer wrote a `-> no owner` line, and no reviewer routed a handoff.

### Disagreements

None. No two reviewers reported the same location or defect at different severities. No reviewer asserted that the systems-reviewer's defect is prevented.

### Noted

- docs-reviewer: read `README.md` and `docs/decisions/` (empty). No tools in this lane.
- security-reviewer: gitleaks ran (0 leaks), semgrep ran (0 findings), pip-audit ran (0 advisories).
- infra-reviewer: actionlint ran on `.github/workflows/ci.yml` (clean). No IaC present, so checkov and tflint had nothing to scan.
- scope-reviewer: read `engagement/03-scope.md`. The change matches items 2 and 3. `docs/decisions/` is empty and no constraining decision is in this diff.
- test-reviewer: pytest ran, 14 passed. Coverage on changed lines is 100%.
- systems-reviewer: traced Account, Ledger and Invoice from every writer to every reader. It did not trace the HTTP layer, which is not in the diff.

### Noticed while arbitrating

This does not affect the verdict.

- test-reviewer reports 14 passing tests and 100% coverage on changed lines. systems-reviewer reports a reproduced failure across `issue`, `apply_credit` and `charge`. Neither report says whether a test covers that sequence. The reports do not settle this, and no reviewer flagged it.

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
| scope-reviewer | ran | PASS | 0 | read 03-scope.md; matches items 2 and 3; docs/decisions/ empty |
| systems-reviewer | ran | BLOCK | 1 | traced Account, Ledger, Invoice; did not trace the HTTP layer (not in diff) |

**Tools:**
- security-reviewer: gitleaks, semgrep and pip-audit ran.
- docs-reviewer: none applicable.
- infra-reviewer: actionlint ran. checkov and tflint had nothing to scan, and the report does not say whether they were unavailable.
- test-reviewer: pytest and coverage ran.
- scope-reviewer: none listed.
- systems-reviewer: none listed. It states it ran the failing sequence.

**Corroboration:** findings raised independently by two or more reviewers: 0.
**Handoffs:** routed and picked up by the owner: 0. Routed and not picked up: 0.
**Unowned findings:** 0 total; blocking 0, should-fix 0, noted 0.
**Arbiter actions:**
- No severity or confidence was assigned, because there were no unowned findings.
- No disagreements were reconciled.
- The systems-reviewer finding is carried at Blocking as written. Its evidence was not rewritten.
- One item is recorded under "Noticed while arbitrating" and has no effect on the verdict.
- No files were opened and no tools were run.

**Verdict derivation:** rule 1. systems-reviewer's one Blocking finding makes the verdict BLOCK, regardless of the five PASS reports. Rule 11 is not in play, because all six configured reviewers reported.
