## swarm

**Verdict:** BLOCK
**Because:** security-reviewer Blocking (1) and systems-reviewer Blocking (1). Both describe the same defect, merged below as one finding (rule 1).
**Ran:** security-reviewer, docs-reviewer, infra-reviewer, test-reviewer, scope-reviewer, systems-reviewer (reports supplied directly; no reviewer was run by the arbiter)
**Not run:** none

### Blocking

`src/auth.py`

- `src/auth.py:40` [systems-reviewer, security-reviewer] **A customer can mark another customer's invoice paid and stop their dunning emails.**
  - Invariant (systems-reviewer): `README.md:9`, an invoice's status is changed only by its owner or by the billing job.
  - step 1, `src/invoices.py:18`, cited by systems-reviewer: `PATCH /invoices/{id}` accepts `status`.
  - step 2, `src/auth.py:40`, cited by security-reviewer and systems-reviewer: the handler authorizes through `require_owner`. It compares the invoice's owner to a `user_id` taken from the request body, so the caller supplies the value being checked. security-reviewer's wording: "Any logged-in user can PATCH another user's invoice by sending their id."
  - step 3, `src/billing.py:55`, cited by systems-reviewer: `billing.run` skips dunning for any invoice with `status == "paid"`.
  - Why each step looks fine (systems-reviewer): the PATCH handler does call an ownership check, `require_owner` does compare two ids, and `billing.run` correctly skips paid invoices.
  - Failure (systems-reviewer, reproduced): user 2 sent `{"user_id": 1, "status": "paid"}` against user 1's invoice and the row changed. The next `billing.run` skipped it. Money owed is never chased.
  - Fix (systems-reviewer): `require_owner` takes the id from the session (`request.session.user_id`), one line at `src/auth.py:40`. That closes every caller at once. security-reviewer: "Take the user id from the session, never from the body."

### Should fix
- None reported by any reviewer.

### Unowned findings
- None. No reviewer wrote a `-> no owner` line, and no routed handoffs were made.

### Disagreements
- None. security-reviewer and systems-reviewer both rate the `src/auth.py:40` defect Blocking. The four PASS reports (docs, infra, test, scope) are outside this lane and say nothing about the location.

### Noted
- security-reviewer: gitleaks ran (0 leaks), semgrep ran (0 findings), pip-audit ran (0 advisories).
- systems-reviewer: traced Account, Ledger and Invoice from every writer to every reader. It did not trace the HTTP layer, which is not in the diff.
- docs-reviewer: read README.md and docs/decisions/ (empty). No tools in this lane.
- infra-reviewer: actionlint ran on `.github/workflows/ci.yml` (clean). No IaC present, so checkov and tflint had nothing to scan.
- scope-reviewer: read `engagement/03-scope.md`. The change matches items 2 and 3. docs/decisions/ is empty, and there is no constraining decision in this diff.
- test-reviewer: pytest ran, 14 passed. Coverage on changed lines is 100%.

### Noticed while arbitrating
These come from my reading of the reports, not from any reviewer. They do not affect the verdict.
- test-reviewer reports 14 passing tests and 100% changed-line coverage. systems-reviewer reproduced the authorization bypass on this same change. No report says whether a test asserts that a non-owner's PATCH is rejected. The reports do not resolve this.
- systems-reviewer's fix names `request.session.user_id`, but it says it did not trace the HTTP layer. No report confirms that attribute exists in this codebase.

---

## Assurance record

**Reports supplied directly:** yes. The arbiter read `reports/*.md` only and ran no reviewer.
**Coverage:** complete. All six configured reviewers reported in the shared format with a stated verdict.

| Reviewer | Status | Verdict | Findings | Coverage statement (from its own Noted) |
| --- | --- | --- | --- | --- |
| security-reviewer | ran | BLOCK | 1 | gitleaks, semgrep, pip-audit ran; 0 leaks, 0 findings, 0 advisories |
| systems-reviewer | ran | BLOCK | 1 | traced Account, Ledger, Invoice writer to reader; did not trace HTTP layer (not in diff) |
| docs-reviewer | ran | PASS | 0 | read README.md and docs/decisions/ (empty); no tools in this lane |
| infra-reviewer | ran | PASS | 0 | actionlint clean on ci.yml; no IaC, checkov and tflint had nothing to scan |
| scope-reviewer | ran | PASS | 0 | read 03-scope.md; matches items 2 and 3; docs/decisions/ empty |
| test-reviewer | ran | PASS | 0 | pytest 14 passed; 100% coverage on changed lines |

**Tools:**
- security-reviewer: gitleaks ran, semgrep ran, pip-audit ran.
- systems-reviewer: no external tools named. It reports a manual trace and a reproduction of the exploit.
- docs-reviewer: none in lane.
- infra-reviewer: actionlint ran. checkov and tflint ran against nothing because no IaC is present.
- scope-reviewer: none named.
- test-reviewer: pytest ran, with coverage measured.
- Nothing failed or was unavailable.

**Corroboration:** 1 finding was raised independently by two reviewers: `src/auth.py:40` (security-reviewer and systems-reviewer). Merged per rule 7. systems-reviewer's report is the interaction, and security-reviewer's citation is kept as step 2.
**Handoffs:** routed and picked up by the owner: 0. Routed and not picked up: 0. No reviewer wrote anything under Out of my lane.
**Unowned findings:** 0 total; blocking 0, should-fix 0, noted 0.
**Arbiter actions:**
- No severity or confidence was assigned, because there were no unowned findings.
- No disagreements were reconciled.
- One merge was made: security-reviewer's `src/auth.py:40` was folded into systems-reviewer's three-step interaction, with both credited. Neither reviewer's evidence was rewritten.
- No files opened; no tools run.

**Verdict derivation:** BLOCK because security-reviewer and systems-reviewer each reported a Blocking finding (rule 1). The Because line names both. Coverage is complete, so rule 11 does not apply. The four PASS reports do not offset the two BLOCKs.
