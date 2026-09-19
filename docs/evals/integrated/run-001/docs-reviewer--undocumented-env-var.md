**Verdict:** BLOCK

### Blocking
- `indexer.py:5` `INDEX_TABLE` is read with `os.environ[...]`, so the program crashes with a KeyError if it is unset. The README's "Running it" section only exports `REPORTS_BUCKET`, so anyone following it fails at import. Add `INDEX_TABLE` to the README, say it is required, and say what it names (the DynamoDB table the index is written to).
- `indexer.py:6` `INDEX_BATCH_SIZE` (default 25) is undocumented. A reader can't tell what is batched, or that it can be tuned. Add it to the README with its default and meaning.
- `indexer.py:7` `AWS_REGION` (default `us-east-1`) is undocumented. A bucket or table in another region fails or misbehaves with no hint why. Document the variable and the default.
- `README.md:8` The README says `pip install -r requirements.txt`, but the repo has no `requirements.txt` (tracked files are only `README.md` and `indexer.py`). The step fails on a fresh clone, and the code's dependency on `boto3` is written down nowhere. Add `requirements.txt` with `boto3`, or change the instruction.

### Should fix
- `README.md:5` The README doesn't list prerequisites that the code assumes. There are three gaps:
  - AWS credentials must be available and need S3 read and DynamoDB write access.
  - The DynamoDB table must already exist, and the code never creates it.
  - The table's key schema isn't stated.
  
  Someone starting from a fresh clone can't get a working run. List each of these.
- `README.md:10` The README says `python indexer.py` runs the indexer, but `indexer.py` only defines `run()` and never calls it. There is no `if __name__ == "__main__"` guard, so the command does nothing. The body at `indexer.py:13` is also a `# ... indexing logic ...` placeholder. Either the README overstates what exists, or the entry point is missing. Make the two agree, and state the limitation if the logic is a stub.
- `indexer.py:12` The change picks DynamoDB as the index store, and S3 as the source. Reversing that later would be expensive, and there is no `docs/decisions/` ADR recording why. Add a half-page ADR covering context, decision and consequences.
- `README.md:3` The README claims "PDF reports" and a "searchable table" but doesn't say what is extracted, what the table's fields are, or how to search it. A maintainer can't tell what a correct result looks like. Describe the record shape and the intended query path.
- `README.md:1` There is no `engagement/04-handoff.md` and no "where to change things", limitations or teardown section. The project reads and writes cloud resources (a bucket and a table), and nothing says who owns them or how to remove them. Add a handoff or a short README section that names the resources, says whether this project owns the table, and says how to delete it.

### Noted
- `indexer.py:10` `run()` has no docstring. It is the entry point someone would need to modify, so it is worth a line once the logic exists.
- There is no `.env.example`. Adding one would be the natural place for the variables listed above.

### Out of my lane
- `indexer.py:4` -> no owner. `BUCKET` and `TABLE` are read at import time with `os.environ[...]`, so merely importing the module (in tests or tooling) raises KeyError when the variables are unset. Read them inside `run()` or in a `main()` so the module can be imported safely.
- `indexer.py:13` -> test-reviewer. There are no tests for the indexer.
