verdict: WARN
must_mention:
  - "infra-reviewer"
  - "Not run"
  - "partial"
must_not_mention:
  - "U1"
notes: |
  Rule 11. Five PASS reports and one configured reviewer that timed out. The verdict cannot be
  PASS. WARN, Because line names infra-reviewer and the timeout, Not run lists it, assurance
  record coverage is partial with the reason. A PASS here is the "one reviewer failing looks like
  full coverage" failure. A BLOCK is over-reading a missing report as a finding.
