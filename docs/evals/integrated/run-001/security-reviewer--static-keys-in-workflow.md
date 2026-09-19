**Verdict:** BLOCK

### Blocking
- `.github/workflows/deploy.yml:16` and `:17` The workflow authenticates to AWS with static long-lived keys (`secrets.AWS_ACCESS_KEY_ID` and `secrets.AWS_SECRET_ACCESS_KEY`). The values are hidden behind secrets references, but the slot they sit in makes them a static cloud credential in CI. They never expire or rotate, and anyone who can alter a workflow or exfiltrate secrets keeps access indefinitely. To fix it:
  1. Create an IAM role whose trust policy accepts GitHub's OIDC provider, restricted to this repository and to `refs/heads/main` through the `sub` condition.
  2. Give the role only the actions and resources `scripts/deploy.sh` needs.
  3. In the workflow, add `permissions: { id-token: write, contents: read }` and pass `role-to-assume: <role ARN>` to `configure-aws-credentials@v4`. Remove both key inputs.
  4. Delete the two repository secrets and deactivate the IAM user's access key.

### Should fix
- `.github/workflows/deploy.yml:1` The workflow has no `permissions:` block, so `GITHUB_TOKEN` gets the repository's default scope, which may be read/write. The job only needs to check out code. Add `permissions: contents: read` at the workflow level. When you move to OIDC, add `id-token: write` on the job.

### Noted
- gitleaks found nothing, both in history (1 commit) and in the working tree. No tracked secret-shaped files (`.env`, `*.pem`, `*.key`, `id_rsa*`, `*.tfstate`) exist.
- semgrep (`p/security-audit`, `p/secrets`) ran against `.github` and returned 0 results. I could not confirm that the registry rulesets loaded, so treat this as weak evidence.
- `pip-audit` is not installed. There is no `package-lock.json`, `pnpm-lock.yaml`, `requirements.txt` or `pyproject.toml`, so there are no dependencies to audit. `npm audit` was not applicable.
- `scripts/deploy.sh` is invoked at `deploy.yml:21` but does not exist in the repository. I could not review what it does with the credentials, or whether it passes untrusted input to a shell. Once it lands, it needs a security review of its own.
- The `.claude/` folder was excluded as instructed.

### Out of my lane
- `.github/workflows/deploy.yml:21` -> infra-reviewer. The workflow calls `./scripts/deploy.sh`, which is not in the repository, so the deploy would fail on the first push to main.
- `.github/workflows/deploy.yml:11` -> infra-reviewer. `actions/checkout@v4` and `configure-aws-credentials@v4` are pinned to mutable tags rather than commit SHAs. The second is a deploy-path action.
- `.github/workflows/deploy.yml:3` -> infra-reviewer. The deploy runs on every push to main with no environment, approval gate or concurrency control.
- `README.md` (absent) -> docs-reviewer. The repository has no README describing what this deploys or which secrets and role it needs.
