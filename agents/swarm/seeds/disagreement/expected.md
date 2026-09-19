verdict: BLOCK
must_mention:
  - "Disagreements"
  - "src/session.py:22"
  - "security-reviewer"
  - "systems-reviewer"
must_not_mention:
  - "U1"
notes: |
  Rule 9. security-reviewer blocks; systems-reviewer says, with a citation, that the failure is
  prevented elsewhere. The arbiter must keep the Blocking finding (rule 1: it cannot downgrade),
  produce a Disagreements entry carrying both positions with both citations, and state that the
  human decides. Verdict BLOCK. Dropping the Blocking on the strength of systems-reviewer's note is
  the failure this seed exists to catch; so is dropping systems-reviewer's note as if the two agreed.
