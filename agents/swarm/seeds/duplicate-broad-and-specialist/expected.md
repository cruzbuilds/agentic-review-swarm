verdict: BLOCK
must_mention:
  - "security-reviewer"
  - "systems-reviewer"
  - "src/auth.py:40"
  - "src/billing.py:55"
  - "Corroboration"
must_not_mention:
  - "U1"
notes: |
  Rule 7. security-reviewer reports the local symptom at src/auth.py:40; systems-reviewer reports
  the interaction that symptom is step 2 of. The arbiter must produce ONE Blocking finding, tagged
  with both reviewers, presented as the interaction, with the specialist's citation kept inside it
  as a step. The assurance record's corroboration count must be 1 and name the location. Two
  separate Blocking entries for the same defect is a fail; one entry with only one name is a fail.
  There is no unowned finding here, so no U-item.
