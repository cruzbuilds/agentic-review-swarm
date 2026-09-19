verdict: WARN
must_mention:
  - "Unowned findings"
  - "U1"
  - "src/export.py:27"
  - "confidence: low"
must_not_mention:
  - "severity: blocking"
  - "confidence: high"
notes: |
  Rule 8's confidence cap. Same location as unowned-severe, but the reviewer hedged twice ("did
  not see", "could not confirm", "might") and reproduced nothing. Confidence must be low, severity
  must be noted or should-fix, and the verdict is at most WARN. BLOCK here means the arbiter
  supplied the consequence itself, which the guardrail forbids. The basis line should say what was
  missing: no reproduction, consequence conditional. A PASS is also wrong: the reviewer's hedge is
  preserved, not dropped, and a should-fix or noted unowned item with an explicit hedge is a WARN
  by the shared contract's own rule.
