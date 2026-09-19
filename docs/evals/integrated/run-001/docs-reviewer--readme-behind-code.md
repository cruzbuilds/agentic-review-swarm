## docs-reviewer

**Verdict:** BLOCK

### Blocking
- `README.md:13` The README says "Only handles PDF. Other formats are skipped." but `indexer.py:4` sets `SUPPORTED = {".pdf", ".docx", ".txt"}`. A reader will believe `.docx` and `.txt` files are ignored and may work around a feature that exists. Rewrite the limitation to list the supported formats, or remove it.
- `README.md:14` The README says "Single-threaded. Large buckets take a while." but `indexer.py:10` and `indexer.py:14` add a `ThreadPoolExecutor` with 8 workers by default. The stated limitation is the opposite of the behavior. Remove it or replace it with the real constraint. The README also doesn't say whether the parallelism is safe for DynamoDB write throughput.
- `README.md:8` The Running section shows only `--bucket`. It omits `--workers` (`indexer.py:10`, default 8) and `--dry-run` (`indexer.py:11`). Someone who wants to preview a run or tune concurrency has to read the source. Add both flags with a one-line description and their defaults.

### Should fix
- `README.md:3` The README says the tool indexes into DynamoDB but doesn't say which table, which region, or what credentials and IAM permissions it needs. It also doesn't list the prerequisites (Python version, AWS SDK dependency, an existing table). `indexer.py` has no table argument or environment variable for this, so a new person can't tell how to point it at a table. Add a prerequisites and configuration section that says how the target table is chosen and what access is required.
- `README.md:5` Running starts with `python indexer.py`, with no install step. There is no `requirements.txt` or `pyproject.toml` in the repo, so a fresh clone has no listed dependencies. Add the install step and a dependency manifest.
- `README.md:3` DynamoDB as the index store is a choice that is expensive to reverse. `docs/decisions/` doesn't exist, so the reasoning isn't recorded. Add a short ADR (context, decision, consequences).
- `indexer.py:7` `main()` has no docstring or comment on what "index" means: which fields are written, what the key schema is, and what happens on re-runs (idempotent or duplicates). Someone modifying this needs that. Document it in the README or a docstring once the body is written.

### Noted
- There is no `engagement/` folder, so there is no handoff document and no "where to change things" section. Nothing in this change creates cloud resources, so I am not requiring a teardown section. If the DynamoDB table is created as part of this project, its removal needs documenting.
- `indexer.py:14-16` is a stub (`pass`), so I reviewed the README against the CLI surface and the constants only.

### Out of my lane
- `indexer.py:14` -> scope-reviewer. The executor body is `pass`, so the documented command `python indexer.py --bucket my-bucket` reads nothing and writes nothing. `--dry-run` is parsed but never used. Confirm whether this is meant to be a placeholder.
- `indexer.py` -> test-reviewer. There are no tests for the supported-format filtering, the worker option, or dry-run.
