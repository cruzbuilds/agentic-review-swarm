# Research record

How this review system evolved, what each step was tested against, and what the evidence did and did
not show. Read this page first; each stage links to one document, and each of those says what
question it answers, what preceded it, where its evidence lives, what is and is not supported, and
what came next.

The convention for the whole repository:

```
implementation      = the working tree, the current version only
git history / tags  = every earlier implementation, exactly as it was tested
research docs       = why each version existed and what happened (this directory)
docs/evals/         = the evidence: graded runs with their raw reports, frozen
docs/research/paper.md = the synthesis, a living draft
README.md           = navigation and the story in brief
```

Nothing under `docs/evals/` is edited after it is frozen. When a later commit fixes something a run
found, the run's grading still says what it said.

## The progression

```
Stage 0   Simple prompt
          code -> one general review prompt -> findings
                |
                v
Stage 1   Structured prompt
          code -> one call with substantially more guidance -> findings
                |
                v
Stage 2   V1: parallel specialists
          code -> fan out to five narrow reviewers -> merge
                |
                |  Experiment 001: the specialists tie one prompt, beat the other on hygiene,
                |  and file the most consequential defect under "nobody owns this"
                v
Stage 3   V2: specialists + systems reviewer + evidence-aware arbiter
          code -> six independent reviewers -> arbiter -> findings + assurance record
                |
                |  component evaluations and an integrated run: mechanisms behave as designed;
                |  no comparison with V1 yet; no real pull requests yet
                v
NEXT      V3: agentic investigation (proposed, not built)
          a manager that decides, from intermediate evidence, whether each investigator continues
```

| Stage | What | Where the record is | What it is measured by |
| --- | --- | --- | --- |
| 0 | One general prompt, twenty-four words | Arm C of [Experiment 001](experiment-001.md) | 30 confirmed defects, 81% precision, every merge-blocking defect every run |
| 1 | One structured prompt, 170 words | Arm A of [Experiment 001](experiment-001.md) | 38 confirmed, 81%, eight more than stage 0, none high-value, less repeatable |
| 2 | V1, five specialists in parallel, simple merge | [Experiment 001](experiment-001.md); code at [`v1-experiment-final`](https://github.com/cruzbuilds/agentic-review-swarm/releases/tag/v1-experiment-final) | 38 confirmed, 79%, most repeatable, only inspection record; C26 unowned |
| 3 | V2, specialists + `systems-reviewer` + arbiter | [v2-hybrid-review.md](v2-hybrid-review.md); code on `v2/hierarchical-review-model` | systems-reviewer 5/5 interactions; arbiter 17/17; integrated 45/49 mechanical, 0 implementation failures, 0 V1 regressions |
| next | V3, managed investigators | [v3-agentic-investigation.md](v3-agentic-investigation.md) | nothing; not built |

Stages 0 and 1 were never separate builds. They are the two generalist arms of Experiment 001, and
they are in this table because the experiment's most useful result was that most of what V1 was
built to add was already in the model at stage 0.

## What each transition was

**0 to 1.** More direction in one call. Bought eight hygiene findings, cost consistency and doubled
the report. Did not buy high-value detection, which stage 0 already had.

**1 to 2.** Decomposition into lanes with written charters, run independently, merged. Bought
repeatability, a thirteen-item test work list where one generalist said "no tests" once, and a
per-agent record of what was checked. Cost: correctness had no lane, so the worst defect in the
subject was noticed and filed as unowned; the security lane was out-found by both generalists.

**2 to 3.** Not more agents. A reading of the evidence: the specialists performed locally and the
system still missed what crossed boundaries, and simple merging did not reason over the combined
evidence. So: one reviewer whose lane is interactions, with an eligibility rule that forbids local
findings; and an arbiter that gives unowned findings severity and confidence from the reviewer's
own evidence, records disagreements, caps the verdict on incomplete coverage, and cannot open a file.
Specialists unchanged, parallelism unchanged, so V2 stays comparable with V1.

**3 to next.** Every version so far fixes the execution graph before any evidence exists; a reviewer
investigates once and returns. The question is whether letting intermediate evidence decide what
happens next improves the review, at what cost. Recorded as a question.

## The thread through all of it: who decides what happens next

```
Simple prompt       a human decides the single call
Structured prompt   a human still decides the single call
V1                  the workflow decides a fixed parallel graph
V2                  the workflow still decides execution; synthesis becomes evidence-aware
V3 (proposed)       intermediate evidence begins deciding subsequent execution
```

## Documents in this directory

| File | Canonical for |
| --- | --- |
| [experiment-001.md](experiment-001.md) | Experiment 001 as it bears on this repository: design, numbers, what is and is not supported, links into the experiment's own repository, which holds the raw record |
| [v2-hybrid-review.md](v2-hybrid-review.md) | V2: starting point, hypothesis, what changed, every evaluation run with its numbers, demonstrated versus not, contradictions found, the next question |
| [v3-agentic-investigation.md](v3-agentic-investigation.md) | The proposed next architecture and the question it would test. Not built |
| [paper.md](paper.md) | The synthesis, in the author's voice, kept chronological: question, V1, Experiment 001, diagnosis, V2, evaluations, remaining question |

Related, outside this directory: [`../design.md`](../design.md) for the shape of the repository and
the V1/V2 comparison table; [`../decisions/`](../decisions/) for each choice, where
[0004](../decisions/0004-no-general-code-reviewer.md) is V1's and
[0006](../decisions/0006-systems-review-beside-the-specialists.md) is V2's;
[`../eval-log.md`](../eval-log.md) for the chronological log of what evaluation found, from the first
seed run on 2026-09-13; [`../evals/`](../evals/) for the frozen runs;
[`../security-charter-observation.md`](../security-charter-observation.md) for the one specialist
result that is observed and deliberately not acted on.

## Historical references

| Reference | What it holds |
| --- | --- |
| tag `v1-experiment-final` (`a18fba7`) | V1 exactly as Experiment 001's tools condition ran it. Includes the tool-execution fix. |
| `7461982` | V1 as the reading-only condition ran it, before the fix. |
| `b4732ea` on `main` | Branch point of V2. Does not include `a18fba7`; see the contradiction recorded in [v2-hybrid-review.md](v2-hybrid-review.md#9-contradictions-and-missing-data-found-while-writing-this). |
| `c235736` | ADR 0006, `systems-reviewer` charter, security observation |
| `53445c2` | `systems-reviewer` eligibility rule, finding shape, six interaction seeds |
| `a46d685` | systems-reviewer Run 001 frozen: raw reports, grading, eval-log entry |
| `c6352b5` | Arbiter contract, two-form Out of my lane, severity sentence, eight arbiter seeds |
| `42197dc` | Arbiter Run 001 frozen |
| `02c97cd` | Hygiene: runner strips `__pycache__`. Separate from the runs it followed. |
| `1771099`, `5514f27` | README, design.md, marketplace for V2 |
| `b6f0b5b`, `c339a07` | Integrated Run 001 frozen, then the `three-lanes` failure replayed and classified |
| `fdaf574` | First research record and README navigation |
| `21c0e29` | Consolidation: `docs/research/` as the canonical record, README navigation chain |
| `745f155` | Merge of the tool-execution fix (`a18fba7`) into V2, after consolidation; the V2 baseline tag goes here |
| Experiment 001 repository | predictions `9e2155d`; subject `b38c5b0`; see [experiment-001.md](experiment-001.md) |
