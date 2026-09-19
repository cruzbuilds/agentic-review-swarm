# systems-reviewer, Evaluation Run 001

**Commit under test:** `53445c2` (charter with eligibility rule and five-part finding shape; six seeds).
**Runner:** `scripts/run-seeds.sh systems-reviewer`, `SEED_KEEP_ALL=1`, 2026-09-19 03:19 to 03:24 UTC, one run per seed.
**Raw reports:** the six `systems-reviewer--*.md` files beside this one, unedited.
**Nothing was changed before grading.** Charter, seeds, expectations, runner and dist are as committed.

Grading rule: a correct verdict is not a pass. The seed passes when the reviewer reconstructs the
cross-file interaction the fixture was built to test, with all five parts of a systems finding
present (invariant, interaction, why each local step looks valid, resulting failure, fix).

## Matrix

| Seed | Expected | Actual | Interaction identified | Invariant | Interaction | Why local steps look valid | Failure | Fix | Local / specialist findings (drift) | Malformed vs reasoning | FP / FN | Grade |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| invariant-across-valid-steps | BLOCK | BLOCK | Yes, both paths: restore and transfer, plus downgrade-then-restore | Yes | Yes | Implicit (states what each check covers; no labeled section) | Yes, ran it, 4 and 6 active | Yes, one activation check on every path | Should fix: `billing.py` hardcodes 3 (local duplication); "newest first" wording (product/docs). Noted: bare `KeyError` (local, self-labeled) | Header `## systems-reviewer` missing; content well-formed | Neither | **PASS** |
| impossible-state-transition | BLOCK | BLOCK | Yes: PAID, apply_coupon, PLACED with live `payment_id`, second capture; also the unrefundable branch | Yes | Yes | Yes | Yes, both downstream failures | Yes, guard in `capture` plus coupon rule | Should fix: capture idempotency (hedged race); refund from SHIPPED vs README diagram (real fixture inconsistency); ship-before-write (hedged) | Well-formed | Neither | **PASS** |
| modules-disagree-about-shared-data | BLOCK | BLOCK | Yes: None/0 across all three files, p95 falls during a hang; plus a second real interaction (finish overwrites janitor's cancel) the fixture did not intend | Yes | Yes | Yes | Yes, ran 20+5 window, breached=False | Yes, exclude and count separately | Should fix: p95 index arithmetic (local, self-labeled "local arithmetic question"); empty-window returns healthy (product); dict-mutation race (hedged) | Well-formed | Neither | **PASS** |
| ownership-across-workflow | BLOCK | BLOCK | Yes: `can_access` tests token existence not possession; enumeration by sequential id; 200-vs-404 leak | Yes | Yes | Yes | Yes | Yes, one shared check taking the presented token | Should fix: falsy `user_id == 0` (local, framed as two functions disagreeing); comments survive revoke (product, hedged). Out of lane: `==` compare routed to security-reviewer, unused imports to linter | Header missing; content well-formed | Neither | **PASS** |
| race-corrupts-core-record | BLOCK | BLOCK | Yes: shared row, `spend` locked, `top_up` unlocked, concrete interleaving, whole-row lost update, `reconcile` returns True | Yes | Yes | Yes | Yes, ran it | Yes, lock in `top_up` or atomic apply in Store | Should fix: `create()` on existing id (hedged); `KeyError` mapping (local, low confidence, self-labeled) | Well-formed | Neither | **PASS** |
| clean | PASS | BLOCK | Found a real interaction the author missed: `reopen` from PENDING via the shared transition table, contradicting README ("PENDING to OPEN when the requester replies") and its own docstring ("only from RESOLVED") | Yes | Yes | Yes | Yes, ran it | Yes | Should fix: rate/reopen race (hedged, no store); `weekly_csat` has no timestamp to filter on (real gap); reply on RESOLVED changes nothing (product) | Header missing; content well-formed | **Not a false positive.** The fixture is not clean. | **INVALID FIXTURE** (reviewer: correct on substance; severity arguable) |

Mechanical checks: all six verdicts extracted; every `must_mention` term present in all six; no `must_not_mention` term appeared in any finding section.

## Aggregate

- Defect seeds: 5 of 5 BLOCK with the intended interaction reconstructed and all five parts present. 4 of 5 with every part explicitly labeled; 1 with "why each step looks fine" present but unlabeled.
- Clean seed: cannot be graded as a false-positive test, because the reviewer found a real defect in it. The fixture's `reopen` does not check `status == "RESOLVED"`; it relies on `satisfaction is None`, and the shared transition table permits PENDING to OPEN for the reply path. The author (me) missed it. The README and the docstring both state the rule the code breaks.
- Two further fixture-authoring inconsistencies surfaced by the reviewer: the orders README diagram shows CANCELLED only from PAID while `payments.refund` accepts SHIPPED; and the jobstats fixture has a second real interaction (`finish` overwriting the janitor's close-out) that was not designed in but is a legitimate category-2 finding.
- Reproductions: 5 of 6 reports say "I ran it" for the blocking finding and describe the result; one used `PYTHONDONTWRITEBYTECODE=1` unprompted to avoid touching the tree.
- Report length: 680 to 859 words. Every finding cites file and line.

## Recurring reasoning patterns

1. **Speculative concurrency in Should fix, always hedged.** 4 of 6 reports carry a Should fix race or ordering item on a fixture that has no persistence or transport layer, each ending in "I could not confirm this" or equivalent. The tightened race rule kept all of them out of Blocking, which is what it was for. They remain within the warn tier's "describe the failure, say what you would need" allowance. They are also the least useful lines in the reports.
2. **Local defects the reviewer knows are local still land in Should fix or Noted.** `billing.py` hardcoding 3; the p95 index arithmetic ("a local arithmetic question, so I have not marked it blocking"); `user_id == 0` truthiness; `KeyError` not mapped. In every case the reviewer labeled it local and kept it anyway. The charter says local defects belong to a specialist or are outside the mandate. There is no specialist for a local correctness defect, so the reviewer has nowhere to send it and keeps it. This is the ADR 0004 gap reappearing one level down.
3. **Severity is binary in practice.** Every interaction that breaks a stated rule went to Blocking, including the clean fixture's `reopen` path, whose consequence is a ticket re-entering a queue without a message. The charter gives the reviewer no way to say "real interaction, low consequence." A human reviewer would call that Should fix.
4. **Product-decision items are correctly labeled but not consistently placed.** "Which one is a product decision" appears in three reports, sometimes under Should fix, sometimes under Noted.

## Recurring mandate drift

Mild, and self-aware. No specialist checklist item appeared in any Blocking section. The drift is confined to Should fix and Noted, is always labeled local by the reviewer itself, and totals four items across six reports. Lane routing in Out of my lane was correct every time: tests to test-reviewer, README gaps to docs-reviewer, a non-constant-time compare to security-reviewer, unused imports to "a linter, not any agent."

## Harness contamination, recorded

Every one of the six reports flagged committed `__pycache__/*.pyc` files under Out of my lane as "no owner in the roster." The bytecode was created when the seed author ran `python3 -c "import ..."` inside each seed directory to check the fixtures imported; the runner then copied the directory and committed everything in the scratch repo. The reviewer was right that they were there and right that nobody owns them. Same class of leak as the `.claude/settings.json` in Experiment 001. Fix belongs in the runner (exclude `__pycache__`) and in the author's habit, not in the charter.

## Output format

Three of six reports omit the `## systems-reviewer` heading line and begin at `**Verdict:**`. All other sections are present and in order. The runner extracted every verdict. Likely cause: the seed prompt asks the main session to use the subagent and relay its report, and the relay sometimes drops the heading. Minor; the arbiter will need to tolerate it or the runner should assert it.

## Surprising results

- **The reviewer found defects the author did not put there, in three fixtures.** Two are real and one is a documentation inconsistency. A seed suite written by one person to test interaction reasoning was itself reviewed for interaction defects by the thing under test, and lost. This is the strongest evidence in the run that the mandate is real, and it is also the reason the clean seed is unusable as written.
- **The tightened race rule held on the first try.** No generic "could have a race" reached Blocking. Every hedged concurrency item stayed in Should fix with an explicit "cannot confirm."
- **The eligibility rule was quoted back.** Two reports explicitly kept a finding out of Blocking on the grounds that it was local. The rule is being applied, not just read.

## Does the evidence support changing the charter?

Not the mandate. Five of five defect seeds passed on reasoning, the clean-seed BLOCK was a true positive, and no checklist item reached a blocking section. The mandate is doing what it was written to do.

Two narrow gaps are supported by this run, both about where things go rather than what the reviewer looks for:

1. Local defects with no owner. The charter says "hand it off" but there is no roster entry for local correctness. The reviewer resolves this by keeping the item in Should fix. The V2 arbiter's unowned-finding path exists for exactly this; the charter should say that a local correctness defect goes under Out of my lane as "no owner in the roster" so it arrives at the arbiter as an unowned finding with low severity, and Blocking and Should fix stay purely interactional.
2. Severity for real-but-mild interactions. The charter needs one sentence separating a broken promise with a user-visible consequence (Blocking) from a broken rule with no data, access or money consequence (Should fix).

Neither is implemented. Both wait on the arbiter contract, which is the next step, because the first one depends on it.

## Fixture changes required before Run 002

- `clean`: make `reopen` require `status == "RESOLVED"`; the seed author will re-trace every path before claiming it clean, and the reviewer's report from this run is the checklist.
- `impossible-state-transition`: README diagram must show CANCELLED reachable from SHIPPED, or `refund` must stop accepting it. Either is fine; they must agree.
- `modules-disagree-about-shared-data`: either guard `finish` against a closed run, so the fixture tests one interaction, or add the second interaction to `expected.md` as a legitimate alternate finding. Preference: add it to `expected.md`; a fixture with two real interactions is closer to real code.
- All seeds: remove `__pycache__` directories; runner to exclude them.
