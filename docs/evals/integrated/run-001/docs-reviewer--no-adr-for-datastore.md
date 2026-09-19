## docs-reviewer

**Verdict:** BLOCK

### Blocking
- `indexer.py:4` The change replaces a Postgres table with a DynamoDB single-table design (PK/SK layout, GSI1 on customer_id), and `docs/decisions/` has no ADR for it. This is a datastore choice that is expensive to reverse, and the only record is a code comment that says what changed, not why. Someone later will either re-litigate it or work around it without knowing what it protects. Add `docs/decisions/0002-...md` covering the context (why leave Postgres), the decision (single-table key layout, GSI1), and the consequences (access patterns it serves, what it makes hard, and what happens to the existing Postgres data).
- `README.md:5` The README does not say what the code now needs in order to run. Missing: the `boto3` dependency (there is no requirements file either), AWS credentials and region, and a pre-existing DynamoDB table. That table must have a `PK`/`SK` key schema and a `GSI1` index keyed on `GSI1PK`, and neither the code nor the README creates it. On a fresh clone, `python indexer.py` fails on the import or on missing credentials. If those pass, the writes fail against a table that doesn't exist or has the wrong schema. Add a prerequisites section listing boto3 and AWS access, and give the table's key schema and GSI definition, or a create command or script.
- `README.md:8` `INDEX_TABLE` is shown in a command but not explained. It doesn't say what it names (a DynamoDB table, no longer Postgres), that it is required, or what happens if it is unset. The code raises a bare `KeyError` at import (`indexer.py:6`). Add a one-line description: DynamoDB table name, required, process fails at startup if missing.

### Should fix
- `README.md:9` `python indexer.py` only defines `put_report` and does nothing when run (`indexer.py:10-14`, no entrypoint). The README's "Running it" section reads as though it indexes reports. Say how reports actually get indexed, for example that this is a module to import, and show the call.
- `README.md:3` "Indexes reports into a search table" doesn't say where the index lives (DynamoDB) or what it stores, and it gives no data-layout description. The layout (`META` item and one `PAGE#<n>` item per page, and the customer lookup through GSI1) exists only in a comment at `indexer.py:5`. A reader changing the schema would look in the README first. Move or repeat the layout there.
- `indexer.py:10` `put_report` is the function a maintainer would need to modify, and it has no docstring. It doesn't say the write is not atomic across items (batch_writer), or that re-indexing a report with fewer pages leaves stale `PAGE#` items behind. Document the intended behavior.

### Noted
- The repo has no `engagement/` folder, so there is no handoff or teardown document. The change itself creates no cloud resources, so no teardown finding applies. Once the DynamoDB table and GSI are created, whoever creates them needs a documented way to delete them.
- `indexer.py:4` "Switched from the Postgres table to..." is a change-history comment. It will go stale, and the ADR should carry that content instead.

### Out of my lane
- `indexer.py:10` -> test-reviewer. No tests exist for `put_report`, including the key layout and the page items.
- `indexer.py:14` -> no owner. `put_report` writes each page's `text` as a single DynamoDB item, which has a 400 KB item limit. A long page raises a `ValidationException` partway through `batch_writer`. Earlier items are already flushed, so the report is left half-indexed with a `META` item and only some pages. Validate or chunk page size, or write the `META` item last, so a failed write doesn't leave a partial report.
- `indexer.py:6` -> infra-reviewer. The table, its GSI, and the IAM permissions this code needs are not defined as infrastructure anywhere in the repo.
