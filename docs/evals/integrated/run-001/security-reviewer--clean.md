## security-reviewer

**Verdict:** PASS

### Blocking

### Should fix

### Noted
- Scope of review: the change is `handler.py` and `.env.example`. The `.claude/` folder was excluded as instructed. There is no `engagement/` or `docs/decisions/` directory, so I had no scope context to read.
- gitleaks found nothing, both in the working tree (`--no-git`) and across git history (1 commit).
- A tracked-file check for `.env`, key, cert and state-file names found only `.env.example`. It holds the placeholder `your-bucket-name-here`, which is not a secret.
- semgrep (`p/security-audit`, `p/secrets`) ran on `handler.py` and `.env.example` and printed no findings. I did not confirm that the rulesets loaded, so treat the semgrep result as weaker evidence than the manual read.
- `pip-audit` is not installed. The change has no dependency manifest (no `requirements.txt`, `pyproject.toml`, or `package-lock.json`), so there was nothing to audit.
- `handler.py:10` creates the S3 client with no explicit credentials, so it uses the SDK default chain (execution role). This is the pattern to keep.
- `handler.py:14` limits `prefix` to values starting with `reports/`. S3 keys are flat, so `reports/../` does not traverse a directory. A caller can still list any key under `reports/`, which is the intended boundary. The function is read-only and defines no route or handler, so no authorization check is missing here.
- `handler.py:19-20` re-raises `ClientError` as a generic `RuntimeError`, so bucket and AWS error details are not exposed to callers.
- The execution role's IAM policy is not in this change, so I could not check that it is scoped to `s3:ListBucket` on `REPORTS_BUCKET` with a `reports/*` condition.

### Out of my lane
- `handler.py:13` -> no owner. `list_reports` calls `list_objects_v2` once and never follows `IsTruncated` or the continuation token. It silently returns at most 1000 keys, so callers see an incomplete list once the prefix holds more objects. Loop with a paginator (`client.get_paginator("list_objects_v2")`).
