## infra-reviewer

**Verdict:** WARN

### Blocking

### Should fix
- `main.tf:5` `aws_iam_role.fn` is referenced but no `aws_iam_role` resource is defined anywhere in the change. `terraform validate` and `plan` will fail on the undeclared reference, so this cannot be applied. Define the role, or take it as a variable or data source.
- `main.tf:11` `retention_in_days = 0` means the log group never expires. Lambda logs will accumulate and be billed indefinitely. Set a finite retention such as 14 or 30 days.
- `main.tf:1` The Lambda has no `depends_on` or reference to `aws_cloudwatch_log_group.fn` (`main.tf:9`). The log group name is a duplicated string, so Terraform sees no ordering between them. If the function logs first, Lambda auto-creates `/aws/lambda/fn-<suffix>`. The later `aws_cloudwatch_log_group` create then fails with "already exists", and the retention setting never applies. Reference the log group from the function, for example through `logging_config.log_group`, or add `depends_on`.
- `main.tf:1` The Lambda and log group have no tags, and the name `fn-<suffix>` does not say which project or purpose. In a bill or console listing, nobody can tell whether it is safe to delete. Add tags for project and purpose, for example via provider `default_tags`, and use a descriptive name. The charter's criterion is no tags, no name and no comment. There is a name here, so this is Should fix rather than Blocking.
- `main.tf:6` `filename = "build/fn.zip"` points at an artifact that is not in the repo and has no build step. There is also no `source_code_hash`. `plan` fails until someone builds the zip by hand, and later code changes will not trigger a redeploy. Add `source_code_hash = filebase64sha256(...)` and document or script the build.

### Noted
- Ran `terraform fmt -check`, which was clean. `checkov` crashed on a certificate-verification error while trying to reach its API, so I have no results from it. `tflint`, `actionlint` and `hadolint` are not installed. The only infrastructure file is `main.tf`. There are no workflows or Dockerfiles, so the CI permissions, SHA pinning and static credential checks do not apply.
- `main.tf` has no `terraform {}` block, no `required_providers`, no provider block and no backend. The `aws` and `random` providers are unpinned. State will be stored locally by default, which is easy to lose and is not versioned. That is fine for a throwaway seed but not for handoff.
- Teardown: all three resources are managed by Terraform, so `terraform destroy` covers them. There is no handoff doc (`engagement/04-handoff.md`) to check against.
- No hardcoded account IDs, ARNs or bucket names were found.
- No `.claude/` files were reviewed, as instructed.

### Out of my lane
- `main.tf:5` -> security-reviewer. The IAM role the Lambda will assume does not exist yet, so its policy scope cannot be reviewed. Check it when it is added.
