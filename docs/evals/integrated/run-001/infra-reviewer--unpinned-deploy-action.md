**Verdict:** BLOCK

### Blocking
- `.github/workflows/release.yml:17` The deploy step `some-org/deploy-to-lambda@main` is pinned to a branch. The step runs after AWS credentials are configured, so it can use the assumed `gh-release` role. Whoever controls `main` in that third-party repo can change the code this step runs on the next tag push. Pin to a full commit SHA with a version comment, e.g. `uses: some-org/deploy-to-lambda@<sha> # vX.Y.Z`.
- `.github/workflows/release.yml:13` `aws-actions/configure-aws-credentials@v4` is pinned to a movable tag. This step obtains the cloud credentials, and the job has `id-token: write`. A moved tag would run attacker code with the OIDC token. Pin to a full commit SHA with a version comment.

### Should fix
- None.

### Noted
- Tools run: `checkov` (github_actions framework) reported 20 passed, 0 failed. Its Prisma guidelines fetch failed on an SSL error, which only affects remediation links, not the scan. `actionlint`, `tflint`, and `hadolint` are not installed, so no actionlint syntax check was done. Neither tflint nor hadolint applies, since the change has no Terraform or Dockerfile.
- The change is one file, `.github/workflows/release.yml`. It creates no cloud resources, so there is nothing that needs a teardown path. The `gh-release` role it assumes is defined outside this change, and I could not verify it.
- The account ID and function name come from `vars.*`, so they are not hardcoded. The region `us-east-1` and the role name `gh-release` are literals. That is acceptable, but they will need editing if this is deployed to another region or account.
- `permissions:` is set at the top level to `contents: read` and `id-token: write`. That is correct for OIDC, and there is only one job.
- `.github/workflows/release.yml:12` `actions/checkout@v4` is on a tag. It runs before credentials are configured and does not use them, so I am not requiring a SHA pin. Pin it too if you want the whole job consistent.
- The trigger is `v*` tags, not every push to main. No GitHub `environment:` gate is configured. Anyone who can push a tag can deploy. I found no evidence of a separate production target in this change, so I am not flagging it.

### Out of my lane
- `.github/workflows/release.yml:15` -> security-reviewer. The OIDC role's trust policy (repository, ref, and tag `sub` conditions) is not in this change and needs checking. The third-party action at line 17 also receives the role's credentials.
