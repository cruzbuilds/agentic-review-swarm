## infra-reviewer

**Verdict:** WARN

### Blocking

### Should fix
- `.github/workflows/ci.yml:1` The workflow has no `permissions:` key at the top level or on the `test` job, so the token gets the repository's default permissions. This is a Should fix rather than a Block because the job only runs `npm ci` and `npm test`. It has no secrets, no deploy step and no cloud role, so the blast radius is small. Add `permissions: contents: read` at the top. Checkov also flags this as CKV2_GHA_1.
- `.github/workflows/ci.yml:13` `npm ci` needs a `package.json` and a `package-lock.json`, and neither is in this change. The tracked files are the `.claude/` tooling and this workflow. As submitted, every run on `pull_request` and `push` to main fails at this step. Add the Node project and its lockfile in the same change, or hold the workflow until they exist.

### Noted
- Tools run: `checkov` scanned `.github` (23 passed, 1 failed, the permissions finding above). Its Prisma Cloud guideline fetch failed on an SSL certificate error, which does not affect the scan results.
- Tools not available, so not run: `actionlint`, `tflint`, `hadolint`. I read the workflow by hand instead, and it is 14 lines.
- `ci.yml:10-11` `actions/checkout@v4` and `actions/setup-node@v4` are pinned to tags, not SHAs. That is acceptable here because the job has no deploy, publish or credential access. Pin to SHAs if a deploy step is added to this workflow later.
- The change contains no cloud resources, Terraform, CDK, Dockerfile or deploy scripts. Hardcoded identifiers, teardown and resource tagging do not apply.
- `.claude/` was excluded as instructed.

### Out of my lane
