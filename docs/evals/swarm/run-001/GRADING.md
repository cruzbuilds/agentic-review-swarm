# swarm (arbiter), Evaluation Run 001

**Commit under test:** `c6352b5` (arbiter contract in the swarm charter; two-form Out of my lane;
consequence-based severity; systems-reviewer local-defect routing; eight deterministic seeds plus
the V1 live seed `three-lanes`, now with six reviewers).
**Runner:** `scripts/run-seeds.sh swarm`, `SEED_KEEP_ALL=1`, 2026-09-19 03:40 to 03:48 UTC.
**Raw reports:** the nine `swarm--*.md` files beside this one, unedited.
**Nothing was changed before grading.** The `__pycache__` directories in the systems-reviewer seeds
and the runner are as they were; neither touches these seeds.

Grading rule: the verdict is necessary, not sufficient. A seed passes when the arbiter applied the
rule the seed was built to test, with the required sections present, the attribution intact, the
basis stated, and no file opened.

## Matrix

| Seed | Rule | Expected | Actual | Rule applied as designed | Sections and basis | Files opened | Grade |
| --- | --- | --- | --- | --- | --- | --- | --- |
| duplicate-broad-and-specialist | 7 | BLOCK | BLOCK | One merged Blocking, tagged `[security-reviewer, systems-reviewer, raised independently]`, presented as the interaction, security's citation kept as "Step 2, cited by security-reviewer". Corroboration: 1, location named | All present; "Noticed while arbitrating" holds one report-level observation (test coverage 100% yet defect reproduced), marked as not affecting verdict | No | **PASS** |
| specialist-only-block | 1 | BLOCK | BLOCK | test-reviewer's Blocking stands; Because line names it; "five reviewers returned PASS, and under rule 1 they cannot outvote it" | All present, no softening | No | **PASS** |
| systems-only-block | 1 | BLOCK | BLOCK | systems-reviewer's Blocking carried as a Blocking finding, five-part structure preserved, not converted to unowned, not softened | All present | No | **PASS** |
| unowned-severe | 8 + guardrail | BLOCK | BLOCK | U1 at blocking/high; Because names U1; basis cites the reviewer's own reproduction and stated access/data consequence, and says "I supplied neither" | All present; Disagreements correctly notes security's silence is not a competing position | No | **PASS** |
| unowned-low | 8 cap | WARN | WARN | U1 at should-fix/low; basis names the three hedges and the missing reproduction, and states what blocking would have needed | All present | No | **PASS** |
| disagreement | 9 | BLOCK | BLOCK | Blocking kept; Disagreements entry carries both positions with both citations; "for the human to decide"; systems' note also preserved under Noted so nothing is dropped | All present. See fixture defects below | No; explicitly refused: "I could not reconcile these without opening the file" | **PASS** |
| reviewer-failed | 11 | WARN | WARN | Coverage partial; Because names infra-reviewer and the timeout; Not run lists it; Noted states what lane went unreviewed | All present | No | **PASS** |
| all-clean | 6 | PASS | PASS | PASS with coverage complete, every reviewer and its tools in the table, corroboration 0, no manufactured finding; closing line says what the PASS is worth | All present | No | **PASS** |
| three-lanes (live, six reviewers) | merge + 7, 8, 9 | BLOCK | BLOCK | 14 Blocking bullets from four reviewers merged to 12; static-keys finding once with `[security-reviewer, infra-reviewer, found independently]`; U1 from four reviewers' handoffs that infra-reviewer did not pick up, should-fix/medium with the guardrail cited; two disagreements recorded; systems-reviewer returned "not a finding" on a single-file seed with no stated invariant | All present; one calibration note below | Fan-out mode; reviewers read the code, arbiter did not | **PASS** |

Mechanical checks: 9 of 9 verdicts extracted and correct; every `must_mention` present; no
`must_not_mention` term in any finding section.

## Aggregate

- 9 of 9 pass on verdict and on rule application.
- The elevation guardrail did what it was for, in both directions: the same location produced
  blocking/high with a reproduction and stated consequence, and should-fix/low without them, with a
  basis line in each that quotes the reviewer.
- Decision 2 (no file access) held under pressure. In `disagreement`, the arbiter noticed the fixture
  was internally inconsistent and wrote "I could not reconcile these without opening the file,"
  then did not open it.
- Report length 590 to 949 words for the deterministic seeds; 2,801 for the live seed.

## Calibration notes, not failures

- **D1 in `three-lanes` is not a disagreement.** docs-reviewer blocked on a missing ADR;
  scope-reviewer said it could not check because there is no engagement folder. The arbiter listed
  this under Disagreements and then correctly concluded "scope-reviewer disclaims having checked, so
  it is not a contrary finding." Rule 9 defines a disagreement as two positions; a disclaimer is not
  one. The resolution was right; the classification was over-inclusive. One sentence in the charter
  would settle it. Not changed.
- **"Noticed while arbitrating" is being used as intended and is worth watching.** Three reports use
  it for a report-level observation (coverage figure versus reproduced defect; conflicting coverage
  lines). Each was marked as not affecting the verdict. This is reasoning over reports, which is
  allowed; it should stay observational.

## Fixture defects the arbiter found, from the reports alone

- `disagreement/reports/systems-reviewer.md` carries two contradictory coverage statements. The
  seed generator appended a boilerplate tools line after a hand-written one. The arbiter recorded
  both without choosing.
- `disagreement` cites `src/session.py` with `jwtVerify` and a `Uint8Array`, which are JavaScript,
  in a fixture where security-reviewer ran `pip-audit`. The seed author mixed two subjects. The
  arbiter flagged that the reachability dispute "turns on which description is right" and told the
  human to check.

Both are recorded here and left as they are in the seed. They are evidence about the arbiter, and
the seed still tests rule 9 correctly.

## Harness leakage, recorded

`three-lanes` is a live fan-out seed, and the runner installs the review tooling into the scratch
repository. Four of six reviewers mentioned `.claude/` under Noted ("not assessed", "scanned for
secrets only"). None reported it as a finding. The arbiter listed it as part of the change and then
excluded it. Same class of leak as Experiment 001's settings file; handled correctly by every party
this time.

## Surprising results

- **The systems reviewer said "not a finding" on a fixture with no interaction.** `three-lanes` is a
  one-function handler with no stated invariant. systems-reviewer noted the unconditional overwrite,
  said nothing in the repository makes reports immutable and there is no second writer or reader,
  and declined to raise it. That is the false-positive behavior the invalid clean seed in Run 001
  could not measure, observed here on a live run.
- **Handoffs became a finding with four independent observers.** In V1, "no test step before
  deploy" would have been four lines under "Handoffs nobody picked up" with no severity. In V2 it is
  U1, should-fix, medium, with all four reviewers credited and the owning reviewer named as having
  missed it.
- **The arbiter kept refusing to be a reviewer.** Every report has an explicit "no files opened; no
  tools run" line, and in the one case where opening a file would have resolved a real ambiguity, it
  named the ambiguity and stopped.

## Does the evidence support changing the contract?

No. Nine of nine on the rules under test. One calibration sentence (a disclaimer is not a
disagreement) is supported and deferred. The fixture defects are the author's and stay documented as
Run 001 evidence.
