## systems-reviewer

**Verdict:** BLOCK

The change is the whole seed commit (`c509603`). The `.claude/` folder was excluded as instructed. I traced `Run` from `runs.py` through `janitor.py` to `sla.py`, and checked it against the README's SLA promise. I ran nothing, because the repo has no tests or build. The sequence below is derived by reading the code.

### Blocking

- `sla.py:9`, `janitor.py:12`, `runs.py:11`: the SLA p95 counts hung and dead runs as 0 ms, so a worker outage makes latency look better and the on-call page never fires.
  - **Invariant.** README lines 6-7 say the SLA is p95 under 2,000 ms and that on-call is paged when it is breached. The p95 is only meaningful if slow or stuck runs count as slow.
  - **Interaction.**
    1. `RunStore.start` creates a run with `duration_ms=None`, meaning "not finished yet" (`runs.py:11`).
    2. If the worker hangs or dies, `finish()` is never called.
    3. After 600 s, `close_stale` sets `duration_ms = 0` and `outcome = "cancelled"`, on the reasoning "it did no useful work" (`janitor.py:12-13`).
    4. `p95_ms` reads `r.duration_ms or 0` over every run in the window, including cancelled and unfinished ones (`sla.py:9`). Before the janitor runs, a `None` is also read as 0.
    5. `breached()` compares that p95 to 2000 (`sla.py:17`).
  - **Why each step looks fine.**
    - `janitor.py` reads as reasonable cleanup: a dead worker has no real duration, so 0 is a plausible placeholder.
    - `sla.py` is written on purpose so an unfinished run "doesn't crash the SLA page" (`sla.py:7-8`).
    - `runs.py` correctly uses `None` for "not finished".
    - Each file is defensible alone. Together they turn "the work never completed" into "the work completed instantly".
  - **Failure.** Take 100 runs in the window. Suppose 10 of them exceed 2,000 ms, say 5,000 ms, because the backend is degraded. The p95 is 5,000 ms and on-call is paged. Suppose instead that those same 10 runs hang, which is what a worse outage looks like. They become 0 ms, the p95 is that of the healthy runs (about 100 ms), and `breached()` returns False. The worse the failure, the healthier the SLA page looks. In-flight runs younger than 600 s also read as 0, so a fresh spike is understated until the runs finish.
  - **Fix.** Decide once, in `sla.py`, what an unfinished or cancelled run means for latency, and stop encoding it as 0.
    - Treat `duration_ms is None` as the elapsed time since `started_at` (or as breaching).
    - Or count cancelled and unfinished runs as a separate failure metric that also pages.
    - Whichever you pick, change `janitor.py:12` so it no longer writes a fake 0 duration, for example by leaving `duration_ms` as `None` and relying on `outcome`.

### Should fix

- `janitor.py:11-13` with `runs.py:26-30`: the janitor and `finish()` can overwrite each other's result on the same run, with no guard on either side.
  - **Interleaving.** A worker that is slow rather than dead calls `finish(id, "ok")` at about 601 s. The janitor's check-then-set (`duration_ms is None`, then write 0 and "cancelled") is not atomic. If the janitor reads `None` before `finish` writes, its later write replaces a real 700,000 ms "ok" run with a 0 ms "cancelled" run.
  - **Reverse order.** If the janitor closes the run first and `finish()` arrives later, `finish()` overwrites unconditionally. That moves the run from cancelled back to ok, with a duration that now includes the dead time.
  - **Why this is only a warning.** I could not confirm the store is shared across threads or processes. To confirm, I would need to see how workers and the janitor call it. The janitor also iterates `store.rows.values()` while `start()` can insert (`runs.py:23`). That raises `RuntimeError: dictionary changed size during iteration` under threads.
  - **Fix.** Make cancelled a terminal state: `finish()` should refuse to change a run that already has an outcome. Make the janitor's check-and-set atomic with `finish()`, for example with a lock or a conditional update.

### Noted

- `sla.py:6-13` and `sla.py:17` are the only consumers of `duration_ms`. The p95 fix above needs no other consumer to change, but any future consumer will inherit the same 0-versus-`None` ambiguity.
- I could not see where the on-call paging is wired. The README says it exists, but no code in this change calls `breached()`.

### Out of my lane

- `sla.py:12` -> no owner. `index = int(len(durations) * 0.95)` overshoots nearest-rank p95. For n=20 it returns the maximum (index 19) rather than the 19th value (index 18). The reported p95 is biased high for small windows, which can page on-call spuriously. Use `math.ceil(0.95 * n) - 1`.
- `sla.py:17` -> no owner. `breached` uses `> 2000`, but the README says the SLA is "p95 under 2,000 ms". A p95 of exactly 2,000 ms is not under the SLA and is not flagged. Use `>=`, or reword the README.
- `runs.py:26-30` -> no owner. `finish()` raises a bare `KeyError` on an unknown `run_id`, and it accepts any `outcome` string although the comment on line 12 lists three allowed values. A worker reporting late or wrongly will crash instead of being rejected cleanly.
- The repo has no tests for `sla.py`, `janitor.py` or `runs.py` -> test-reviewer.
