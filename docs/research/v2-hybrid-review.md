# V2: hybrid review. Research record

**Question this answers.** Does a review architecture that adds one whole-system reviewer beside the
existing specialists, and replaces the merge with an arbiter that reasons over the reviewers'
evidence, behave as designed: does the new reviewer stay in its mandate and reconstruct cross-system
defects, does the arbiter apply its rules, and does any of it regress what V1 did well? It does
**not** answer whether V2 finds more than V1; no comparison has been run.

**What preceded it.** [Experiment 001](experiment-001.md), and the reading of it in
[ADR 0006](../decisions/0006-systems-review-beside-the-specialists.md).

**Where the evidence lives.** [`docs/evals/systems-reviewer/run-001/`](../evals/systems-reviewer/run-001/),
[`docs/evals/swarm/run-001/`](../evals/swarm/run-001/), [`docs/evals/integrated/run-001/`](../evals/integrated/run-001/),
each with a `GRADING.md` and every raw report, frozen at the commits named in section 4 and below.
The chronological account is in [`eval-log.md`](../eval-log.md) from the 2026-09-19 entries onward.

**Status:** V2.0 implemented on `v2/hierarchical-review-model`, component-evaluated, integration-verified,
not yet used on real work, not yet compared with V1 on any subject. Sections are added, not
rewritten.

**Written against:** `c339a07` (2026-09-19); header and section 11 added at consolidation. Every
number below comes from a preserved artifact in this repository or in the Experiment 001 repository.

**Three things a reader should keep apart throughout.** A *mechanical* result is what the seed
runner's checks said (verdict matched, required terms present). *Behavioral* correctness is what the
preserved report shows the reviewer or arbiter actually did, read against its charter. *Architecture*
correctness is whether the design produces the intended behavior when the implementation is right.
Section 7 has four mechanical failures, zero behavioral failures, and zero architecture failures,
and this document never collapses those into one number.

**What came next.** [v3-agentic-investigation.md](v3-agentic-investigation.md), a question only.

---

## 1. Starting point: V1

V1 is the version tagged [`v1-experiment-final`](https://github.com/cruzbuilds/agentic-review-swarm/releases/tag/v1-experiment-final) (`a18fba7`). It is what Experiment 001 tested and it is preserved exactly.

**What it was.**

- Five specialist reviewers: `security-reviewer`, `test-reviewer`, `infra-reviewer`, `docs-reviewer`, `scope-reviewer`. Each a page of English (`charter.md`) naming what it blocks on, what it warns on, what it stays out of, and how it works. Plus `engagement-guide`, an interviewer, and `swarm`, the coordinator.
- Parallel, independent execution. Every reviewer received the same description of the change at the same time. No reviewer saw another's output. The charter said so explicitly: "Independence is what makes multiple perspectives worth having."
- Fixed mandates. The roster was hard-coded in the shared contract; each charter ended with a list of what that reviewer must not comment on. A reviewer that noticed something outside its lane wrote one line under "Out of my lane" naming the owning agent, or, if none owned it, "no owner in the roster."
- Simple merge. Any BLOCK is BLOCK; WARN if anything warned; PASS only if every reviewer passed. Duplicates merged with dual attribution. Findings grouped by file. Handoffs the owner did not report went under "Handoffs nobody picked up." The tools list was preserved. The orchestrator added nothing of its own and never dropped a finding.
- No systems-level reviewer, by decision. [ADR 0004](../decisions/0004-no-general-code-reviewer.md): a general reviewer has no lane, overlaps everyone, and buries the one thing only it noticed. "If a real gap shows up that none of the specialized agents cover, that's the signal to write a new specialized agent for that gap. Not a general one."
- No evidence-aware arbitration. The merge did not assign severity to anything, did not reason about whether two reviewers corroborated each other beyond tagging, did not record disagreement as such, did not cap the verdict when a reviewer was missing ("a swarm of three is still a swarm"), and had no route by which a "no owner" line could affect BLOCK/WARN/PASS.

**What V1 had demonstrated before Experiment 001.** Field use on [shelflife](https://github.com/cruzbuilds/shelflife): five pull requests, 37 findings, 14 blocking, 0 overridden, and by the author's count 21 of 33 actionable findings would have been missed reading the diff alone ([review log](https://github.com/cruzbuilds/shelflife/blob/main/docs/review-log.md)). It blocked changes to its own permissions twice and proved both blocks. 35 seeds passing. What it had not demonstrated: anything against a control. Nobody had checked what one general prompt would have found on the same code.

**Defects found in V1 by testing it.** Recorded in [`eval-log.md`](../eval-log.md): one reviewer invented a teammate to route a finding to; the built agent files were gitignored so nobody else could install them; two reviewers were declared without a shell and reviewed the working tree instead of the diff ([ADR 0005](../decisions/0005-reviewers-get-git-not-a-shell.md)); and during Experiment 001, all five reviewers ran the entire first condition with their tools silently denied, because `--allowedTools` omitted `Bash` (fix: `a18fba7`, the tagged commit; Experiment 001 `DEVIATIONS.md` D-003 and D-004). See section 9 for the state of that fix relative to the V2 branch.

## 2. What Experiment 001 established, and what it did not

Full record: [Five-Critics-or-One-Good-Prompt](https://github.com/cruzbuilds/Five-Critics-or-One-Good-Prompt), `ANALYSIS.md` sections 1 to 13. Subject: a three-tier TypeScript application generated from one paragraph and frozen at `b38c5b0` ([idea-log](https://github.com/cruzbuilds/idea-log)). Arms: A, one strong 170-word prompt; B, V1 at `7461982` (reading-only) and `a18fba7` (tools); C, twenty-four words with no domain map, added after A and B were analysed (D-005). Three runs per arm per condition. 79 distinct claims, each checked against the code. Predictions sealed at `9e2155d` before any run.

**Established, on that subject:**

| | C, naive | A, strong prompt | B, V1 swarm |
| --- | --- | --- | --- |
| Confirmed defects, all domains | 30 | 38 | 38 |
| Strict precision | 81% | 81% | 79% |
| Confirmed defects, the swarm's five domains | 18 | 24 | 35 |
| Same, without tests | 17 | 23 | 22 |
| Merge-blocking defects found, of 4 | 4 | 4 | 3 |
| The calibration defect (C26), as a finding | 3 of 3 | 5 of 6 | 0 of 6 |
| Security defects | 11 | 11 | 7 |
| Correctness defects | 10 | 11 | 3 |
| Findings seen in all three runs | 60% | 44% | 66% |
| Per-agent record of what was and was not checked | no | no | every run |

- The specialists tied the strong generalist and beat the naive one by eight moderate and hygiene items.
- The specialists' advantages were decomposition (thirteen module-level test items with assertions, every run, where each generalist said "no tests" once), repeatability, and the inspection record.
- The most consequential defect in the subject, predictions rewritable after the outcome is recorded, was noticed by `test-reviewer` in two of six swarm runs and placed under "Handoffs nobody picked up: no agent in the roster owns this." It never received a severity and never touched a verdict.
- Both generalists out-found `security-reviewer` inside its own lane. The reason is not established ([observation](../security-charter-observation.md)).
- Four of five sealed predictions failed, including the one the author called the sharpest.

**Not established:** that specialization improves defect coverage in general; that V1 is better or worse than a generalist on any other subject; anything about cost, since A and B were not instrumented; anything about tools, since the subject had nothing for most of them to run against; anything statistical, three runs describe stability. The subject was the kind V1 was least built for: a whole freshly generated repository with no engagement documents, no tests, no CI, almost no infrastructure.

## 3. The architectural hypothesis behind V2

The reading of Experiment 001 that motivated V2 is narrow, and it is stated here before any V2 result.

The specialists were not poor reviewers. Precision was equal across arms; the test reviewer's decomposition and the swarm's repeatability were real. What the architecture lacked was two things:

1. **Explicit ownership for defects that emerge across otherwise reasonable local operations.** C26 is a PATCH schema, a handler, and a calibration filter, each correct on its own page. No lane covered "the interaction between these three." The contract's answer, "no owner in the roster," was correct and terminal.
2. **A merge that reasoned about evidence.** The V1 orchestrator merged text. It did not consider provenance (who found it, independently or not), corroboration (how many did), disagreement (two reviewers, two severities), coverage (a reviewer missing or failed), or unowned findings (real, serious, nobody's). Everything that was not a Blocking or Should fix bullet from a chartered reviewer was invisible to the verdict.

The three-rule chain that lost C26: `test-reviewer`'s charter says correctness is not its job, "say so and move on"; the contract says route only to the roster, otherwise "no owner"; the orchestrator counts only Blocking and Should fix. Each rule is reasonable. Together they have one lane for text and one for verdicts, and unowned findings live in the wrong one.

**The V2 hypothesis:**

> Broad whole-system reasoning and specialist depth are complementary rather than mutually exclusive. A review architecture that has both, with an arbiter that keeps every serious finding visible regardless of lane, should recover the cross-cutting findings V1 lost while preserving what V1 demonstrably did well: decomposition, repeatability, lane hygiene, and the inspection record.

Recorded in [ADR 0006](../decisions/0006-systems-review-beside-the-specialists.md) before the systems reviewer's charter was written.

## 4. What V2 changed

Commits `c235736`, `53445c2`, `c6352b5` on `v2/hierarchical-review-model`. Branch point `b4732ea` on `main`.

```
                              the change (diff, branch, PR, or directory)
                                              |
            +-----------+-----------+---------+---------+-----------+-----------+
            |           |           |                   |           |           |
      +-----v----+ +----v-----+ +---v------+     +------v---+ +-----v----+ +----v------+
      | security | |  tests   | |  infra   |     |   docs   | |  scope   | | systems   |
      | reviewer | | reviewer | | reviewer |     | reviewer | | reviewer | | reviewer  |
      +-----+----+ +----+-----+ +---+------+     +------+---+ +-----+----+ +----+------+
            |           |           |                   |           |           |
            |   five specialists, charters unchanged from V1         |   new in V2: the lane
            |   each with Out of my lane: -> <agent> | -> no owner    |   none of them can have
            +-----------+-----------+---------+---------+-----------+-----------+
                                              |   six reports, nothing else
                                     +--------v--------+
                                     |     arbiter     |   the swarm command, phase 2
                                     | reports only.   |   may not open a file, run a tool,
                                     | no code access. |   or add a finding
                                     +--------+--------+
                                              |
                              +---------------+---------------+
                              |                               |
                      +-------v-------+             +---------v---------+
                      |   Findings    |             | Assurance record  |
                      | verdict + why |             | coverage, tools,  |
                      | blocking      |             | corroboration,    |
                      | should fix    |             | handoffs, unowned |
                      | UNOWNED       |             | by severity,      |
                      | DISAGREEMENTS |             | arbiter actions,  |
                      | noted         |             | verdict derivation|
                      +---------------+             +-------------------+
```

**Retained from V1, unchanged.** All five specialist charters. Parallel independent execution. Any reviewer's Blocking is BLOCK and the arbiter cannot downgrade it. Duplicates merge with attribution. Findings group by file. Tools preserved. Nothing dropped, nothing added. All-clean can PASS. The `engagement-guide`. The three-layer build (charter, adapter, dist). Seeds before real use.

**Added: `systems-reviewer`** ([charter](../../agents/systems-reviewer/charter.md)). Mandate: the failures that only exist when the pieces are put together. Five blocking categories, each defined as an interaction: a business invariant violated across individually valid steps; a state transition the design does not allow, reached by a locally valid operation (state A, valid operation, invalid state B); two correct modules that disagree about the data between them; an ownership model that holds per handler and fails across the workflow; a race, named as shared state, operation A, operation B, the interleaving, and the resulting state. An **eligibility rule** above all five: a BLOCK must require reasoning across a sequence, boundary, shared state, or interaction; a defect established from one local operation belongs to a specialist or is outside the mandate. A required **five-part finding shape**: invariant, interaction, why each local step looks valid, failure, fix. Exclusions: style, naming, test decomposition (test-reviewer does it better), specialist checklists, rewrites, and, after Run 001, any local defect it establishes without crossing a boundary, which goes to `-> no owner` and never to its own Should fix.

**Changed: two forms of Out of my lane** ([output-format.md](../../shared/output-format.md)). `-> <agent>`, one line, routed. `-> no owner`, with file, line, what is wrong, why it matters, and what to do, because the arbiter has to assign a severity from that text and will not open the file to strengthen it.

**Changed: the shared contract** ([review-contract.md](../../shared/review-contract.md)). `systems-reviewer` on the roster. One severity sentence for every reviewer: Blocking is a broken rule with a meaningful consequence for a user, data, money, or access; a broken rule with none is Should fix.

**Replaced: the merge, by an arbiter** ([swarm charter, phase 2](../../agents/swarm/charter.md)). Six rules kept from V1 and six new:

- **Provenance survives merging.** Independent discovery by two reviewers is tagged and counted. When a specialist reports the local symptom and the systems reviewer reports the interaction it belongs to, the merged finding is the interaction and the specialist's citation is kept inside it as a named step.
- **Unowned findings are findings.** Every `-> no owner` line and every routed handoff the owner did not report becomes an entry with the originating reviewer, the evidence as written, an arbiter-assigned severity and confidence, the reviewer's next action, and one line of basis. Confidence is defined by what the reviewer supplied: high needs a line plus a sequence or reproduction; medium a line and a described failure; low is hedged or lineless. **Elevation guardrail:** blocking only when the reviewer supplied a reproduction or deterministic sequence *and* explicitly stated a consequence for a user, data, money, or access, in its own words; the arbiter classifies that evidence and may not supply the consequence. Low confidence is never blocking; medium is at most should-fix. An unowned blocking finding makes the verdict BLOCK.
- **Disagreements are a section.** Both positions, both citations, the higher severity stands, one line on why, the human decides.
- **Coverage caps the verdict.** A configured reviewer not installed, failed, timed out, or saying the change is too big: the verdict cannot be PASS. No "PASS, 5 of 6."
- **The arbiter may not open a file, run a tool, or read the diff.** Reports are the whole input. Its two judgments, severity and confidence for unowned findings and reconciliation of disagreements, are bounded by the reports.
- **Two outputs.** Findings, for the developer. Assurance record, for whoever signs off: coverage, per-reviewer status and coverage statement, tools, corroboration count, handoffs picked up and not, unowned by severity, every arbiter action with its basis, verdict derivation.

**Not changed, on purpose.** No specialist charter, including security's ([why](../security-charter-observation.md)). No new specialists. No sequencing. No dynamic agent selection. The broad-first variant is recorded as V2.1 in [`design.md`](../design.md) and not built.

## 5. Systems-reviewer evaluation, Run 001

Commit under test `53445c2`. Runner `scripts/run-seeds.sh systems-reviewer`, one run per seed, 2026-09-19 03:19 to 03:24 UTC. Raw reports and matrix: [`evals/systems-reviewer/run-001/`](../evals/systems-reviewer/run-001/). Preserved at `a46d685` before any change.

**The six seeds.** Python, no dependencies, four to five files each, a README stating the invariant, every file locally reasonable.

| Seed | Category | The interaction |
| --- | --- | --- |
| `invariant-across-valid-steps` | 1 | Free plan allows 3 active projects; `create` enforces it; `restore` and `transfer` both raise the count and neither checks |
| `impossible-state-transition` | 2 | `apply_coupon` moves a PAID order back to PLACED with a sane docstring; `payment_id` survives; second capture double-charges, refund refuses |
| `modules-disagree-about-shared-data` | 3 | `None` for unfinished, read as 0 "so the page doesn't crash", janitor writes 0 for dead workers; p95 falls during a hang |
| `ownership-across-workflow` | 4 | Every handler checks correctly; `can_access` tests that a share token exists, never that the caller presented it; sequential ids |
| `race-corrupts-core-record` | 5 | `spend` locked; `top_up` unlocked with a true argument; whole-row `put` loses balance and ledger together so `reconcile` passes |
| `clean` | 6 | Tickets: one transition table, rate-once at RESOLVED, CSAT treats unrated as absent. Intended PASS |

**Results.**

| Seed | Expected | Actual | Interaction reconstructed | Five parts | Grade |
| --- | --- | --- | --- | --- | --- |
| invariant-across-valid-steps | BLOCK | BLOCK | both paths plus downgrade-then-restore | 5, one unlabeled | PASS |
| impossible-state-transition | BLOCK | BLOCK | exact sequence, both downstream failures | 5 | PASS |
| modules-disagree-about-shared-data | BLOCK | BLOCK | all three files; plus a second real interaction not designed in | 5 | PASS |
| ownership-across-workflow | BLOCK | BLOCK | existence vs possession, enumeration, 200-vs-404 leak | 5 | PASS |
| race-corrupts-core-record | BLOCK | BLOCK | shared row, both ops, interleaving, `reconcile` returns True | 5, ran it | PASS |
| clean | PASS | BLOCK | found a real one the author missed | 5, ran it | INVALID FIXTURE |

Mechanical: 6 of 6 verdicts extracted, every `must_mention` present, no `must_not_mention` in any finding section. Five of six reports ran a reproduction and described the result.

**Mandate drift.** Zero specialist checklist items in any Blocking section. Four local items across six reports (a hardcoded constant, a p95 index calculation, a falsy `user_id == 0`, an unmapped `KeyError`), all under Should fix or Noted, all labeled local by the reviewer itself, which had nowhere to route them: there is no roster entry for local correctness. Lane routing was correct every time, including a non-constant-time compare sent to security-reviewer and unused imports sent to "a linter, not any agent."

**Severity behavior.** Binary. Every interaction that broke a stated rule went to Blocking, including the clean fixture's, whose consequence is a ticket re-entering a queue without a message. The charter at `53445c2` gave no way to say "real interaction, mild consequence."

**The surprising result.** The reviewer found defects in three of the six fixtures that the author did not put there. In `clean`, `reopen` relied on `satisfaction is None` instead of checking for RESOLVED, and the shared transition table let a PENDING ticket return to OPEN with no reply, which the README and the function's own docstring both forbid. In `impossible-state-transition`, the README diagram allows CANCELLED only from PAID while `refund` accepts SHIPPED. In `modules-disagree-about-shared-data`, `finish` can overwrite the janitor's close-out, a second real category-2 interaction. A seed suite written by one person to test interaction reasoning was reviewed for interaction defects by the thing under test, and the author lost three times.

This is evidence that the mandate is doing nontrivial reasoning: the clean-fixture defect is an interaction between a handler's implicit assumption and a shared table's permissiveness, exactly the class the charter describes, and it was found by tracing rather than by matching a checklist. It is not evidence that V2 is better than V1. No V1 reviewer was run on these fixtures, no generalist was, and the fixtures were written by the person who wrote the charter. What it does mean is that the clean seed cannot measure false positives as written, and that the fixtures need the same review as the code they test.

**Harness contamination.** Every report flagged committed `__pycache__` files as "no owner in the roster." The author had import-checked the fixtures in place; the runner copied and committed the bytecode. Fixed in the runner at `02c97cd` after the run was frozen. The seed directories still contained the caches during the integrated run in section 7.

**Deferred from this run, not implemented at the time:** route local defects to `-> no owner` (implemented at `c6352b5` because the arbiter contract required it); one sentence of consequence-based severity (implemented in the shared contract at `c6352b5` for the same reason). The five fixture repairs are still pending.

## 6. Arbiter evaluation, Run 001

Commit under test `c6352b5`. Runner `scripts/run-seeds.sh swarm`, 2026-09-19 03:40 to 03:48 UTC. Raw reports and matrix: [`evals/swarm/run-001/`](../evals/swarm/run-001/). Preserved at `42197dc`.

**Method.** Eight deterministic seeds: a `reports/` directory of six saved reviewer reports in the shared format, a `prompt.md` saying to arbitrate them and not read source, and an `expected.md` naming the rule under test. The reports cite a fictional invoicing application whose source does not exist in the seed, so an arbiter that tried to open `src/auth.py` could not. Plus the V1 live seed `three-lanes`, now spawning six reviewers.

| Seed | Rule | Expected | Actual | What the arbiter did |
| --- | --- | --- | --- | --- |
| duplicate-broad-and-specialist | 7 | BLOCK | BLOCK | one merged Blocking tagged `[security-reviewer, systems-reviewer, raised independently]`, security's citation kept as "Step 2"; corroboration 1 |
| specialist-only-block | 1 | BLOCK | BLOCK | test-reviewer's Blocking stands; "five reviewers returned PASS, and under rule 1 they cannot outvote it" |
| systems-only-block | 1 | BLOCK | BLOCK | carried as a Blocking finding, not converted to unowned, not softened |
| unowned-severe | 8 + guardrail | BLOCK | BLOCK | U1 blocking/high; basis cites the reviewer's reproduction and stated consequence; "I supplied neither" |
| unowned-low | 8 cap | WARN | WARN | U1 should-fix/low; basis names the three hedges and what blocking would have needed |
| disagreement | 9 | BLOCK | BLOCK | Blocking kept; both positions with citations; "for the human to decide"; refused to open the file to resolve an ambiguity it noticed |
| reviewer-failed | 11 | WARN | WARN | coverage partial; Because names infra-reviewer and the timeout; names the lane that went unreviewed |
| all-clean | 6 | PASS | PASS | every reviewer and its tools in the table; corroboration 0; "what this PASS is worth" |
| three-lanes (live) | merge, 7, 8, 9 | BLOCK | BLOCK | 14 bullets from four reviewers merged to 12; static keys once with dual attribution; U1 assembled from four reviewers' handoffs that infra-reviewer missed, should-fix/medium with the guardrail cited; two disagreements recorded |

Nine of nine on verdict and on the rule under test. Every report carries "no files opened; no tools run."

**The severe-versus-low pair.** Same file and line, `src/export.py:27`, in both. With "I reproduced it: an account named `../../etc/cron.d/x` wrote outside the export directory" and "any customer who can rename their own account can write a file anywhere the service user can": blocking, high, verdict BLOCK. With "I did not see sanitizing," "I could not confirm," "might write": should-fix, low, verdict WARN. The guardrail classified the reviewer's evidence in both directions and the basis lines quote it.

**Compared with V1's handling of the same situation.** In V1, `three-lanes` produced "Handoffs nobody picked up" with the handoff text and no severity; the verdict was decided entirely by the specialists' Blocking sections. In V2 the same four handoffs became U1 with a severity, a confidence, four observers credited, the owning reviewer named as having missed it, and a stated basis. The finding has ownership (the arbiter's, with provenance), a route into the verdict (it did not reach it here because the evidence was medium), and an audit trail. That is the mechanism C26 needed. Whether it would have caught C26 on that subject is not tested: the systems reviewer's seeds are not the idea-log application and nobody has re-run Experiment 001's subject through V2.

**Calibration note, deferred.** In `three-lanes` the arbiter listed scope-reviewer's "I could not check this" as a disagreement with docs-reviewer's Blocking, then concluded "scope-reviewer disclaims having checked, so it is not a contrary finding." Right resolution, over-inclusive classification. One sentence in rule 9 would settle it. Not changed.

**Fixture defects the arbiter found from the reports alone.** The `disagreement` fixture has two contradictory coverage lines (generator appended boilerplate after a hand-written line) and cites `src/session.py` with `jwtVerify` and a `Uint8Array` in a fixture where `pip-audit` ran. Both are the author's. The arbiter recorded both without choosing and told the human to check. Left as they are.

## 7. Integrated V2 verification, Run 001

Commit under test `5514f27`. Every agent, every seed, one run: 35 V1 seeds, 6 systems-reviewer, 8 arbiter. 2026-09-19, about 03:55 to 04:50 UTC. `check.sh` passed first (secret scan, dist current, six reviewers can run git, every seed has an expectation). Raw reports, run log and grading: [`evals/integrated/run-001/`](../evals/integrated/run-001/). Preserved at `b6f0b5b`, classification completed at `c339a07`.

**49 reports. 45 mechanical passes. 4 mechanical failures. 0 implementation failures. 0 architecture failures. 0 observed V1 regressions.**

| Agent | Seeds | Passed | Failed |
| --- | --- | --- | --- |
| security-reviewer | 6 | 6 | |
| docs-reviewer | 6 | 6 | |
| infra-reviewer | 6 | 5 | `no-tags` |
| test-reviewer | 6 | 4 | `mocks-the-subject`, `no-test-for-new-branch` |
| scope-reviewer | 7 | 7 | |
| engagement-guide | 3 | 3 | |
| systems-reviewer | 6 | 6 | |
| swarm | 9 | 8 | `three-lanes` |

**The four failures, classified from the preserved reports.** The categories: *architecture* (the design produces the wrong behavior), *implementation* (the design is right, the code or prompt is not), *evaluation-definition* (the reviewer was right and the expectation was not), *fixture* (the seed has a defect), *harness* (the runner or its environment).

| Seed | What the preserved report shows | Class |
| --- | --- | --- |
| `infra-reviewer/no-tags` | WARN, wanted BLOCK. The reviewer found the missing tags and wrote "the charter's criterion is no tags, no name and no comment. There is a name here, so this is Should fix rather than Blocking." The charter says exactly that; the expectation wants BLOCK on "a tag or a meaningful name." It also found an IAM role referenced and never defined, so `terraform plan` fails, which the seed did not plant. | evaluation-definition, plus a fixture defect |
| `test-reviewer/mocks-the-subject` | BLOCK, correct planted defect, exact fix the expectation asks for. Wrote "patch" (the `unittest.mock.patch` API) throughout, never "mock." | evaluation-definition (term matching) |
| `test-reviewer/no-test-for-new-branch` | BLOCK, the exact test case wanted, the century boundary. Wrote "MM/DD/YY," never "two-digit." Also, under `-> no owner` with a reproduction: `parse_date("09/13/2026")` returns year 4026. | evaluation-definition (term matching), plus a fixture defect |
| `swarm/three-lanes` | BLOCK, correct arbitration. The required string `[security-reviewer` is at line 14 of the saved report and the runner's own `grep -qiF` matches it on replay. The report contains one `×` character; macOS BSD grep with `-i -F` on multibyte input reports no match. The same seed passed the same check three hours earlier with no non-ASCII in the report. | harness portability |

None of the four is an architecture or implementation failure. In each, the preserved report shows the reviewer or arbiter behaving as its charter says. V1 seeds at `v1-experiment-final` all passed; the two V1 reviewers whose failures were read in full show the V2 contract additions being used (the `-> no owner` form with a reproduction attached, from `test-reviewer`) without displacing lane behavior.

**systems-reviewer, second run.** Six of six mechanically. `clean` returned WARN instead of Run 001's BLOCK, with the same real defect under Should fix with the sequence and the fix. That is the consequence-based severity sentence, added at `c6352b5`, doing what it was for. The fixture is still not clean.

**Arbiter, second run.** Eight of eight deterministic. `three-lanes` correct on reading.

## 8. What V2 has and has not demonstrated

**Supported by the preserved evidence:**

- The systems reviewer follows its mandate on the current evaluations: five of five interaction seeds reconstructed with all five parts, zero checklist items in any Blocking section across twelve reports, the eligibility rule quoted back in two.
- It discovered interactions that were not intentionally planted, in three fixtures, one of which invalidated the clean seed.
- It declines to raise a finding where no invariant is stated: on `three-lanes` it noted the unconditional overwrite and said "not a finding," the false-positive behavior the broken clean seed could not measure.
- The arbiter follows its contract on the current evaluations: seventeen of seventeen deterministic arbitrations across two runs, the guardrail classifying the same location in both directions, the file-access prohibition held when opening a file would have resolved a real ambiguity.
- Previously dead-end handoffs become findings with severity, confidence, ownership and provenance: demonstrated on `three-lanes` (U1 from four reviewers) and `unowned-severe` (BLOCK from an unowned finding).
- V2 integrated without observed regressions in the specialist suite: 35 of 35 V1 seeds correct on reading, three mechanical misses all evaluation-definition or harness.
- The V2 mechanisms behave as designed.

**Not demonstrated, and not claimed:**

- That V2 finds more, or more important, defects than V1 on any subject. No comparison has been run.
- That V2 would have caught C26 on the Experiment 001 subject. Nobody has run that subject through V2.
- That the systems reviewer's false-positive rate is acceptable on real code. One live seed and one invalid clean fixture is not a measurement.
- Cost and latency. V2 evals record tokens; V1's did not; no review of a real pull request has been timed under V2.
- Behavior across broader real-world work. V2 has reviewed zero real pull requests.
- That the security lane result changes under V2. The specialist is unchanged and the systems reviewer's overlap with it is untested.
- Whether iterative investigation would add value beyond this architecture. Every reviewer still receives a task, investigates once, and returns a report; nothing inspects intermediate evidence and decides whether to continue. See section 10.

## 9. Contradictions and missing data, found while writing this

- **The tool-execution fix was not on the V2 branch until `745f155`.** `a18fba7` (the tagged V1 commit, which adds `Bash` to `review.sh`'s `--allowedTools` and the command allow list) was not an ancestor of `main` (`b4732ea`) or of `v2/hierarchical-review-model` through `c339a07` and the consolidation at `21c0e29`. `scripts/review.sh` on the V2 branch carried the `--allowedTools Read,Grep,Glob,Task` line, the D-003 defect, for that whole span. The intended history, stated in `design.md` and the lab, was tag, then merge of the fix, then V2 branch; the merge did not land until after consolidation. This did not affect any evaluation in this document, because `run-seeds.sh` has its own flags with `Bash` included and the reports show tools running. It would have affected any real review run through `review.sh` on the branch; none was run. Merged at `745f155` (one conflict, in `docs/eval-log.md`, resolved by placing the 2026-09-18 entry before the 2026-09-19 entries). The V2 baseline tag is placed on that merge commit, not on the consolidation, for this reason.
- **`design.md` and the lab's architecture history state that the fix sits between the tag and V2.** Both are wrong until the merge lands. Corrected in `design.md` in the same commit as this document; the lab is corrected separately.
- **The paper's section 4 says Experiment 001's tools condition ran the fix.** It did: the arms ran from the fix branch at `a18fba7`, recorded in `runs.csv`. The branch was simply never merged. No contradiction in the experiment; a contradiction in this repository's history.
- **The `must_mention` check is brittle to correct paraphrase**, and on macOS to any non-ASCII byte in the report. Two evaluation failures and one harness failure in the integrated run are this. Runner change pending.
- **Five fixture defects are known and unrepaired**, all found by the reviewers under test: `clean`'s `reopen`; the orders README versus `refund`; jobstats' second interaction; `no-tags`' undefined IAM role and its expectation versus the infra charter; `dates.py`'s four-digit year. One commit, after approval, with the earlier gradings left as they are.

## 10. The next question

V2 improved the architecture without adding hierarchy or iterative control. Every reviewer still receives a task, investigates once, and returns a report. The arbiter reasons over those reports and nothing else, by design. Nothing in the system inspects a reviewer's intermediate evidence and decides whether the investigation should continue, which tool it should reach for next, or whether its hypothesis should change.

Two moments in the record point at this. In Experiment 001, the single reviewer given tools ran a bcrypt timing benchmark and a 72-byte truncation reproduction on its own initiative, which turned a code-read claim into a demonstrated one. In the arbiter's `disagreement` seed, the right next step was obvious (open the file, settle which description of `session.py` is true) and the architecture forbids it, correctly, because the arbiter is not a reviewer. Nobody was chartered to go back and look.

**The next research question, recorded here and not yet designed:**

> Does review quality improve when static reviewers become managed investigators, able to gather evidence iteratively, choose tools, revise hypotheses, and be directed to continue when their evidence is incomplete?

That architecture is not implemented, not designed past this paragraph, and not the V2.1 variant (which is about ordering, not iteration). Before it, per the [roadmap](https://github.com/cruzbuilds/agentic-review-lab/blob/main/roadmap/README.md): use V2 on real pull requests, collect its failures into seeds, repair the fixtures, land the fix, and only then decide whether Experiment 002 compares V1 against V2, or V2 against whatever comes after this question.

## 11. After the frozen runs: hygiene, kept separate

Recorded so that a reader can tell what was changed after each run was frozen, and that none of it
was a change to a reviewer, the arbiter, a contract, or a fixture under test.

| Commit | What | Classified as |
| --- | --- | --- |
| `02c97cd` | `run-seeds.sh` strips `__pycache__` from a staged seed before it becomes a repository. After systems-reviewer Run 001 was frozen at `a46d685`. | harness hygiene |
| `1771099`, `5514f27` | README, design.md, marketplace and per-agent install lines for V2 and the current repository name. Between arbiter Run 001 and the integrated run. | documentation, distribution |
| `fdaf574` and the consolidation that follows it | Research record, navigation, this directory. | documentation |

| `745f155` | Merge of `a18fba7`, the tool-execution fix, into the V2 branch. After consolidation. `review.sh` on V2 now has `Bash` in `--allowedTools`. | fix landing, no new work |

Still pending, none done: five fixture repairs; the runner's
term check (`must_mention` synonym tolerance, and `LC_ALL=C` or a Python check for the macOS
`grep -iF` multibyte fault); the arbiter's rule 9 calibration sentence. When any of these lands, the
gradings in `docs/evals/` stay as graded and the change is logged in `eval-log.md`.
