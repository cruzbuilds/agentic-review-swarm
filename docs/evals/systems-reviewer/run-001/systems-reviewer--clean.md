**Verdict:** BLOCK

### Blocking
- `handlers.py:37-43` (with `models.py:4-9`): `reopen` can move a PENDING ticket back to OPEN with no reply, which the README's lifecycle does not allow.
  - **Invariant:** `README.md:6-7` allows `PENDING -> OPEN` only "when the requester replies". The `reopen` docstring says "Only from RESOLVED, and only before rating."
  - **Interaction:**
    1. An agent replies to an OPEN ticket, which moves it to PENDING (`handlers.py:10-11`).
    2. The requester calls `reopen(ticket, user_id)`.
    3. `require_reader` passes because they are the requester.
    4. `ticket.satisfaction is None` passes because nothing has been rated.
    5. `transition(ticket, "OPEN")` passes because the shared `TRANSITIONS` table allows `PENDING -> OPEN`, which is there for the reply path.
  - **Why each step looks fine:**
    - `reopen` never checks that the status is RESOLVED. It uses `satisfaction is None` as a stand-in for "not yet rated".
    - `transition` only checks that the edge exists in the table, and this edge is legitimate for `reply`.
    - Reviewed alone, neither file is wrong.
  - **Failure:** I ran it. After an agent reply the ticket was PENDING. After `reopen` it was OPEN with one message, so the requester put it back in the agent queue without saying anything. The lifecycle then depends on which handler the requester happens to call.
  - **Fix:** In `reopen`, require `ticket.status == "RESOLVED"` explicitly and raise otherwise. The `satisfaction` check can then go, because `rate` always closes the ticket. Better still, give the table separate named edges so the requester-reply path and the reopen path cannot borrow each other's.

### Should fix
- `handlers.py:9-14`: A requester reply on a RESOLVED ticket is appended but changes nothing. I ran it and the ticket stayed RESOLVED.
  - Agents work from the OPEN queue, so a message like "still broken" is stored where no one looks.
  - The requester also gets no signal that they should have called `reopen`.
  - Either reject the reply, or have it reopen the ticket. Which one is a product decision.
- `handlers.py:23-34` and `handlers.py:37-43`: `rate` and `reopen` both read `status` and `satisfaction` and then write them, with no shared lock or version check.
  - Suppose two requests load the same RESOLVED, unrated ticket, one calling `rate` and one calling `reopen`.
  - Each passes its checks against its own copy.
  - Whichever saves last wins, and the ticket ends up CLOSED, or OPEN with `satisfaction` set. An OPEN ticket with a score breaks the "once, at resolution" rule and would later count in CSAT.
  - There is no persistence layer in this change, so I cannot confirm the interleaving. If tickets are stored, the save needs a version check or a conditional update on `status`.
- `models.py:13-19` and `reports.py:4-10`: `weekly_csat` promises a weekly figure, but `Ticket` has no `resolved_at` or `rated_at`, so the function cannot restrict itself to a week.
  - It averages whatever list the caller passes, so the window is enforced by an unseen caller.
  - Add a timestamp when the rating is recorded, and have the report filter on it.
  - I could not see the caller, so this stays a warning.

### Noted
- `handlers.py:23-34`: Rating and closing are one step, so a RESOLVED ticket that is never rated stays RESOLVED forever. That is consistent with the README, but there is no auto-close and unrated tickets accumulate.
- I traced every path that writes or reads `status` and `satisfaction`: `reply`, `resolve`, `rate`, `reopen`, `transition` and `weekly_csat`.
  - Apart from the findings above, the rules held.
  - `CLOSED` is terminal in the table, only `rate` reaches it, and `satisfaction` is set only on that path.
  - `rate` sets `satisfaction` before `transition`, but `transition` cannot fail there because the status was just checked.
- The visibility rule in the README ("requester and agents") holds in `require_reader` on every handler. I found no path that reads or changes a ticket without it.
- I did not trace callers, storage or any HTTP layer, because none are in this change.

### Out of my lane
- `__pycache__/*.pyc` (four compiled files) are committed. They should not be in the change, and there is no `.gitignore`. No owner in the roster; scope-reviewer is the closest.
- There are no tests for the lifecycle, the rate-once rule or the reopen rules. That is test-reviewer's call.
