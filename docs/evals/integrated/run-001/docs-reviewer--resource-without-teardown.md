## docs-reviewer

**Verdict:** BLOCK

### Blocking
- `engagement/04-handoff.md:13` The teardown section says "TBD", but `infra/main.tf` creates an S3 bucket (line 1), a DynamoDB table (line 5), a CloudWatch log group (line 14) and an IAM role (line 19). Nothing tells the next person how to delete them, so they will keep costing money and nobody will know to look for them. List every resource with its exact name (`acme-report-indexer-reports`, `report-index`, `/indexer`, `report-indexer-role`) and give the removal steps, for example `cd infra && terraform destroy`. Also say that the bucket must be emptied first, and that the bucket and table hold data.
- `infra/main.tf:5` The change chooses DynamoDB with a PK/SK key schema as the index store and S3 as the report store. Reversing either would be expensive, and `docs/decisions/` does not exist. Nobody can later tell why DynamoDB was picked over a relational or search store, or what the PK/SK layout is meant to support. Add an ADR under `docs/decisions/` covering context, decision and consequences. Include what PK and SK hold.

### Should fix
- `README.md:8` The deploy instructions assume a prepared machine. They do not mention the Terraform version, `terraform init`, AWS credentials, or which account and region to use. A fresh clone running `terraform apply` will fail. List the prerequisites and the full command sequence starting from a clone.
- `README.md:3` The README says "Indexes reports" but never says how indexing runs, what triggers it, or what the inputs and outputs are. The repo contains no indexing code, only infrastructure. The handoff's "Running it" section (`engagement/04-handoff.md:9`) just says "See README", so the operating instructions are missing in both places. Add a "Running it" section to the README. If the indexer is not in this change, say where it lives or that it is not built yet.
- `engagement/04-handoff.md:5` The handoff describes an S3-to-DynamoDB flow but has no "where to change things" section. It also has no known limitations and no production-readiness statement. Add where the indexing logic and resource definitions live, and list what is missing before this is production-ready, with specifics.

### Noted
- The handoff and README are the only documentation, and they do not conflict with each other. There is no `.env.example`, and the change reads no environment variables, so there are no undocumented variables.

### Out of my lane
- `infra/main.tf:21` -> infra-reviewer. `data.aws_iam_policy_document.assume` is referenced but never defined, and there is no `provider` or `terraform` block. The role also has no attached permissions, so the configuration will not plan as written.
- `infra/main.tf:16` -> infra-reviewer. `retention_in_days = 0` means logs never expire. The bucket name on line 2 is hardcoded and must be globally unique.
- `infra/main.tf:1` -> security-reviewer. The bucket declares no public-access block or encryption settings. The IAM role's trust and permissions are undefined.
# 4. Handoff

## What this is

Indexes reports from S3 into DynamoDB for search.

## Running it

See README.

## Tearing it down

TBD
