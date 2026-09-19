## systems-reviewer

**Verdict:** BLOCK

### Blocking
- `janitor.py:12` and `sla.py:9` The README says the SLA is p95 under 2,000 ms and that on-call is paged on breach. The janitor and the SLA calculation together make hung jobs count as the fastest runs, so a stuck fleet never breaches.
  - **Invariant:** `README.md:6` says a breach of p95 < 2,000 ms pages on-call. A run that hangs or dies is the worst latency the system can observe, so it should push p95 up, not down.
  - **Interaction:**
    1. A worker dies or hangs, and `finish()` (`runs.py:26`) is never called.
    2. The janitor sets `duration_ms = 0` and `outcome = "cancelled"` (`janitor.py:12-13`).
    3. `window()` (`runs.py:33`) does not filter on outcome, so the run stays in the window.
    4. `p95_ms` sorts it as 0 (`sla.py:9`). Unfinished runs already get `None -> 0` there too (`sla.py:9`).
  - **Why each step looks fine:** `janitor.py` documents "did no useful work, so duration 0". `sla.py` documents "missing durations count as 0 so the page doesn't crash". `runs.py` is a plain store. Each is defensible alone. Together they turn "everything is hanging" into a stream of zeros.
  - **Failure:** I ran a window of 20 runs at 500 ms plus 5 unfinished runs, and p95 was 500 with `breached=False`. When a dependency outage stalls most workers, the window fills with 0s and the SLA page reports healthy while jobs are failing. The page is not paged, and the stale runs are then closed as 0, which makes it worse.
  - **Fix:** Keep zeros out of latency. Either exclude `duration_ms is None` and `outcome == "cancelled"` runs from the percentile in `sla.py`, or have the janitor record a real duration (`now - started_at`). Also report a separate count of unfinished or cancelled runs, and page on it, so that excluding them does not hide an outage. Fix it in `sla.py:9` and `janitor.py:12`.

- `runs.py:26-29` and `janitor.py:11-13` A run the janitor has cancelled can be finalized again by `finish()`. That is a cancelled-to-ok or cancelled-to-failed transition, and it silently overwrites the janitor's result.
  - **Invariant:** The janitor's docstring and the `Run.outcome` comment (`runs.py:12`) treat `cancelled` as a terminal close-out. `duration_ms is None` is used as the "not finished yet" marker.
  - **Interaction:**
    1. A worker is slow but alive and runs past 600 s.
    2. `close_stale` sees `duration_ms is None` and marks the run `cancelled` with 0 ms.
    3. The worker then calls `finish(run_id, "ok")`.
    4. `finish` has no guard, so it overwrites both fields.
  - **Why each step looks fine:** `finish` is a plain setter. The janitor's condition is correct for a dead worker.
  - **Failure:** I reproduced it. The run went to `duration_ms=0, outcome=cancelled` and then to `duration_ms=700000, outcome=ok`. Between the two calls the SLA page counted a 700 s run as 0 ms. Afterward the row is no longer "cancelled", so anything counting janitor closures is wrong. It is also a lost update: the two writers have no lock, no version check and no compare-and-set on `duration_ms is None`. Any consumer keyed on `outcome` sees a run change state after it was closed.
  - **Fix:** Make `finish` reject or no-op when `duration_ms is not None` (or `outcome` is set). Make the janitor's claim atomic with the same check, using a lock or a conditional update if this moves to a real database. Put the check in `RunStore` so neither caller can bypass it.

### Should fix
- `sla.py:12-13` `index = int(len(durations) * 0.95)` picks the element at floor(0.95·n), which is not a standard p95 for small windows. For n=20 it returns the maximum, and for n=10 it returns the 10th value, which is also the maximum. This is a local arithmetic question, so I have not marked it blocking. Together with the zero-padding above it makes the reported number hard to relate to the README's promise. Decide the percentile definition and state it.
- `sla.py:9` and `sla.py:10-11` An empty window returns 0 and `breached` returns `False`. If the writer stops entirely (nothing is starting runs), the SLA page reports healthy. Whether "no data" should page is a product decision, but the code currently makes it silent success.
- `runs.py:20-24` and `runs.py:33` `_next` and `rows` are mutated with no lock, while the janitor iterates `store.rows.values()` (`janitor.py:10`). If `start()` runs concurrently in another thread, the janitor's loop can raise "dictionary changed size during iteration". The file gives no sign of how the store is shared, so I could not confirm this.

### Noted
- I ran the reproductions above with a throwaway script and `PYTHONDONTWRITEBYTECODE=1`. Nothing in the repository was modified.
- Persistence, threading and how the pieces are deployed are not in the tree. I could not trace the real concurrency model, only the in-memory store.
- There are no `engagement/` or `docs/decisions/` folders, so the only stated promises are in the README.

### Out of my lane
- `__pycache__/*.pyc` files are committed. This is hygiene with no owner in the roster.
- No tests exist for any of these modules. That is test-reviewer's call.
- The README does not say how a window is chosen or what `cancelled` runs mean for the SLA. That is docs-reviewer's call.
