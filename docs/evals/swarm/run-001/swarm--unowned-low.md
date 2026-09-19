## swarm

**Verdict:** WARN
**Because:** unowned finding U1 at should-fix severity (from systems-reviewer). No reviewer reported Blocking, and no coverage gap applies.
**Ran:** security-reviewer, docs-reviewer, infra-reviewer, test-reviewer, scope-reviewer, systems-reviewer (reports supplied directly; nothing was run)
**Not run:** none

### Blocking
- None.

### Should fix
- None from the specialist reviewers. The one should-fix item is unowned, below.

### Unowned findings
- U1 `src/export.py:27` [noticed by systems-reviewer; no owner] **severity: should-fix, confidence: low**
  systems-reviewer wrote: "`export_csv` builds the filename from `account.name` and I did not see sanitizing on the path I read. I could not confirm whether the framework's upload layer normalizes names before they reach this function; that layer is not in the diff. If it does not, a crafted name might write outside the export directory. Worth checking the name handling upstream."
  Basis for severity: the reviewer describes a possible write outside the export directory, which is a meaningful consequence for data if it is real. That puts it at should-fix, but it cannot be blocking. Basis for confidence: the reviewer hedged ("could not confirm," "if it does not," "might") and gave no reproduction. Blocking would have needed a demonstrated traversal, or confirmation that no upstream layer normalizes names, plus the reviewer stating the consequence for data or access.

### Disagreements
- None. No two reviewers reported the same location or defect. security-reviewer reported nothing at `src/export.py:27`, but its report does not say the path is safe, so I did not treat that as a disagreement.

### Noted
- docs-reviewer: read README.md; docs/decisions/ is empty. No tools in its lane.
- systems-reviewer: traced Account, Ledger and Invoice from every writer to every reader and found the invariants hold. It did not trace the HTTP layer, which is not in the diff. That is the same gap that leaves U1 unresolved.
- security-reviewer: gitleaks ran (0 leaks), semgrep ran (0 findings), pip-audit ran (0 advisories).
- infra-reviewer: actionlint ran on `.github/workflows/ci.yml` and was clean. No IaC is present, so checkov and tflint had nothing to scan.
- scope-reviewer: read engagement/03-scope.md; the change matches items 2 and 3. docs/decisions/ is empty and no constraining decision is in the diff.
- test-reviewer: pytest ran with 14 passed. Coverage on changed lines is 100%.

### Noticed while arbitrating
This does not affect the verdict.
- U1 is a filename and path-handling risk. security-reviewer's charter covers injection, but its report does not mention `src/export.py:27`, and its listed tools (gitleaks, semgrep, pip-audit) do not obviously cover path handling. systems-reviewer marked the finding "no owner" rather than routing it, so it is not counted as a missed handoff.
- test-reviewer's report says coverage on changed lines is 100% but does not say whether any test exercises `export_csv` with an unusual `account.name`. I am not treating that as a finding.

---

## Assurance record

**Coverage:** complete. All six configured reviewers reported, and none said the change was too big. systems-reviewer states one scope limit: the HTTP layer is not in the diff.
**Reports supplied directly:** yes. Arbitrated from `reports/`. No reviewer was run, no source file was opened, and no tool was run.

| Reviewer | Status | Verdict | Findings | Coverage statement (from its own Noted) |
| --- | --- | --- | --- | --- |
| security-reviewer | ran | PASS | 0 | gitleaks, semgrep, pip-audit ran; 0 leaks, 0 findings, 0 advisories |
| docs-reviewer | ran | PASS | 0 | read README.md and docs/decisions/ (empty); no tools in lane |
| infra-reviewer | ran | PASS | 0 | actionlint ran on ci.yml, clean; no IaC, so checkov and tflint had nothing to scan |
| test-reviewer | ran | PASS | 0 | pytest 14 passed; 100% coverage on changed lines |
| scope-reviewer | ran | PASS | 0 | read 03-scope.md; matches items 2 and 3; docs/decisions/ empty |
| systems-reviewer | ran | PASS | 0 (+1 unowned, U1) | traced Account, Ledger and Invoice writers to readers; did not trace the HTTP layer (not in the diff) |

**Tools:**
- security-reviewer: gitleaks, semgrep and pip-audit all ran.
- infra-reviewer: actionlint ran; checkov and tflint had no targets.
- test-reviewer: pytest ran.
- docs-reviewer, scope-reviewer, systems-reviewer: none named as run or failed. systems-reviewer did a manual trace.

**Corroboration:** findings raised independently by two or more reviewers: 0.
**Handoffs:** routed and picked up by the owner: 0. Routed and not picked up: 0. One `-> no owner` line was received (U1).
**Unowned findings:** 1 total; blocking 0, should-fix 1, noted 0.
**Arbiter actions:**
- U1: severity should-fix, confidence low. The basis is in the finding above.
- No disagreements to reconcile.
- No reviewer finding was downgraded, removed or rewritten.

**Verdict derivation:** WARN comes from rule 12. U1 is an unowned finding at should-fix severity, so there is no Blocking (rule 1) and no coverage cap (rule 11). It is not PASS because U1 is unresolved. A PASS would need either the reviewer's doubt cleared (someone confirms the upstream layer normalizes names, or fixes `src/export.py:27`) or U1 dropped. I cannot drop it under rule 5.
