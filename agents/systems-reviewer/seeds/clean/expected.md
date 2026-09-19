verdict: PASS
notes: |
  Category 6: clean. The invariants hold along every path.

  Status changes go through one function with an explicit transition table, so no handler can
  produce a transition the README does not list. CLOSED is terminal and reply() refuses it
  before touching messages. The satisfaction score is written once, only from RESOLVED, only
  by the requester, and rating closes the ticket, so it cannot be changed after it counts.
  reopen() refuses a rated ticket, so RESOLVED -> OPEN cannot carry a score back into an open
  ticket. The CSAT report treats unrated as absent, not zero, which agrees with the writer.
  Access is checked in one place with one rule.

  This seed exists to catch a systems reviewer that manufactures an emergent failure from
  clean code. Correct behavior: PASS. A WARN with a real, specific interaction the author
  missed is acceptable and should be reported back so the seed can be fixed. BLOCK is a
  failure.

  Things a drifting reviewer might say that are not findings here: "no tests" (test-reviewer),
  "TRANSITIONS should be an enum" (style), "no rate limiting" (security, and not this
  fixture's concern), "sequential ids" (nothing here is reachable by id alone).
