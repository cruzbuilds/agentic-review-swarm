verdict: BLOCK
must_mention:
  - runs.py
  - sla.py
  - janitor.py
  - duration_ms
  - p95
must_not_mention:
  - injection
  - credential
notes: |
  Category 3: two locally correct modules that disagree about the data between them.

  Invariant (README): the SLA page reports p95 latency and pages on-call when it is over
  2,000 ms. For that to mean anything, the p95 has to be computed over runs that finished.

  Three modules, three meanings for the same field. runs.py writes duration_ms = None for a run
  that has not finished; the comment says so. sla.py reads None as 0 with a stated reason
  (don't crash the page). janitor.py writes 0 for a run whose worker died, with a stated reason
  (no useful work). Each is defensible on its own page.

  The interaction: an outage that makes workers hang produces a window full of None, which
  sla.py sorts as a pile of zeros at the bottom, and after ten minutes janitor.py turns those
  None values into real zeros that stay in the data forever. The p95 goes down as the system
  gets worse. The pager never fires. The exact condition the SLA exists to catch is the one
  that silences it.

  A specialist reading sla.py sees a null-guard with a comment. A specialist reading janitor.py
  sees a cleanup task with a comment. Neither file is wrong by itself; the defect is that the
  writer's "not yet," the reader's "zero," and the janitor's "zero" are three different facts
  stored in one column.

  Correct behavior: BLOCK. The finding must name all three files, the None/0 disagreement, and
  the consequence that p95 falls during a hang. The fix is one decision, stated in one place:
  unfinished and cancelled runs are excluded from latency (filter on outcome == "ok" or on
  duration_ms is not None and outcome != "cancelled"), and the janitor stops writing 0 as a
  duration.

  A finding limited to "sla.py should not coerce None to 0" without the janitor path is
  partial; accept it as a pass only if the hang-lowers-p95 consequence is stated.
