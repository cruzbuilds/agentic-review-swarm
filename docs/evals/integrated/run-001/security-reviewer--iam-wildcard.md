## security-reviewer

**Verdict:** BLOCK

### Blocking
- `lambda-role.json:7` The policy grants `"Action": "*"` on `"Resource": "*"`, which is full administrator access to the whole AWS account. The README says this role only reads objects from one S3 bucket (`reports-bucket`) and writes rows to one DynamoDB table (`report-index`). If the Lambda is compromised, for example through a malicious object it processes, the attacker gets everything the account can do: IAM, other buckets and tables, and creating new credentials. Replace the wildcards with the specific actions and ARNs the function uses. For example:
  - `s3:GetObject` on `arn:aws:s3:::reports-bucket/*`.
  - `dynamodb:PutItem`, plus `dynamodb:BatchWriteItem` or `dynamodb:UpdateItem` only if the code uses them, on the `report-index` table ARN.
  - CloudWatch Logs permissions scoped to the function's log group, if it needs them.

### Should fix

### Noted
- Scope is the whole working directory as one proposed change, apart from `.claude/`. That leaves `README.md` and `lambda-role.json`, both added in the single `seed` commit (8f7a96b). No `engagement/` or `docs/decisions/` exist, so there was no scope context to read.
- gitleaks found nothing, either in the working tree or in the one-commit history. semgrep (`p/security-audit`, `p/secrets`) reported no findings. No tracked `.env`, key, or credential files. There are no lockfiles, so no dependency audit applied.
- The README's stated purpose is the evidence that the wildcard is wider than the work needs. No trust policy is in this change, so I could not check who can assume the role.

### Out of my lane
