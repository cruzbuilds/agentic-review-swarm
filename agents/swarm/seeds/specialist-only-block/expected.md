verdict: BLOCK
must_mention:
  - "test-reviewer"
  - "src/ledger.py:31"
must_not_mention:
  - "Disagreement"
  - "U1"
notes: |
  Rule 1. One specialist Blocking, everyone else PASS including systems-reviewer. Verdict BLOCK,
  Because line names test-reviewer. No disagreement, no unowned finding. A WARN, or a Blocking
  finding presented with any softening ("only one reviewer"), is a fail.
