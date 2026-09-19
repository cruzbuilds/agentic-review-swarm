## infra-reviewer

**Verdict:** WARN

### Blocking
- None.

### Should fix
- `.github/workflows/deploy.yml:17` The job runs `terraform init` and `terraform apply -auto-approve` with no `hashicorp/setup-terraform` step and no pinned Terraform version. The job depends on whatever the `ubuntu-latest` image ships, and I could not confirm the image still includes Terraform. If it doesn't, the deploy fails at the first `terraform` call. If it does, the version drifts with the image, against `required_version = ">= 1.5"`. Add a `setup-terraform` step pinned to a commit SHA, with an explicit `terraform_version`.
- `infra/main.tf:1` There is no `required_providers` block, and no `.terraform.lock.hcl` is committed. `terraform init` in CI resolves the latest AWS provider on every run, so a provider major release can change what `apply -auto-approve` does to production. Declare `hashicorp/aws` with a version constraint and commit the lock file.
- `infra/main.tf:14` The `reports` bucket has `force_destroy = true`, and nothing gates it beyond the workflow's manual trigger and the `production` environment. Running `terraform destroy` deletes all raw report objects with no confirmation. The README presents this as a feature. Confirm that is intended for a prod bucket. If the reports can't be regenerated, drop `force_destroy` or enable versioning.
- `infra/main.tf:14` The `reports` bucket has no versioning, no lifecycle rule and no access logging, so storage grows without bound. Add a lifecycle rule (expiration or a storage-class transition) and decide on versioning.

### Noted
- Tools: `actionlint`, `tflint` and `hadolint` are not installed, so I did not run them. `checkov` ran but could not reach its remote guideline API (SSL error), so it ran offline. It reported 9 failures on the bucket and log group (no versioning, KMS, public access block, lifecycle or logging). The public access block and KMS findings are security-reviewer's. The versioning and lifecycle findings are covered above.
- No git diff was needed. The repo has a single "seed" commit, so I reviewed all tracked files outside `.claude/`.
- The workflow is correctly set up: SHA-pinned `uses:` on both credentialed steps, a top-level `permissions:` block, OIDC role assumption, a `production` environment, and no static keys. Account ID, region and state bucket come from `vars.*`, not literals.
- Both resources are in Terraform, so `terraform destroy` covers them. The log group has 14-day retention, and both resources have identifying names or tags.
- The state bucket, lock table and deploy role are prerequisites created outside this change. The state bucket versioning claimed in the `main.tf:4` comment cannot be verified from this diff. Nothing here provisions or tears down those prerequisites.
- The `dynamodb_table` backend argument is deprecated in newer Terraform (1.10 and later) in favour of `use_lockfile`. It works today.
- There is no `.gitignore`, so a local `infra/backend.hcl` (which holds the state bucket name) could be committed by accident. It would be worth ignoring `infra/backend.hcl` and `.terraform/`.

### Out of my lane
- `README.md:9` -> docs-reviewer. "Nothing is created outside Terraform" is not quite true. The state bucket, lock table and OIDC deploy role must already exist, and the README doesn't list them as prerequisites.
- `infra/main.tf:14` -> security-reviewer. The bucket has no public access block or default KMS encryption (checkov CKV2_AWS_6 and CKV_AWS_145).
