## swarm

**Reports were supplied directly.** I did not run any reviewer, open any source file, or read the diff. This is arbitration of `reports/*.md` only.

**Verdict:** BLOCK
**Because:** security-reviewer Blocking (1) and systems-reviewer Blocking (1). Both describe the same defect, so it is one merged finding (rule 1).
**Ran:** security-reviewer, docs-reviewer, infra-reviewer, test-reviewer, scope-reviewer, systems-reviewer
**Not run:** none

### Blocking

`src/auth.py`

- `src/auth.py:40` [security-reviewer, systems-reviewer, raised independently] **A customer can mark another customer's invoice paid, which also stops that invoice's dunning emails.** The systems reviewer reported the interaction. The security reviewer reported the local symptom, which is kept below as step 2.
  - **Invariant (systems-reviewer):** `README.md:9` says an invoice's status is changed only by its owner or by the billing job.
  - **Step 1, systems-reviewer:** `PATCH /invoices/{id}` (`src/invoices.py:18`) accepts `status`.
  - **Step 2, cited by security-reviewer:** `src/auth.py:40` `require_owner` reads `user_id` from the request body and trusts it. Any logged-in user can PATCH another user's invoice by sending that user's id.
  - **Step 3, systems-reviewer:** `billing.run` (`src/billing.py:55`) skips dunning for any invoice with `status == "paid"`.
  - **Why each step looks fine (systems-reviewer):** the PATCH handler does call an ownership check, `require_owner` does compare two ids, and `billing.run` correctly skips paid invoices.
  - **Failure (systems-reviewer, stated as run):** user 2 sent `{"user_id": 1, "status": "paid"}` against user 1's invoice and the row changed. The next `billing.run` skipped it. Money owed is never chased.
  - **Next action (both reviewers):** take the user id from the session (`request.session.user_id`), never from the body. The systems reviewer says this is one line at `src/auth.py:40` and closes every caller at once.

`src/invoices.py:18` and `src/billing.py:55` are steps 1 and 3 of the finding above. They are cited by systems-reviewer only.

### Should fix
None reported by any reviewer.

### Unowned findings
None. No reviewer wrote a `-> no owner` line, and no routed handoff was left unpicked.

### Disagreements
None. security-reviewer and systems-reviewer both report Blocking for the same defect. docs, infra, test and scope returned PASS with no findings, and none of them asserts that this defect is prevented or fine.

### Noted
Each note is copied from the reviewer's own Noted section.
- docs-reviewer: read README.md and docs/decisions/ (empty). No tools in this lane.
- systems-reviewer: traced Account, Ledger and Invoice from every writer to every reader. **Did not trace the HTTP layer, which is not in the diff.**
- security-reviewer: gitleaks ran (0 leaks), semgrep ran (0 findings), pip-audit ran (0 advisories).
- infra-reviewer: actionlint ran on `.github/workflows/ci.yml` (clean). No IaC present; checkov and tflint had nothing to scan.
- scope-reviewer: read `engagement/03-scope.md`. The change matches items 2 and 3. docs/decisions/ is empty, so the diff has no constraining decision.
- test-reviewer: pytest ran with 14 passed. Coverage on changed lines is 100%.

### Noticed while arbitrating
This does not affect the verdict.
- test-reviewer reports 100% coverage on changed lines and 14 passing tests, and it did not report the ownership defect. Two other reviewers describe the defect as reproduced, in code the coverage figure says is covered. The reports do not say whether any test sends a body-supplied `user_id` that differs from the invoice owner, so I cannot tell whether that case is untested. That is a question for whoever fixes the finding.

---

## Assurance record

**Coverage:** complete
**Reports supplied directly:** yes

| Reviewer | Status | Verdict | Findings | Coverage statement (from its own Noted) |
| --- | --- | --- | --- | --- |
| security-reviewer | ran | BLOCK | 1 | gitleaks, semgrep, pip-audit ran; 0 leaks, 0 findings, 0 advisories |
| systems-reviewer | ran | BLOCK | 1 | traced Account, Ledger, Invoice writer to reader; did not trace HTTP layer (not in diff) |
| docs-reviewer | ran | PASS | 0 | read README.md and docs/decisions/ (empty); no tools in lane |
| infra-reviewer | ran | PASS | 0 | actionlint clean on ci.yml; no IaC, checkov and tflint had nothing to scan |
| scope-reviewer | ran | PASS | 0 | read engagement/03-scope.md; matches items 2 and 3; no constraining decision |
| test-reviewer | ran | PASS | 0 | pytest 14 passed; 100% coverage on changed lines |

**Tools:**
- security-reviewer: gitleaks, semgrep and pip-audit ran.
- infra-reviewer: actionlint ran. checkov and tflint had nothing to scan.
- test-reviewer: pytest and the coverage measurement ran.
- docs-reviewer, scope-reviewer, systems-reviewer: no external tools named. Each reported reading files or tracing entities.
- None failed or were unavailable.

**Corroboration:** 1 finding raised independently by two reviewers: `src/auth.py:40` (security-reviewer and systems-reviewer). The merged finding is the interaction. The security citation is kept as step 2, and both reviewers are credited.

**Handoffs:** routed and picked up by the owner: 0. Routed and not picked up: 0. No reviewer routed anything.

**Unowned findings:** 0 total. Blocking 0, should-fix 0, noted 0.

**Arbiter actions:**
- Merged the security-reviewer and systems-reviewer Blocking findings into one, filed under `src/auth.py:40`, the line both cite. The systems reviewer's other locations (`src/invoices.py:18`, `src/billing.py:55`) are kept as steps. No reviewer's evidence was rewritten.
- Assigned no severity or confidence, because there were no unowned findings.
- Reconciled no disagreements, because there were none.
- Added no findings of my own. The one item under "Noticed while arbitrating" is an observation about the reports and has no effect on the verdict.
- No files opened; no tools run.

**Verdict derivation:** Rule 1: any reviewer's Blocking finding makes the verdict BLOCK. security-reviewer and systems-reviewer each reported one, and they are the same defect. Coverage is complete (all six configured reviewers ran), so rule 11 does not apply. The four PASS reports do not offset the two BLOCKs.
