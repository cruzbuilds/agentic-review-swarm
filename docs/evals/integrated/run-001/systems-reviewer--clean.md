**Verdict:** WARN

### Blocking

### Should fix
- `handlers.py:37-42` (with `models.py:4-9`) `reopen` is documented as "Only from RESOLVED", but it only checks `satisfaction is None` and leaves the source-state check to the shared `TRANSITIONS` table. That table also allows `PENDING -> OPEN`, so a requester can call `reopen` on a PENDING ticket and move it to OPEN without replying.
  - Invariant: the README allows `PENDING -> OPEN` only "when the requester replies".
  - Sequence: an agent replies, moving the ticket OPEN to PENDING. The requester calls `reopen(ticket, user_id)`. `require_reader` passes, `satisfaction` is None, and `transition` accepts `PENDING -> OPEN`.
  - Why each step looks fine: the handler reads correctly on its own, and the table is a legitimate table for `reply`.
  - Failure: the ticket returns to the agents' OPEN queue with no new message, and no reply is recorded.
  - Fix: check `ticket.status == "RESOLVED"` explicitly in `reopen`, as `rate` does at line 26.
- `handlers.py:33` (with `README.md:6-9` and `models.py:6`) `CLOSED` is reachable only through `rate()`. Rating and closing are one operation, and neither the README nor the schema says so.
  - An unrated RESOLVED ticket never closes. It stays open to `reopen` and `reply` indefinitely, which the README's "a CLOSED ticket cannot change" rule does not cover.
  - A requester who wants to rate cannot keep talking, and a requester who does not want to rate cannot close.
  - No agent path exists to close a ticket.
  - Fix: decide whether close-without-rating (an auto-close or an agent close) is intended, and document that rating closes the ticket. If unrated tickets must close, add a second path into `CLOSED`. That path must not set `satisfaction`, so `reports.py:7` still treats such tickets as absent.

### Noted
- Traced entity: `Ticket.status` and `Ticket.satisfaction`, through `reply`, `resolve`, `rate`, `reopen` and `transition`, plus the reader in `weekly_csat`.
  - The "score recorded once" rule holds along every path in this change. `satisfaction` is set only in `rate`, which requires RESOLVED and unrated and then moves the ticket to CLOSED, which has no outgoing transitions. `reopen` cannot reach a rated ticket.
  - `weekly_csat` treats None as absent, and the writer only ever sets 1..5, so the reader and writer agree.
- I could not trace persistence, because there is no storage layer in the change. If tickets are loaded, mutated and saved as whole rows, `rate` and `reopen` can race. That could happen from a double-click or two tabs, where both requests load the ticket as RESOLVED with no score.
  - If `rate` commits CLOSED with a score and `reopen` then writes back its stale copy as OPEN, the result is an OPEN ticket with a score. After an agent resolves it again, it is RESOLVED, `rate` says "already rated" and `reopen` refuses, so it can never close.
  - I cannot confirm this without seeing the save path. If one exists, use a version check or a conditional `UPDATE ... WHERE status='RESOLVED' AND satisfaction IS NULL`.
- `models.py:5` allows `OPEN -> RESOLVED` directly, but the README lifecycle reads `OPEN -> PENDING -> RESOLVED`. I read this as intended (an agent can resolve without a reply), but it is worth confirming.
- `weekly_csat` takes a plain list and `Ticket` has no timestamps (no `resolved_at` or `rated_at`), so "weekly" cannot be enforced or verified in this change. Correctness depends on an unseen caller selecting the right tickets, and I could not trace that caller.

### Out of my lane
- `models.py:18` -> docs-reviewer. The comment says the score is "set once at RESOLVED", and the README says it is recorded "when the ticket is resolved". The code sets it in `rate()` when the requester rates, in the same step that closes the ticket.
- `README.md:8-9` -> docs-reviewer. The README does not say that rating is what closes a ticket (see the Should fix above).
- There are no tests anywhere in the change -> test-reviewer. The transition table, the rate/reopen exclusion and the CSAT null handling all need coverage.
- `handlers.py:9-13` -> no owner. `body.strip()` can produce an empty message, which is appended anyway and still triggers `PENDING -> OPEN`.
  - Sequence: an agent replies, moving the ticket to PENDING. The requester calls `reply(ticket, uid, False, "   ")`. `require_reader` passes, an empty message is recorded, and the ticket flips to OPEN.
  - Why it matters: this is a content-free requester reply that pushes the ticket back into the agent queue, with an empty entry in the thread.
  - Fix: reject an empty body after stripping, before the append and the transition.
