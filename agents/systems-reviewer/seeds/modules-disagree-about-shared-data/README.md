# jobstats

Records background job runs and reports latency for the SLA page.

- `runs.py` writes a row per job run.
- `sla.py` computes the p95 duration over a window. **The SLA is p95 under 2,000 ms**; the
  on-call rotation pages when it is breached.
- `janitor.py` closes out runs whose worker disappeared.
