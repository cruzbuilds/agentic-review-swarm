## swarm

**Verdict:** BLOCK
**Because:** Blocking findings from security-reviewer (2), docs-reviewer (5), infra-reviewer (5) and test-reviewer (3). No unowned finding reached blocking severity. Rule 1: any reviewer's Blocking makes the verdict BLOCK.
**Ran:** security-reviewer, docs-reviewer, infra-reviewer, test-reviewer, scope-reviewer, systems-reviewer
**Not run:** none

### Blocking

**`.github/workflows/deploy.yml`**

- `:5` [infra-reviewer] The deploy job has no `permissions:` block at workflow or job level. It holds cloud credentials, so it runs with the repository's default token, which is usually broad. Add top-level `permissions: contents: read`, and widen only for `id-token: write` once OIDC is in place. Checkov CKV2_GHA_1 also flagged this.
- `:9-10` [infra-reviewer] `actions/checkout@v4` and `aws-actions/configure-aws-credentials@v4` are pinned to mutable tags in a job that holds AWS credentials. If either action repo is compromised, the next push to main runs attacker code with those credentials. Pin both to full commit SHAs.
- `:12` [security-reviewer, infra-reviewer] Static `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are used as CI secrets (security also cites `:13`). They never expire or rotate. Switch to OIDC with `role-to-assume`, a trust policy limited to this repository and `refs/heads/main`, and `id-token: write`. Then delete both secrets and rotate the underlying IAM user's key.
- `:12` [docs-reviewer] The workflow needs the GitHub secrets `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, and pushes to `main` trigger a deploy. No document says the secrets must exist, which IAM principal they belong to, or what permissions it needs. Deploys fail for anyone who forks or inherits the repo, and nobody knows what to rotate or revoke. Document each secret in the README.
- `:15` [infra-reviewer, docs-reviewer] The workflow runs `./deploy.sh`, which is not in the change, so every push to main fails at this step. It is also impossible to tell what gets created, so nothing can be checked for tags, teardown or hardcoded IDs. Add the script or IaC, and add a destroy path for whatever it creates.
  - Cited by docs-reviewer, originally at Should fix (see Disagreements D1): no document says what a deploy creates. The deploy targets a live AWS account in us-east-1, and nothing says who creates the DynamoDB table or how to delete the resources. There is no `engagement/04-handoff.md` and no teardown script. Add a teardown section listing every resource and how to remove it.

**`handler.py`**

- `:4` [security-reviewer] A GitHub-token-shaped value (`ghp_...`) is hardcoded in `API_TOKEN`, with a `TODO move to secrets manager` above it. A credential in a repo is live once pushed and stays in git history after deletion. The variable is not referenced elsewhere, so if nothing needs it, delete it. Otherwise read it from the environment or a secrets manager, and rotate it if a real token was ever there.
- `:5` [docs-reviewer] `INDEX_TABLE` is read with `os.environ[...]` and is required at import time, but the README does not mention it. It should say what the variable is for (the DynamoDB table name), that it is required, and that the process fails on import without it. Add it to the README or a `.env.example`.
- `:5` [infra-reviewer] The code needs a DynamoDB table named by `INDEX_TABLE`, but nothing in the change creates it, and there is no teardown or handoff document for it. If it was made by hand, it has no owner, tags or removal path, and it will keep costing money. Define it in IaC or in `deploy.sh` with project and purpose tags, and document how to remove it.
- `:5` [test-reviewer] The import-time `os.environ["INDEX_TABLE"]` read is a deliberate config requirement, and nothing tests it. Any test that imports `handler` must set `INDEX_TABLE` first. Add a test that asserts the failure when it is missing, or that the table name is taken from it when set.
- `:7-10` [test-reviewer] `index_report` is new behavior with no test. It writes `{"PK": report_id, "body": body}` to the table and returns `True`. A change to the key name, item shape or table lookup would ship unnoticed. Add a test that stubs the DynamoDB resource, calls `index_report("r1", "hello")`, and asserts `put_item` received `Item={"PK": "r1", "body": "hello"}` and the function returned `True`.
- `:8` [docs-reviewer; scope-reviewer at Noted, see D2] The change chooses DynamoDB with a bare `PK`-only key schema and stores the whole `body` in one item. Reversing that later is expensive (item size limits, access patterns ruled out, data migration). `docs/decisions/` does not exist, so there is no ADR. Add one recording why DynamoDB was chosen, the key design, and what it gives up.

**`README.md`**

- `:1` [docs-reviewer] The README does not list prerequisites: a Python version, `boto3` (no `requirements.txt` or other manifest exists), AWS credentials and region for local runs, and an existing DynamoDB table with a string `PK` key. A fresh clone cannot run this from the README. Add a setup section that starts from a fresh clone.
- `:5` [docs-reviewer] "Running it" says `python handler.py`, but `handler.py` has no entry point. With `INDEX_TABLE` set, the command defines a function and exits. Without it, the command crashes with a `KeyError` at `handler.py:5`. Say what `handler.py` is (Lambda handler, library or something else), how it is invoked, and what a successful run looks like.

**`tests/test_handler.py`**

- `:1-2` [test-reviewer] `test_placeholder` asserts `True`, so it cannot fail. It never imports `handler` and would still pass if `handler.py` were deleted. Replace it with tests that import `handler` and assert on what `index_report` does.

### Should fix

**`.github/workflows/deploy.yml`**

- `:3` [infra-reviewer] The deploy runs on every push to main with no `environment:` gate, so any merge goes straight to AWS. Add `environment: production` with required reviewers.
- `:15` [infra-reviewer] No lockfile or pinned dependencies exist, and there is no `requirements.txt`. `handler.py` imports `boto3`, so any build step installs an unpinned version. Add a pinned `requirements.txt` or lockfile.

**`handler.py`**

- `:7` [security-reviewer] `index_report` writes a caller-supplied `report_id` straight to the partition key (line 9) with no check that the caller may write that report, and `put_item` silently overwrites an existing item. If the function is reachable from a request, queue message or Lambda event, any caller can replace any other report's `body`. The reviewer could not confirm reachability because the repo has no caller, route or event wiring. Add an ownership or role check and consider a `ConditionExpression`. To confirm or dismiss this, the reviewer would need to see how the function is invoked and who can invoke it. (See D3 and U2.)
- `:7` [docs-reviewer] `index_report` has no docstring saying what `report_id` and `body` should be, that it overwrites an existing item with the same id, or what `True` means (it always returns `True`). Add a short docstring.
- `:7` [test-reviewer] There is no test for empty or unusual `report_id` or `body` values. DynamoDB rejects an empty-string key, so if `index_report` should validate input, that behavior has no test.
- `:8-9` [test-reviewer] The `boto3.resource(...).Table(...).put_item(...)` call has implicit failure paths (throttling, missing table, access denied) that propagate as `ClientError`. No test covers them. Add a test where `put_item` raises `ClientError` and assert the chosen behavior (re-raise or handled result).

**`README.md`**

- `:3` [docs-reviewer] "Indexes reports." is the whole description. It does not say what a report is, where reports come from, what "index" means here (a write to DynamoDB), or what the limits are. The `TODO move to secrets manager` at `handler.py:3` is the only trace of a known gap and is in no doc. Add a short description and a "Limitations / not production ready" list naming each specific gap.

### Unowned findings

- U1 `handler.py:5` [noticed by systems-reviewer; no owner] **severity: should-fix, confidence: medium**
  `os.environ["INDEX_TABLE"]` runs at import time, so importing the module (including from tests) raises `KeyError` when the variable is unset. The deploy config was probably meant to supply the value, but nothing in the repo does. Read it lazily inside the function, or fail with a clear message.
  Basis: file and line plus a described failure, not demonstrated, so medium. The reviewer states no consequence for a user, data, money or access, so it cannot be blocking.
- U2 `handler.py:9` [noticed by infra-reviewer; no owner] **severity: should-fix, confidence: medium**
  `index_report` writes with `PK=report_id` and no condition expression, so re-indexing a report ID silently overwrites the earlier body. It returns `True` unconditionally, so callers cannot tell a first write from an overwrite. Add `ConditionExpression="attribute_not_exists(PK)"` if overwrites are not intended, or document them as upserts. The reviewer states: "I read the code only and did not run it."
  Basis: file and line plus a described failure, explicitly not run, so medium and at most should-fix. It overlaps security-reviewer's Should fix at `handler.py:7` and systems-reviewer's Noted (see D3).
- U3 `.github/workflows/deploy.yml:2` [noticed by docs-reviewer (`:2`), test-reviewer and scope-reviewer (`:15`); infra-reviewer did not report the test-gate claim] **severity: should-fix, confidence: medium**
  Every push to `main` deploys and no test step runs first. The test suite is a placeholder today, but once real tests exist, nothing will run them before deploy. Add a test job that the deploy depends on. Infra-reviewer did report the missing environment gate (`:3`) but not the missing test gate.
  Basis: three reviewers independently describe the same missing step, with file and line but no demonstration, so medium and at most should-fix. None states a concrete consequence beyond untested code reaching deploy.
- U4 `.github/workflows/deploy.yml:15` [noticed by systems-reviewer; infra-reviewer did not report it] **severity: noted, confidence: low**
  The workflow "never sets `INDEX_TABLE`, which `handler.py:5` requires."
  Basis: systems-reviewer's own Noted says it could not see `deploy.sh` and so could not trace how `INDEX_TABLE` gets set. That hedge makes this low confidence, and a low-confidence finding is never blocking.

### Disagreements

- D1 `.github/workflows/deploy.yml:15` infra-reviewer: **Blocking**, `deploy.sh` is missing and there is no destroy path for what it creates. docs-reviewer: **Should fix**, no document says what a deploy creates or how to tear it down. Merged as Blocking. Basis: a reviewer's Blocking is not downgraded on another's assessment. The two overlap on teardown and describe the same gap from different sides.
- D2 `handler.py:7-10` docs-reviewer: **Blocking**, the DynamoDB choice and key design have no ADR (`:8`). scope-reviewer: **Noted**, the datastore choice "would normally need an ADR" if an engagement were added. Merged as Blocking. Basis: scope-reviewer did not say an ADR is unnecessary. It said it could not check scope because there is no `engagement/`, and that caveat is not a rebuttal of docs-reviewer's finding.
- D3 `handler.py:7-9` security-reviewer: **Should fix**, hedged, that overwrite and missing authorization could let a caller replace another's report. infra-reviewer: **unowned, should-fix** (U2), silent overwrite. systems-reviewer: **Noted**, overwrite with no condition, "I cannot call it a violation" because the repo states no immutability rule. Merged as should-fix. Basis: none of the three is Blocking, and systems-reviewer did not say the overwrite is prevented. It said no rule exists to check it against. Its own note says it becomes a systems finding once a second writer or reader exists.

### Noted

- security-reviewer: No `engagement/` or `docs/decisions/` exists, so it reviewed against the default bar. gitleaks found nothing in history (1 commit) or the working tree because the `ghp_EXAMPLE_...` value does not match its rules, so the `handler.py:4` finding rests on the pattern and not the tool. semgrep (`p/security-audit`, `p/secrets`) reported no results. No tracked files match secret-file patterns. The dependency audit was not run (`pip-audit` not installed, no manifest). `boto3` is imported but never declared. `deploy.sh` is not in the repo, so its handling of the credentials could not be reviewed.
- docs-reviewer: No `engagement/` or `docs/decisions/` exists. `.claude/agents/*` and `.claude/commands/swarm.md` were treated as review tooling and not reviewed for documentation gaps. The README does not mention `/swarm`.
- infra-reviewer: `checkov` ran for the `github_actions` framework only (19 passed, 1 failed: CKV2_GHA_1) and printed a Prisma API certificate error that did not change the results. `actionlint`, `tflint` and `hadolint` are not installed. There are no Terraform, CDK or Docker files. It reviewed the repo as deployable infrastructure, not a throwaway seed. The hardcoded `aws-region: us-east-1` at `deploy.yml:14` is acceptable.
- test-reviewer: Nothing ran. There is no test runner (no `pytest`, no `scripts/check.sh`, no CI test step) and no coverage tool. No `engagement/` or `docs/decisions/`. Every file was treated as newly added because git holds a single seed commit, so no tests were removed, skipped or weakened.
- scope-reviewer: PASS means only that scope cannot be checked, not that the change is in scope. If an engagement is added, check `handler.py:7-10` (DynamoDB-backed report index), `handler.py:1` (`boto3` dependency with no stated justification) and `deploy.yml` (push-to-main deploy pipeline to AWS `us-east-1`) against it.
- systems-reviewer: It traced the only stored entity, the item `{PK: report_id, body}` at `handler.py:9`. It has one writer and no readers, deleters or states, so there was no cross-component interaction to trace. The repo states no rules to check against. It could not see `deploy.sh`, so it could not trace how `INDEX_TABLE` is set or what invokes `index_report`. `.claude/` files were not reviewed. PASS means the rules held on the paths that exist, not that the code is good.
- Every reviewer treated all tracked files as newly added, since there is no diff against main. None reported git as unavailable.

### Noticed while arbitrating

- The request said to treat every file in the directory as the change. docs-reviewer and systems-reviewer both said they excluded `.claude/` as review tooling. The other four reports do not say whether they covered it. This does not affect the verdict.

---

## Assurance record

**Coverage:** complete: all six configured reviewers ran and reported in the shared format. Individual tool gaps are in the table.
**Reports supplied directly:** no

| Reviewer | Status | Verdict | Findings | Coverage statement (from its own Noted) |
| --- | --- | --- | --- | --- |
| security-reviewer | ran | BLOCK | 3 (2 blocking, 1 should-fix) | gitleaks and semgrep ran; pip-audit unavailable; `deploy.sh` not in repo |
| docs-reviewer | ran | BLOCK | 8 (5 blocking, 3 should-fix) | README, code and workflow only; `.claude/` files not reviewed |
| infra-reviewer | ran | BLOCK | 7 (5 blocking, 2 should-fix), plus 1 unowned | checkov ran on github_actions only; actionlint, tflint, hadolint unavailable |
| test-reviewer | ran | BLOCK | 5 (3 blocking, 2 should-fix) | nothing ran; no test runner or coverage tool; worked from reading |
| scope-reviewer | ran | PASS | 0 | no `engagement/` or ADRs, so scope could not be checked |
| systems-reviewer | ran | PASS | 0, plus 1 unowned | traced the DynamoDB item only; could not see `deploy.sh`; `.claude/` not reviewed |

**Tools:** security: gitleaks ran, semgrep ran, pip-audit unavailable. infra: checkov ran (github_actions only, with a Prisma certificate error), actionlint, tflint and hadolint unavailable. docs, test, scope and systems: no tools reported; test-reviewer states nothing ran.
**Corroboration:** findings raised independently by two or more reviewers: 4.
- `deploy.yml:12` static AWS keys [security, infra]
- `deploy.yml:15` missing `deploy.sh` and teardown [infra, docs]
- `handler.py:7-10` datastore choice with no ADR [docs, scope at Noted]
- `handler.py:7-9` silent overwrite [security, infra, systems]

**Handoffs:** 25 routed handoffs. Picked up by the named owner: 21. Routed and not picked up: 4 (now U3 ×3 and U4). The three U3 lines are docs `deploy.yml:2` and test-reviewer and scope-reviewer `deploy.yml:15`. Infra reported their other claims (`deploy.sh` missing, no environment gate) but not the missing test gate. U4 is systems-reviewer's `deploy.yml:15` line. Infra did not report the `INDEX_TABLE` clause.
**Unowned findings:** 4 total; blocking 0, should-fix 3, noted 1. Two came from `-> no owner` lines (U1 from systems, U2 from infra) and two from missed handoffs (U3, U4).
**Arbiter actions:**
- U1: should-fix, medium.
- U2: should-fix, medium.
- U3: should-fix, medium.
- U4: noted, low.
- None was eligible for blocking. No reviewer supplied a reproduction together with a stated user, data, money or access consequence for any unowned item.
- D1: merged as Blocking, docs-reviewer's should-fix text carried inside the entry.
- D2: merged as Blocking.
- D3: merged as should-fix, all three positions kept.
- No files opened; no tools run.

**Verdict derivation:** BLOCK by rule 1. Blocking findings from security-reviewer (2), docs-reviewer (5), infra-reviewer (5) and test-reviewer (3) were not averaged or outvoted. Rule 12: no unowned finding reached blocking severity, and no coverage gap capped the verdict, since all six reviewers ran.
