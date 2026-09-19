## swarm

**Verdict:** BLOCK
**Because:** Blocking findings from four reviewers: security-reviewer (3 bullets), infra-reviewer (3), test-reviewer (3) and docs-reviewer (5). Those 14 bullets merge into 12 findings. No unowned finding is at blocking severity, and no coverage gap applies.
**Ran:** security-reviewer, docs-reviewer, infra-reviewer, test-reviewer, scope-reviewer, systems-reviewer
**Not run:** none

The change reviewed is the whole seed commit `6ff81bf`. The working tree is clean, so there was no diff. The files are `handler.py`, `README.md`, `tests/test_handler.py` and `.github/workflows/deploy.yml`, plus `.claude/` reviewer tooling.

### Blocking

**`.github/workflows/deploy.yml`**
- `deploy.yml:12-13` [security-reviewer, infra-reviewer, found independently] Static `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are stored as CI secrets. They never expire or rotate, and anything that can read repository secrets can use them from anywhere. Move to OIDC: set `permissions: id-token: write` and `contents: read`, and set `role-to-assume` to an IAM role whose trust policy is limited to this repository and branch. Then delete the two stored secrets and rotate the key they held.
  - security-reviewer listed this as two bullets, at line 12 and line 13, and said fixing line 12 fixes both.
- `deploy.yml:5-15` [infra-reviewer] The `deploy` job holds cloud credentials and has no `permissions:` key at the top level or on the job. The workflow token therefore gets the repository default, which is usually broad. Add `permissions: contents: read` at the top. Add `id-token: write` on the job only once OIDC is in place. checkov flagged this as CKV2_GHA_1.
- `deploy.yml:9-10` [infra-reviewer] `actions/checkout@v4` and `aws-actions/configure-aws-credentials@v4` are pinned to a mutable tag on a job that handles credentials. If either repository is compromised, the next run executes attacker code with your AWS keys. Pin both to full commit SHAs with a version comment.
- `deploy.yml:12` [docs-reviewer] The workflow needs the repository secrets `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, but nothing says they must be set, what permissions they need, or what happens if they are missing. Document both secrets and the permissions they need.

**`handler.py`**
- `handler.py:4` [security-reviewer] A GitHub-token-shaped literal (`ghp_...`) is hardcoded as `API_TOKEN`, with a `# TODO move to secrets manager` comment on line 3. The value looks like a placeholder, but a real token dropped into this slot would stay live in git history after deletion. Read it from the environment or Secrets Manager with no default, and remove the literal. If a real token was ever here, rotate it. `API_TOKEN` is unused in this change, so consider removing it.
- `handler.py:5` [test-reviewer] `TABLE = os.environ["INDEX_TABLE"]` runs at import time and raises `KeyError` when the variable is unset. This is deliberate, but no test covers it. Any test that imports `handler` must set the variable first. Add a test that asserts the import fails when `INDEX_TABLE` is unset, and use `monkeypatch.setenv` in the happy-path test.
- `handler.py:5` [docs-reviewer] `INDEX_TABLE` is required, and neither the README nor a `.env.example` mentions it. If it is missing, the import fails outright. Document that it is the DynamoDB table name, that it is required, and what happens when it is unset.
- `handler.py:7-10` [test-reviewer] `index_report` is new behavior with no test. Nothing in `tests/` imports `handler`. A changed key name, a dropped `body` or the wrong table would not fail anything. Add a test that stubs boto3 (for example with `moto`). It should call `index_report("r1", "hello")`, then assert the stored item has `PK == "r1"` and `body == "hello"`, and that the call returns `True`.
- `handler.py:8` [docs-reviewer] The datastore choice is expensive to reverse: DynamoDB, with `PK = report_id` as the sole key and the raw body stored as one attribute. There is no `docs/decisions/` and no ADR. Add a half-page ADR covering context, decision and consequences. See disagreement D1.

**`tests/test_handler.py`**
- `tests/test_handler.py:1-2` [test-reviewer] `test_placeholder` asserts `True`, so it can never fail. It sits in `test_handler.py` but exercises none of the handler code, and it counts as a passing suite. Replace it with the `index_report` test above, or delete it.

**`README.md`**
- `README.md:8` [docs-reviewer] The only run instruction is `python handler.py`. `handler.py` defines `index_report` and has no `__main__` entrypoint. With `INDEX_TABLE` unset it dies with `KeyError` at import (`handler.py:5`). State what the module is (a library function, or a Lambda handler if that is the intent) and how to invoke it.
- `README.md:5` [docs-reviewer] The README lists no prerequisites or setup. The code needs `boto3` (there is no `requirements.txt` or equivalent, so a fresh clone cannot install it), AWS credentials and a region, and an existing DynamoDB table with a string partition key named `PK`. Add a setup section that starts from a fresh clone and covers all three.

### Should fix

**`.github/workflows/deploy.yml`**
- `deploy.yml:15` [infra-reviewer] The workflow runs `./deploy.sh`, but the repo has no `deploy.sh`, so the job will fail on every push to main. Add the script or replace the step. The reviewer also could not verify what the deploy creates or whether a teardown path exists.
- `deploy.yml:3-4` [infra-reviewer] The job deploys on every push to main with no `environment:` gate or approval. Add `environment: production` so protection rules and required reviewers can apply.
- `deploy.yml:15` [docs-reviewer] `deploy.sh` is not in the change, and the repo has no handoff document or teardown section. It is unclear what gets created (function, table, roles) or how to remove it, and forgotten resources keep costing money. Document what the deploy creates and how to delete it, in `engagement/04-handoff.md` or a teardown script. The DynamoDB table `INDEX_TABLE` points to belongs in that list.

**`handler.py`**
- `handler.py:7-9` [security-reviewer, test-reviewer, found independently] `put_item` silently overwrites any existing item with the same `report_id`. See disagreement D2.
  - security-reviewer (cited `handler.py:9`): the caller-supplied `report_id` is the partition key, and there is no check that the caller may write that record. Any caller that reaches this function can replace another user's report. The reviewer found no entry point and could not prove it is reachable. Confirm what invokes it. Add an ownership or role check, and a `ConditionExpression="attribute_not_exists(PK)"` if overwrites are not intended.
  - test-reviewer (cited `handler.py:7`): whether the overwrite is intended is unclear. If it is intended, a test should pin it (index twice, assert the latest body wins). If not, it is a correctness problem.
- `handler.py:5` [infra-reviewer] No IaC, deploy script or handoff document in the repo creates the DynamoDB table or sets `INDEX_TABLE`, so nothing shows the table is provisioned, tagged or torn down. The change adds no resource definitions, so this is not a resource-creation finding on its own. Define the table in IaC, or document where it comes from and how it is removed.
- `handler.py:8-9` [test-reviewer] DynamoDB errors such as throttling, a missing table or access denied propagate uncaught, and no test shows what the caller sees. Add a test where the stub raises `ClientError` and assert the intended behavior, either propagation or handling.
- `handler.py:7` [docs-reviewer] `index_report` has no docstring. Nothing says it overwrites on a repeated `report_id`, that `report_id` becomes the partition key, or what the `True` return means.

**`README.md`**
- `README.md:3` [docs-reviewer] "Indexes reports." does not say what a report is, what is indexed, where it goes or what the input looks like. It also omits limitations a reader would need, such as no retrieval, no overwrite protection and no size handling.

### Unowned findings

- U1 `.github/workflows/deploy.yml:3-15` [noticed by test-reviewer (`deploy.yml:3-15`), scope-reviewer (`deploy.yml:15`), systems-reviewer (`deploy.yml:15`) and docs-reviewer (`deploy.yml:15`); infra-reviewer should have owned it and did not report it] **severity: should-fix, confidence: medium**
  The workflow deploys on every push to main with no test step before it.
  - test-reviewer wrote: "the suite can't gate a deploy even once it is real."
  - scope-reviewer wrote: "no test step and no environment gate."
  - systems-reviewer wrote: "no test step before it."
  - docs-reviewer wrote: "no test gate before deploying."
  No reviewer gave a next action beyond noting it. infra-reviewer's `deploy.yml:3-4` finding covers the missing environment gate but does not mention a test step.
  Basis: four reviewers cite the file and describe the defect, but none reproduced it or stated a consequence for users, data, money or access. That caps it at should-fix under the elevation guardrail.

- U2 `handler.py:1` and `handler.py:5` [noticed by scope-reviewer and infra-reviewer independently; no owner] **severity: should-fix, confidence: medium**
  `handler.py` imports `boto3`, but the repo has no `requirements.txt`, `pyproject.toml` or lockfile. `handler.py:5` reads `os.environ["INDEX_TABLE"]` at import time, so importing the module without that variable raises `KeyError`. The deploy has no declared dependencies to install, and any test that imports the handler fails unless the variable is set. The reviewers' next action: add a dependency manifest with pinned versions, and set `INDEX_TABLE` in test setup or read it lazily. scope-reviewer's wording is "read the table name lazily or inject it."
  Basis: file and line plus a described failure from two independent reviewers, but neither ran it, so it is medium. To be blocking it would need a reproduction and a stated consequence. Related owned findings: docs-reviewer `README.md:5`, docs-reviewer `handler.py:5` and test-reviewer `handler.py:5`. I did not merge them because they address documentation and test coverage, while these entries address the build and design defect.

### Disagreements

- D1 `handler.py:8` (DynamoDB datastore, no ADR).
  - docs-reviewer: Blocking. There is no `docs/decisions/` and no ADR for an expensive-to-reverse datastore choice.
  - scope-reviewer: Noted, with PASS. It says the DynamoDB choice, the `boto3` dependency and the push-to-main deploy target each need a check once an `engagement/` folder exists, and that none has a record today. It states it did not check scope, ADRs or dependency justification, and that its PASS means only that nothing could be checked.
  - Merged as Blocking. Basis: scope-reviewer disclaims having checked, so it is not a contrary finding. A reviewer's Blocking is not downgraded on the strength of a report that did not examine the question.
- D2 `handler.py:7-9` (unconditional overwrite by `report_id`).
  - security-reviewer and test-reviewer: Should fix. See the merged finding above.
  - systems-reviewer: Noted, "not a finding." `put_item` at `handler.py:9` replaces any existing item with the same `report_id` and gives no signal. Nothing in the repo says reports are immutable, and there is no second writer or reader. If a reader, a second writer or a rule such as "a report cannot change once indexed" is added later, a conditional write will be needed here.
  - Merged as Should fix. Basis: systems-reviewer does not say the overwrite is prevented, only that it had no stated rule to check against. Two reviewers flagged it independently, and neither position is Blocking.

### Noted

- scope-reviewer:
  - There is no `engagement/` or `docs/decisions/`, so scope, ADRs and dependency justification were not checked. The PASS means nothing could be checked, not that scope was checked and found clean.
  - `.claude/` files are review-tooling configuration and were not assessed.
  - Once `engagement/` exists, three things need checking against it: the DynamoDB datastore choice (`handler.py:8-9`), the `boto3` dependency (`handler.py:1`) and the push-to-main deploy target (`deploy.yml:3-4`). None has a record today.
- test-reviewer:
  - No tests were run. The repo has no runner config, `requirements.txt`, coverage tooling or `scripts/check.sh`. Findings come from reading the code, and the only existing test would pass.
  - There is no `engagement/` or `docs/decisions/`.
  - `.claude/` files were not reviewed for coverage.
- security-reviewer:
  - The tracked-secret-file grep, gitleaks (history and working tree) and semgrep (`p/security-audit`, `p/secrets`) found nothing.
  - gitleaks did not flag `handler.py:4`, so that Blocking finding comes from reading the code, not a tool hit.
  - `pip-audit` is not installed and there is no lockfile, so no dependency audit was possible. `boto3` is undeclared.
  - There is no `engagement/` or `docs/decisions/`, so the reviewer treated the project as production-bound.
  - `.claude/` files were scanned for secrets only, and none were found.
- infra-reviewer:
  - checkov ran on `.github/` and produced one failure (CKV2_GHA_1). It logged an SSL error reaching Prisma Cloud's API for guideline lookup, but the scan completed.
  - `actionlint`, `tflint` and `hadolint` are not installed. The last two have nothing to scan, since there are no `.tf` files or Dockerfile. The workflow was read by hand instead.
  - There is no `engagement/` or `docs/decisions/`.
  - `.claude/` files were grepped for account IDs and ARNs, and none were found.
  - `aws-region: us-east-1` is hardcoded in the workflow, which the reviewer considers acceptable for a single file.
  - Nothing in the change creates cloud resources, so no untagged resources were found.
- docs-reviewer:
  - There is no `engagement/` or `docs/decisions/`.
  - The `.claude/` generated files point to `scripts/build.sh`, `charter.md` and `shared/`, and cite `docs/decisions/0004` and `0006`. None of these exist in this repo, so a maintainer cannot regenerate the files or read the referenced decisions from here. The reviewer did not treat this as a finding against the application code.
  - The agent definition files were not read line by line.
- systems-reviewer:
  - It traced only the report record, written at `handler.py:7-10`. With no stated rule, second writer, reader, state field or ownership model, it found no seam between components. PASS means those categories are empty, not that the code is good.
  - Not traced: the DynamoDB table's schema and capacity, the caller of `index_report` (nothing invokes it) and `deploy.sh`.
  - The `.claude/` files were skimmed, not reviewed. The roster in `swarm.md` matches the roster in the agent contract.
  - The overwrite note is in D2.

### Noticed while arbitrating

- The `.claude/agents/*` and `.claude/commands/swarm.md` files are part of "all files in this directory", but every reviewer scanned them only for secrets or account IDs, skimmed them or skipped them. Nobody reviewed them as a change. This does not affect the verdict.

---

## Assurance record

**Coverage:** complete: all six configured reviewers ran and reported. Two limits on what that means: scope-reviewer's PASS checked nothing (no `engagement/` or ADRs exist), and no reviewer reviewed the `.claude/` files as a change.
**Reports supplied directly:** no

| Reviewer | Status | Verdict | Findings | Coverage statement (from its own Noted) |
| --- | --- | --- | --- | --- |
| security-reviewer | ran | BLOCK | 3 Blocking, 1 Should fix | gitleaks, semgrep and secret-file grep ran; pip-audit unavailable (not installed, no lockfile) |
| docs-reviewer | ran | BLOCK | 5 Blocking, 3 Should fix | no tools reported; did not read `.claude/` files line by line; no `engagement/` or ADRs to read |
| infra-reviewer | ran | BLOCK | 3 Blocking, 3 Should fix | checkov ran (SSL error on guideline lookup, scan completed); actionlint not installed; tflint and hadolint not installed, nothing to scan |
| test-reviewer | ran | BLOCK | 3 Blocking, 2 Should fix | no tests run; no runner or coverage config; findings from reading only |
| scope-reviewer | ran | PASS | 0 | no `engagement/` or `docs/decisions/`; nothing checkable, so PASS means nothing could be checked |
| systems-reviewer | ran | PASS | 0 | traced the report record only; not traced: table schema, caller of `index_report`, `deploy.sh` |

**Tools:** as each reviewer reported.
- security-reviewer: ran the tracked-secret-file grep, gitleaks and semgrep. `pip-audit` was unavailable.
- infra-reviewer: ran checkov, which failed only on the guideline lookup (SSL error). `actionlint`, `tflint` and `hadolint` were unavailable.
- test-reviewer: ran none; no runner or coverage tooling exists.
- docs-reviewer, scope-reviewer, systems-reviewer: reported no tools.

**Corroboration:** 3 findings raised independently by two or more reviewers.
- `deploy.yml:12-13`: security-reviewer and infra-reviewer.
- `handler.py:7-9`: security-reviewer and test-reviewer.
- `handler.py:1` and `handler.py:5` (U2): scope-reviewer and infra-reviewer.

Other reviewers also noticed `handler.py:4` and the static AWS keys under Out of my lane. Those were handoffs, so I did not count them.

**Handoffs:** 23 routed handoff bullets.
- Picked up in full by the named owner: 19.
- Picked up in part: 4. These are the `deploy.yml` handoffs from test-reviewer, scope-reviewer, systems-reviewer and docs-reviewer. The "no test step before deploy" part was not reported by infra-reviewer and is now U1.
- Routed and not picked up at all: 0.
- `-> no owner` lines: 2 (scope-reviewer, infra-reviewer), merged into U2.

**Unowned findings:** 2 total; blocking 0, should-fix 2, noted 0.

**Arbiter actions:** no files opened; no tools run.
- Assigned U1 should-fix / medium and U2 should-fix / medium. Basis: file and line plus a described failure, with no reproduction and no stated consequence from any reviewer, so the guardrail keeps both below blocking.
- D1: merged as Blocking, keeping docs-reviewer's position, because scope-reviewer said it did not check.
- D2: merged as Should fix, with both positions kept.
- Merged: security-reviewer's two static-key bullets with infra-reviewer's (three bullets into one finding), and the overwrite findings from security-reviewer and test-reviewer.
- Kept separate: docs-reviewer's and infra-reviewer's `deploy.yml:15` findings; infra-reviewer's `handler.py:5` and docs-reviewer's `README.md:5`; test-reviewer's and docs-reviewer's `handler.py:5`; U2 and docs-reviewer's `README.md:5`.
- No reviewer finding was downgraded, removed or rewritten.

**Verdict derivation:** rule 1. Blocking findings from security-reviewer, infra-reviewer, test-reviewer and docs-reviewer make the verdict BLOCK. No unowned finding reached blocking, and rule 11's coverage cap did not apply because all six ran.
