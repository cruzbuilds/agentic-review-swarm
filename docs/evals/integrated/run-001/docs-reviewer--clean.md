**Verdict:** WARN

### Blocking

None.

### Should fix

- `README.md:57` The "Not production ready" section says the indexer runs under a "broad role" that needs scoping. No role exists. `infra/main.tf` creates no IAM resources, `indexer.py` runs with whatever local credentials the user has, and the Prerequisites (line 9) say it only needs read on the bucket and write on the table. A reader can't tell which gap to close. Rewrite it to say what is true, for example that there is no IAM policy in `infra/` and the runner's own credentials are used, so a scoped policy still needs to be written.
- `README.md:65` The teardown section says the log group "keeps 14 days of logs". Nothing writes to `/report-indexer`. `indexer.py` logs to stdout via `basicConfig`, and no handler or agent ships to CloudWatch. A reader will look there for logs and find none. Either say the log group is currently unused, or wire it up and document how logs reach it.
- `README.md:43` The README says the customer comes from the S3 object's "`customer` metadata tag". S3 has both object tags and user-defined metadata (`x-amz-meta-customer`). The code reads only metadata, via `head_object(...)["Metadata"]` at `indexer.py:35`. Someone who sets an object tag gets everything filed under `unknown` with no error. Say "user-defined metadata (`x-amz-meta-customer`)", and add an example upload such as `aws s3 cp x.pdf s3://... --metadata customer=acme`. The setup steps create an empty bucket and never say how PDFs get in.
- `README.md:9` The README doesn't say which AWS region Terraform deploys to. `infra/main.tf` has no provider block, so the region comes from the user's environment or profile. The Configuration table (line 41) says the indexer defaults to `us-east-1`. If Terraform lands in another region, the indexer fails with a table-not-found error. State that the `AWS_REGION` used for `terraform apply` must match the one used to run the indexer, or pin the region in Terraform.
- `README.md:52` The Limitations section says a large batch "can fail partway; re-running is safe". It doesn't say that failures are silent (see the first no-owner item in Out of my lane). Add a line saying how a user would find out which PDFs failed to index, or that they currently can't.

### Noted

- There is no `engagement/04-handoff.md`. The README covers setup, config, limitations, gaps and teardown, so it works as the handoff. It has no "where to change things" section, for example where to add a new access pattern. `docs/decisions/0002` partly covers this.
- `docs/decisions/` starts at 0002 and has no 0001. If 0001 was intentionally skipped, that's fine. If it was lost, a decision record is missing.
- The README says reports can be "listed by customer", but gives no query example. The GSI is `KEYS_ONLY` (`infra/main.tf:22`), so a query returns only PK and SK and the caller needs a second `get_item` for the page count. ADR 0002 says "keys only" but not what that costs the reader. One sentence would help.
- `terraform destroy` deletes the source PDFs, because `force_destroy` is set on the bucket that holds the inputs. The README does say Terraform empties the bucket. It doesn't warn that this is unrecoverable if the bucket holds the only copy.

### Out of my lane

- `infra/main.tf:15` -> infra-reviewer. `attribute { name = "PK" type = "S" }` puts two arguments in a single-line block, and lines 16-17 do the same. HCL only allows one argument in a single-line block, so `terraform validate` and `terraform apply` should fail with "Invalid single-argument block definition". That breaks the README's setup step. I read this from the syntax and did not run Terraform. Put each argument on its own line.
- `infra/main.tf:4` -> security-reviewer. The S3 bucket has no public access block, encryption or versioning configured, and it holds customer reports.
- `indexer.py:60` -> no owner. `ex.submit(...)` discards the returned futures, so exceptions raised in `index_one` (PDF parse errors, DynamoDB throttling, missing `head_object` permission) are never logged or raised. The process exits 0 with no message for the failed PDFs. A user would believe the whole bucket was indexed when reports are missing from the index. Collect the futures and log or re-raise their exceptions, and exit non-zero if any failed.
- `indexer.py:36` -> no owner. `report_id` is the basename of the key with a lowercase `.pdf` stripped. `a/1.pdf` and `b/1.pdf` both become `1` and overwrite each other's items in DynamoDB. `1.PDF` passes the case-insensitive filter at line 27, but `removesuffix(".pdf")` leaves it as `1.PDF`. Use the full key or a prefix-qualified ID, and strip the suffix case-insensitively.
