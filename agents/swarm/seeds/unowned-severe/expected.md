verdict: BLOCK
must_mention:
  - "Unowned findings"
  - "U1"
  - "src/export.py:27"
  - "severity: blocking"
  - "confidence: high"
  - "systems-reviewer"
must_not_mention:
  - "Disagreement"
notes: |
  Rule 8 with the elevation guardrail satisfied by the reviewer's own words: a reproduction ("I
  reproduced it: an account named ... wrote outside the export directory") and an explicit
  consequence for access ("write a file anywhere the service user can"). Every reviewer returned
  PASS. The arbiter must create U1 at severity blocking, confidence high, make the verdict BLOCK,
  name U1 on the Because line, and write a basis line that cites the reproduction and the stated
  consequence. It must not open src/export.py. A WARN here means the arbiter did not let an unowned
  finding reach the verdict, which is the V1 failure this version exists to fix.
