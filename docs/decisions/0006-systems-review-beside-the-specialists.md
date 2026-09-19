# 6. A systems reviewer beside the specialists, and an arbiter that can act on unowned findings

**Status:** Accepted, for V2.0
**Date:** 2026-09-19
**Supersedes:** the architectural assumption in [0004](0004-no-general-code-reviewer.md) that nothing crosses lanes. ADR 0004 stays in place as the V1 decision and its reasons still hold for the agent it described.

## Context

### What V1 believed

Comprehensive review decomposes into independent lanes. Five specialists with narrow charters and deeper instructions, run in parallel, each staying out of the others' lanes, merged by an orchestrator that adds nothing of its own. A general reviewer was rejected on purpose (0004): it has no lane, overlaps everyone, and buries the one thing only it noticed under twenty things everyone noticed. Anything that fell between lanes was to be reported as "no owner in the roster," surfaced under "Handoffs nobody picked up," and taken as the signal to write a new specialist.

### What Experiment 001 observed

The full record is [cruzbuilds/Five-Critics-or-One-Good-Prompt](https://github.com/cruzbuilds/Five-Critics-or-One-Good-Prompt), `ANALYSIS.md` section 13. The swarm was tested at [`v1-experiment-final`](https://github.com/cruzbuilds/agentic-review-swarm/releases/tag/v1-experiment-final) against one strong generalist prompt and one naive one, on a frozen application, three runs each.

- On confirmed defects the swarm tied the strong generalist, 38 to 38, and beat the naive one by eight moderate and hygiene items. Precision was the same across all three.
- The swarm's advantages were real and specific: the test reviewer decomposed "no tests" into thirteen module-level items with assertions, every run; the swarm was the most repeatable; and it produced the only per-agent record of what was checked, what could not run, and what was noticed but unowned.
- The most consequential defect in the subject, predictions rewritable after the outcome is recorded, was found by both generalists (five of six runs and three of three) and by no swarm run as a finding. The test reviewer noticed it in two runs. The merged report placed it under "Handoffs nobody picked up: no agent in the roster owns this." It never received a severity and never touched the verdict.
- Correctness findings overall: eleven and ten for the generalists, three for the swarm, and those three only because they touched a specialist's charter.
- Both generalists out-found the security specialist inside its own lane, eleven and eleven to seven.

### Why the finding was lost

Three V1 rules interacting, none of them wrong on its own. `test-reviewer`'s charter says correctness is not its job: "say so and move on." The contract says route only to the roster, otherwise write "no owner in the roster." The orchestrator's verdict counts only the Blocking and Should fix sections; "Handoffs nobody picked up" carries no severity and does not affect the verdict. V1's "never drop a finding" rule worked, which is why the text survived. The report has one lane for text and one lane for verdicts, and unowned findings live in the wrong one.

That is the mechanical part. The architectural part is that nothing in V1 is looking for behavior that emerges from interactions between files, states and handlers. The two runs that noticed it did so by accident, through an agent told not to care.

## Decision

V2.0 adds two things and changes one rule.

**A `systems-reviewer`.** One reviewer whose mandate is the class of failure created by interactions: correctness, business invariants, state transitions, cross-file behavior, component interactions, emergent behavior, the places where security, identity, data, state and business logic meet, and important problems that belong to no specialist. It is allowed to wander across files. It is told to stay out of style, naming, formatting, lint-level issues, README hygiene, test-coverage decomposition, and specialist checklist findings except where one is needed to explain a cross-system failure.

This is not the agent 0004 rejected. That agent was "a general code reviewer" with no lane that "comments on everything." This one has a mandate the specialists structurally cannot fill, and an exclusion list as binding as theirs. 0004's reason for rejecting a general reviewer, that it buries the one thing only it noticed, is answered by the arbiter, not by the lane rule.

**An arbiter in place of the merge.** The orchestrator keeps every V1 merge behavior: any specialist BLOCK is a BLOCK, duplicates merge with attribution, findings group by file, tools and reviewer failures stay visible, no finding is dropped, and it never adds findings of its own. It gains two narrow powers, documented in its charter and nowhere else: it assigns severity and confidence to an unowned finding, and it reconciles a disagreement between reviewers. It does not review from scratch. It produces two outputs instead of one: findings, and an assurance record.

**Unowned findings become first-class.** A finding no reviewer owns is no longer a handoff. It carries its originating reviewer, file and line and evidence where available, a severity, a confidence, an explanation, and a recommended next action, and it is eligible to affect the verdict. No owner is invented for it.

## Why specialists remain

Every property the swarm demonstrated in Experiment 001 came from specialization: the decomposition, the repeatability, the inspection record, the lane hygiene the generalists did not bother with. Removing lanes would throw those away to fix a problem that lane boundaries did not cause on their own. The specialists and their charters are unchanged in V2.0, including `security-reviewer`, whose observed limitation is documented separately in [docs/security-charter-observation.md](../security-charter-observation.md) and deliberately not tuned to the experiment.

## Why parallel independence remains

Experiment 001 did not show that parallelism was the problem. Precision was equal, the orchestrator's dedupe worked, and reports were already grouped and tiered. It showed a coverage gap and a synthesis gap. Independent parallel inspection is kept for three reasons: it is V1's own principle, that one reviewer's output must not shape another's input; it keeps V2's specialists comparable to V1's, so a later experiment can say which change helped; and the demonstrated failure does not need sequencing to fix. A broad-first, targeted-specialist execution model is recorded as a possible V2.1 variant in `docs/design.md`, to be evaluated as its own arm, not assumed.

## What is deliberately not changing yet

- No specialist charter. Not security, not tests, not docs, not infra, not scope.
- No new specialists. A specialist per defect Experiment 001 found would be tuning to a benchmark.
- No dynamic agent selection. The domains are known and fixed.
- No sequencing. Everything still runs at once.
- No change to what a specialist BLOCK means. The arbiter cannot downgrade one.
- No claim that V2 is better. It is a hypothesis with evals behind it. Whether it recovers the cross-cutting findings V1 lost while keeping what V1 did well is the question for Experiment 002, which has not been designed.

## Consequences

- One more reviewer per run. Roughly a fifth more tokens, to be measured rather than guessed.
- The systems reviewer will sometimes report something a specialist also reports. That is expected; the arbiter merges it with both attributions, and the overlap is a signal, not noise.
- The systems reviewer needs its own seeds, and they are a different shape: several files, each locally reasonable, with a defect that exists only in their interaction.
- The arbiter needs its own evals, and they must be deterministic: saved reviewer reports as input, not live reviewers.
- "Handoffs nobody picked up" ceases to exist as a section. What it held becomes either a routed handoff the owning specialist missed, which stays visible as such, or an unowned finding with a severity.
- ADR 0004 remains the record of what V1 believed and why. Its consequence "write a new specialized agent for that gap, not a general one" no longer applies; the rest of it does.
