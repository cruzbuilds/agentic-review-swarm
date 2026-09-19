# Integrated V2 verification, Run 001

**Commit under test:** `5514f27` (V2.0 complete on `v2/hierarchical-review-model`: systems-reviewer,
arbiter contract, two-form Out of my lane, consequence-based severity, README and design docs,
marketplace; runner strips `__pycache__`).
**Runner:** `scripts/run-seeds.sh`, every agent, every seed, `SEED_KEEP_ALL=1`, 2026-09-19 ~03:55
to ~04:50 UTC. 49 seeds: 35 from V1, 6 systems-reviewer, 8 deterministic arbiter.
**Raw reports:** the 49 files beside this one plus `run.log`, unedited.
**Nothing was changed before grading.**

## Result

**45 passed, 4 failed.** `check.sh` passed before the run (secret scan, dist current, six reviewers
can run git, every seed has an expectation).

| Agent | Seeds | Passed | Failed |
| --- | --- | --- | --- |
| security-reviewer | 6 | 6 | 0 |
| docs-reviewer | 6 | 6 | 0 |
| infra-reviewer | 6 | 5 | 1: `no-tags` |
| test-reviewer | 6 | 4 | 2: `mocks-the-subject`, `no-test-for-new-branch` |
| scope-reviewer | 7 | 7 | 0 |
| engagement-guide | 3 | 3 | 0 |
| systems-reviewer | 6 | 6 | 0 |
| swarm | 9 | 8 | 1: `three-lanes` |

## The four failures, classified

Each was classified before anything was touched. Nothing has been touched.

### 1. `infra-reviewer/no-tags`: WARN, wanted BLOCK. Evaluation failure (expectation vs charter), not a regression.

The reviewer found the missing tags and said, in the finding itself: "The charter's criterion is no
tags, no name and no comment. There is a name here, so this is Should fix rather than Blocking."
The charter's Blocking item reads "A cloud resource with no tags, no name, and no comment." The
fixture's Lambda has a name (`fn-<random>`). The `expected.md` wants BLOCK "on the missing
identification (a tag or a meaningful name)." The seed and the charter disagree about whether a
random name is a name. The reviewer read the charter literally and was right to. Two other things
in the same report: it found a real fixture defect the seed author did not plant (the IAM role is
referenced and never defined, so `terraform plan` fails), and it ran `terraform fmt`, tried
`checkov` (certificate error, same as Experiment 001), and said which tools were absent. The
report is better than the expectation. **Not caused by V2:** neither the infra charter nor its
seeds changed; the shared-contract severity sentence ("Blocking is for a broken rule with a
meaningful consequence") points the same way the reviewer went.

### 2. `test-reviewer/mocks-the-subject`: BLOCK, missing term "mock". Evaluation failure (term matching), not a regression.

The reviewer identified the planted defect exactly: "The only test patches `notify.alert_if_over`,
the function it claims to test... It can never fail... Delete the patch. Patch `notify.send_alert`
instead," with the precise assertion the expectation asks for. It used the word "patch" throughout
and never "mock," so the `must_mention: mock` check failed. The runner's term check is a substring
match and "patch" is the correct term for `unittest.mock.patch`. The verdict, the finding, and the
fix are all correct. **Not caused by V2:** the test charter and seed are unchanged. This is a
non-determinism in word choice that the seed's `must_mention` list did not anticipate.

### 3. `test-reviewer/no-test-for-new-branch`: BLOCK, missing term "two-digit". Evaluation failure (term matching), not a regression.

The reviewer named the untested branch ("The new MM/DD/YY branch... has no test"), the exact case
the expectation wants (`parse_date("09/13/26")` asserting `date(2026, 9, 13)`), and the century
boundary the notes call "ideally" (`"12/31/99"`, `"01/01/00"`). It wrote "MM/DD/YY" and "century"
rather than "two-digit." Same class as failure 2. Also in this report, under the new `-> no owner`
form: the reviewer ran `parse_date("09/13/2026")`, got `4026-09-13`, and reported a correctness
defect with a reproduction. That is a V1 specialist using a V2 contract form correctly, on the first
run after the form was introduced, and finding a real bug the seed did not plant.

### 4. `swarm/three-lanes`: BLOCK, "missing: [security-reviewer". Harness failure, resolved on replay. Not a regression.

The saved report contains the literal `[security-reviewer` at line 14, and the runner's exact check
(`printf '%s' "$report" | grep -qiF -- '[security-reviewer'`) matches it, exit 0, when replayed on
GNU grep. It did not match on the Mac during the run. The one difference between this report and the
arbiter Run 001 report for the same seed, which passed the same check three hours earlier: this one
contains a single non-ASCII character, `×` (U+00D7), at line 113 in the assurance record ("U3 ×3").
macOS ships BSD grep, and BSD grep with `-i` and `-F` together on input containing a multibyte
character is a known failure mode: the case-insensitive fixed-string path mishandles multibyte input
and reports no match. The other report in this run with a non-ASCII character, `test-reviewer--clean`,
has no `must_mention` terms and so could not show the same fault.

Classification: **harness**, a portability defect in `run-seeds.sh`'s term check on macOS, triggered
by a reviewer writing `×`. The arbitration itself is correct on reading: 14 Blocking bullets merged
to 12 with dual attribution, an unowned finding assembled from four reviewers' handoffs, disagreements
recorded. Fix candidates, none applied: `LC_ALL=C` on the grep, or `grep -qi -e` with the term
escaped, or a Python check. Recorded for the fixture-and-harness commit.

## Regressions from V1

None found. Every V1 seed that failed did so on an expectation-versus-output mismatch that the
reviewer's own text shows to be a correct review: the infra reviewer applied its charter's literal
criterion; the test reviewer used "patch" for `mock.patch` and "MM/DD/YY" for two-digit years.
No V1 specialist charter changed. The two V1 reviewers whose reports were read in full show the V2
contract additions working (the `-> no owner` form, the severity sentence) without displacing
their lane behavior.

`systems-reviewer/clean` passed this time at WARN, because the runner accepts WARN for an expected
PASS. The reviewer found the same real defect in the fixture as in Run 001 and put it under Should
fix rather than Blocking, with the sequence and the fix. That is the consequence-based severity
sentence, added to the shared contract in `c6352b5`, doing what it was for: the interaction is real
and its consequence is a ticket re-entering a queue, so Should fix. The fixture is still not clean
and this pass does not make it so.

## Fixture and harness issues surfaced

- `infra-reviewer/seeds/no-tags`: `aws_iam_role.fn` referenced, never defined (reviewer finding).
- `infra-reviewer/seeds/no-tags/expected.md` and the infra charter disagree on whether a random
  name counts as identification.
- `test-reviewer/seeds/{mocks-the-subject,no-test-for-new-branch}/expected.md`: `must_mention`
  terms are one synonym each; the check is brittle to correct paraphrase.
- `test-reviewer/seeds/no-test-for-new-branch/dates.py`: accepts MM/DD/YYYY and returns year 4026
  (reviewer finding, reproduced).
- `scripts/run-seeds.sh`: `grep -qiF` on macOS fails on input with a multibyte character; replayed and confirmed on the saved report.
- `systems-reviewer/seeds/clean`: still not clean (Run 001).

None changed. All go to the fixture-repair list, one commit, after this run is frozen.

## Deferred calibration items, all still open

1. Arbiter rule 9: a reviewer's "I could not check this" is not a disagreement (arbiter Run 001).
2. Systems reviewer local-defect routing: now in the charter; first evidence it is being used came
   from a V1 specialist (`test-reviewer`), not from the systems reviewer, which had no local nit to
   route in this run. Watch on the next run.
3. Infra charter: "no tags, no name, and no comment" vs "no meaningful name." A charter question,
   not a V2 question. Recorded, not changed.
4. `must_mention` brittleness: consider synonym lists or a regex form in the runner. Harness, not
   architecture.

## Is V2 ready for Experiment 002?

The mechanism is: six reviewers run, the arbiter applies its rules, the two documents come out,
nothing regressed. What is not ready is everything that would make Experiment 002 honest: the
fixtures above need repair, the `three-lanes` failure is a macOS grep portability bug in the runner, and V2 has not been used on a
single real pull request. The protocol for Experiment 002 is a paragraph. The recommendation stands
as written in ADR 0006 and the lab roadmap: use V2 on real work first, collect its failures into
seeds the way V1's were, and design 002 with predictions sealed before deciding to spend the compute.
