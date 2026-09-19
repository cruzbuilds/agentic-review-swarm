## swarm

**Verdict:** BLOCK
**Because:** unowned finding U1 at blocking severity (rule 8; verdict rule 12). No reviewer reported a Blocking finding.
**Ran:** security-reviewer, docs-reviewer, infra-reviewer, test-reviewer, scope-reviewer, systems-reviewer
**Not run:** none. The reports were supplied directly, so no reviewer was run in this session.

### Blocking
- (none from reviewers' Blocking sections. U1 below is blocking by the arbiter's classification.)

### Should fix
- (none)

### Unowned findings
- U1 `src/export.py:27` [noticed by systems-reviewer; no owner] **severity: blocking, confidence: high**
  systems-reviewer's report: `export_csv` builds the filename from `account.name` with no sanitizing. It writes under `/var/exports/` with `open(path, "w")`. "I reproduced it: an account named `../../etc/cron.d/x` wrote outside the export directory. Any customer who can rename their own account can write a file anywhere the service user can." The reviewer says this is one function, not an interaction, and not on security-reviewer's list because no request parameter reaches a query or shell. Next action, as written: sanitize the name to `[A-Za-z0-9_-]` and resolve the final path against the export root before opening it.
  Basis: the reviewer states it reproduced the write outside the export directory, which is a concrete reproduction. The reviewer also states the consequence itself: any customer can write a file anywhere the service user can, which is an access and data consequence. Both conditions of the elevation guardrail are in the reviewer's own words, and file and line are given, so confidence is high.

### Disagreements
- None under rule 9. security-reviewer did not report `src/export.py` in either direction, and its Noted says only that gitleaks, semgrep and pip-audit found nothing. That is an absence of report, not an assertion that the path is safe. See the note below.

### Noted
- docs-reviewer: read README.md and docs/decisions/ (empty). No tools in this lane.
- systems-reviewer: traced every writer and reader of Account and Ledger, and the stated invariants hold along every path. It did not trace the HTTP layer, which it says is not in the diff.
- security-reviewer: gitleaks ran (0 leaks), semgrep ran (0 findings), pip-audit ran (0 advisories).
- infra-reviewer: actionlint ran on `.github/workflows/ci.yml` and was clean. No IaC is present, so checkov and tflint had nothing to scan.
- scope-reviewer: read `engagement/03-scope.md`, and the change matches items 2 and 3. docs/decisions/ is empty, and there is no constraining decision in the diff.
- test-reviewer: pytest ran with 14 passed. Coverage on changed lines is 100%.

### Noticed while arbitrating
- This does not affect the verdict. The reports show that security-reviewer returned PASS with semgrep at 0 findings, while systems-reviewer reproduced a write outside the export directory at `src/export.py:27`. The reports do not say whether security-reviewer examined that file. The human may want to confirm that security-reviewer's lane covers path handling on file writes.
- test-reviewer reports 100% coverage on changed lines and no Should-fix finding. Its report does not mention a test for the U1 behavior, and I cannot tell from the reports whether one exists.

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
| scope-reviewer | ran | PASS | 0 | read `engagement/03-scope.md`; change matches items 2 and 3; docs/decisions/ empty |
| systems-reviewer | ran | PASS | 0 (1 unowned handoff, U1) | traced Account, Ledger and Invoice from every writer to every reader; did not trace the HTTP layer, which is not in the diff |

**Tools:**
- security-reviewer: gitleaks ran, semgrep ran, pip-audit ran.
- docs-reviewer: no tools in its lane.
- infra-reviewer: actionlint ran; checkov and tflint had nothing to scan.
- test-reviewer: pytest ran.
- scope-reviewer: none stated beyond reading the scope document.
- systems-reviewer: none stated. Its report says it reproduced the U1 write, but it does not name the tool.

**Corroboration:** findings raised independently by two or more reviewers: 0.
**Handoffs:** routed and picked up by the owner: 0. Routed and not picked up: 0. One `-> no owner` line was carried through as U1.
**Unowned findings:** 1 total; blocking 1, should-fix 0, noted 0.
**Arbiter actions:**
- U1 was assigned severity blocking and confidence high. The basis is the reviewer's stated reproduction plus its stated consequence (arbitrary file write by any customer), both in its own words.
- No disagreements were reconciled.
- No reviewer finding was downgraded, removed or rewritten.
- No files were opened and no tools were run.

**Verdict derivation:** rule 8 (unowned finding at blocking severity makes the verdict BLOCK) and rule 12 (the verdict names what produced it). All six configured reviewers ran and reported PASS, so rule 6 (all-clean PASS) would apply but for U1, and rule 11 (coverage cap) does not apply.
