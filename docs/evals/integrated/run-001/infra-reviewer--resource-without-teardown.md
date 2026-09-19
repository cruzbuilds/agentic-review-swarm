## infra-reviewer

**Verdict:** BLOCK

### Blocking
- `scripts-deploy.sh:4` The CloudWatch dashboard `report-indexer-ops` is created by hand in the console. `scripts-deploy.sh:6-7` does the same for the SNS topic `report-indexer-alerts` and its on-call email subscription. None of these are in Terraform, no teardown script removes them, and no handoff document records them. `terraform destroy` will leave all three behind, and nobody will know to look for them. Put them under Terraform (`aws_cloudwatch_dashboard` accepts a JSON body, so the widget-layout reason doesn't hold; `aws_sns_topic` and `aws_sns_topic_subscription`). If they must stay manual, add explicit removal steps to a teardown script or `engagement/04-handoff.md`.
- `infra/main.tf:1-4` The S3 bucket has no `force_destroy` and no emptying step. Once `reports` holds objects, `terraform destroy` fails on it, and the bucket keeps running and costing money. There is also no teardown script or note to cover this. Set `force_destroy = true` if the data is disposable. Otherwise add a documented empty-then-destroy step.

### Should fix
- `infra/main.tf:10` `terraform validate` fails with "Invalid single-argument block definition". A one-line block can hold only one argument, so `attribute { name = "PK" type = "S" }` does not parse. Nothing in this file can be applied until it is fixed. Write the block on multiple lines.
- `infra/main.tf:2` `var.bucket_name` and `var.table_name` (line 7) are never declared. The change contains no `variables.tf`, no `*.tfvars` and no `variable` blocks, so Terraform will error on undeclared variables. Declare both and say where the values come from.
- `scripts-deploy.sh:3` The script runs `terraform apply -auto-approve` without `terraform init`, so it fails on a fresh checkout. It also skips plan review and has no environment gate. Add `init` and drop `-auto-approve`, or apply a saved, reviewed plan.
- `scripts-deploy.sh:1` The script has no `set -euo pipefail`. If `cd infra` or a later step fails, the script keeps going and still reports success.
- `infra/main.tf:1` There is no `terraform {}` block, no `required_providers` pin, no provider configuration and no backend. State is local, unversioned and easy to lose. Losing it orphans the bucket and table and leaves `destroy` with nothing to work from. Add a versioned remote backend and pin the AWS provider. Commit `.terraform.lock.hcl`.
- `infra/main.tf:3` and `infra/main.tf:11` Both resources are tagged only with `project`. Nothing says what the bucket or table is for, and an unlabelled item on a bill is hard to judge safe to delete. Add a `purpose` tag or similar.

### Noted
- The change contains no CI workflows or Dockerfile. The SHA-pinning, `permissions:` and OIDC checks don't apply.
- `terraform fmt -check` and `terraform validate` ran and produced the syntax error above. `checkov` is installed but its run did not complete (no `timeout` command), so treat it as not run. `tflint`, `actionlint` and `hadolint` are not installed and were not run.
- `PAY_PER_REQUEST` billing on the DynamoDB table (`infra/main.tf:8`) is reasonable at unknown usage. It is not a finding.
- `scripts-deploy.sh` sits at the repo root, while the convention is `scripts/`. This is a naming point and not raised as a finding.
- The comment "Run once" at `scripts-deploy.sh:2` suggests no re-run or update path is intended.

### Out of my lane
- `infra/main.tf:1-4` -> security-reviewer. The bucket has no public-access block, encryption or versioning configuration.
- `scripts-deploy.sh:6-7` -> docs-reviewer. There is no README or handoff doc describing the manual deploy steps, and none was in the change.
