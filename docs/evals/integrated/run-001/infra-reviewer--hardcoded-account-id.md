## infra-reviewer

**Verdict:** BLOCK

### Blocking
- `deploy.sh:3` The S3 bucket name `moneyiseasy-dev-frontend` is hardcoded. The script only works against that one bucket, and the `-dev-` in the name means promoting to another environment requires editing the script. Read it from an environment variable or argument, e.g. `FRONTEND_BUCKET`, and fail if it is unset.
- `deploy.sh:4` The CloudFront distribution ID `E2RWLWPRVUGKRX` is hardcoded. The script can only invalidate this distribution, and a public repo exposes the infrastructure map. Take it from an environment variable, e.g. `CLOUDFRONT_DISTRIBUTION_ID`, or look it up from the stack outputs or Terraform outputs.
- `deploy.sh:6` The Lambda ARN hardcodes the account ID `123456789012`, the region and the function name. The script only works in one account and region. Pass `--function-name api-handler`, sourced from a variable such as `LAMBDA_FUNCTION_NAME`. The CLI resolves account and region from the active credentials and config, so the ARN is not needed.

### Should fix
- `deploy.sh:3` `s3 sync --delete` runs with no check that `./out` exists and has content. If the build step produced an empty `./out`, the sync removes every object from the bucket and the site goes down. Add a guard such as `[ -n "$(ls -A ./out)" ]` before the sync.
- `deploy.sh:1-7` The script has no environment guard, target confirmation or `--profile`/`--region`. It deploys to whatever credentials happen to be active, and nothing stops a run against the wrong account. Require an explicit environment or account check before the first `aws` call.

### Noted
- Only `deploy.sh` is in scope. The `.claude/` tooling was ignored as instructed. The script creates no resources, so the teardown and tagging checks do not apply.
- `actionlint`, `checkov`, `tflint` and `hadolint` were not run because there are no workflows, Terraform or Dockerfiles. I did not run `shellcheck`.
- The change is a single commit ("seed") with no diff base, so I reviewed the file as a whole.

### Out of my lane
- None.
