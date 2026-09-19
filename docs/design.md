# Design

How this repository is shaped and why. The ADRs in `decisions/` hold the individual choices. This is the picture they add up to.

## What it is

Several AI reviewers examine the same change at once, independently. Five have a defined lane and a list of what they refuse to pass. One reasons about the system as a whole and owns what falls between the lanes. An arbiter turns their reports into one verdict, one findings list, and one assurance record. Agents criticize. People build.

That is V2. V1 was the five specialists and a merge, and the difference is the subject of [ADR 0006](decisions/0006-systems-review-beside-the-specialists.md). The rest of this document describes the repository as it is now and marks where V1 differed. The research record, with the evidence for each version, is [`research/README.md`](research/README.md); this document is about shape, not results.

## Three layers, kept apart

Most collections of agents are a folder of prompt files. This one separates three things that change for different reasons.

| Layer | What it is | Changes when |
| --- | --- | --- |
| Charter | What the agent is for, what it blocks on, what it stays out of. Plain markdown. No tool knows about it. | You learn something about reviewing |
| Adapter | A few lines of YAML frontmatter that make the charter a Claude Code agent or a Kiro agent. | A tool changes its format |
| Distribution | `marketplace.json`, the Kiro install script, the README index. | An agent is added or removed |

`scripts/build.sh` glues an adapter onto its charter, with the two shared contracts prepended, and writes the result to `dist/`. It's `cat` with a check mode. That's all it needs to be. The point is that the thinking lives in one file per agent and never gets edited in three places.

## Every agent has five parts

- **Mandate.** One sentence. What it's responsible for.
- **Blocks on.** Specific things that produce a BLOCK. Checkable. An agent that can only approve is decoration.
- **Tools.** Named, with flags. Where preferences get frozen instead of re-explained.
- **Out of lane.** What it must not comment on. Without this, every agent flags the same thing.
- **Output format.** Identical across agents, so reports can be merged instead of read one at a time.

The output format has a section called "Out of my lane." When an agent notices something that isn't its job, it goes there in one of two forms: routed to the agent that owns it, or `-> no owner` with enough detail (file, line, what, why, next action) for the arbiter to assign a severity. Findings don't get lost and agents don't step on each other. That one section is what makes a swarm work instead of a pile of agents talking over each other.

In V1 the second form existed as a phrase, "no owner in the roster," and the merge surfaced it under "Handoffs nobody picked up" with no severity and no route into the verdict. Experiment 001 showed that is where the most consequential finding in the study went. V2 made it a form with a shape and gave the arbiter a rule for it.

## Proving they work

Each agent has a `seeds/` folder. Each seed is a small folder with one planted defect and an `expected.md` saying what the correct verdict is and what the report must mention. Plus a clean seed with nothing wrong, because an agent that blocks everything is as useless as one that passes everything.

`scripts/run-seeds.sh` runs each agent against each of its seeds through the Claude Code CLI and checks the answer. That's an eval. It answers the question that otherwise never gets asked: is this agent real, or does it just sound sure of itself.

When an agent misses something on a real repository, that becomes a new seed.

Two seed shapes are new in V2. The systems reviewer's seeds are several files each, every file locally reasonable, with a defect that exists only in their interaction, and they are graded on whether the reviewer reconstructed the interaction rather than on the verdict alone. The arbiter's seeds are saved reviewer reports plus a prompt to arbitrate them, so the arbiter's rules can be tested deterministically. Every run is graded and preserved under `docs/evals/`, with the raw reports, including the runs where the reviewer found defects in the fixtures. Those stay as they were run; the fixtures are fixed in later commits and the earlier grading is not rewritten. The corpus grows from real failures.

## The roster and the order

| Agent | Job | Wave |
| --- | --- | --- |
| security-reviewer | Ways the change can be attacked or leak | 1 |
| docs-reviewer | Whether someone inheriting this could run, change, and remove it | 1 |
| infra-reviewer | Will it run, what does it cost, can it be torn down | 2 |
| swarm | Runs every configured reviewer at once; in V1 merged the reports, in V2 arbitrates them | 2, rewritten in V2 |
| test-reviewer | Is new behavior covered, would the tests fail if it broke | 3 |
| scope-reviewer | Does the change match what was agreed, was the reasoning recorded | 3 |
| engagement-guide | Interviews you to fill out intake, discovery, scope, handoff | 3 |
| systems-reviewer | Failures that exist only between the pieces: invariants, transitions, shared data, ownership across a workflow, races | V2 |

Wave 1 had a gate: install both agents into a real project and run them on a real change. If two agents can't produce a useful review, adding five more doesn't help. All three waves were built by 2026-09-14; the gate was passed on this repository's own engagement documents, and the full swarm reviewed real pull requests on shelflife.

The swarm orchestrator is wave 2 on purpose. There's nothing to orchestrate until at least two critics exist and have caught something.

V2 came from measurement rather than from a wave. Experiment 001 ([Five-Critics-or-One-Good-Prompt](https://github.com/cruzbuilds/Five-Critics-or-One-Good-Prompt)) tested the seven-agent V1, tagged `v1-experiment-final`, against one strong generalist prompt and one naive one. What it found is in ADR 0006 and, in full, in that repository's `ANALYSIS.md` section 13. The systems reviewer and the arbiter are the response.

## V1 and V2, side by side

| | V1 (`v1-experiment-final`) | V2.0 (this branch) |
| --- | --- | --- |
| Reviewers | 5 specialists | 5 specialists, unchanged, plus `systems-reviewer` |
| Execution | parallel, independent | parallel, independent, unchanged |
| Coordinator | merge: any BLOCK is BLOCK, dedupe with attribution, group by file, never drop | arbiter: all of that, plus severity and confidence for unowned findings, disagreements as a section, coverage caps, two outputs |
| A finding nobody owns | "Handoffs nobody picked up", no severity, cannot affect the verdict | `### Unowned findings`, severity and confidence assigned from the reviewer's evidence, can affect the verdict, cannot be blocking without a reproduction and a stated consequence |
| A configured reviewer missing | "a swarm of three is still a swarm"; PASS possible | verdict capped at WARN |
| Arbiter's access to the code | the merge could in principle read it; nothing said otherwise | forbidden; reports are the whole input |
| Output | one merged report | findings, then an assurance record |
| Evals | one seed per planted defect; one live swarm seed | plus multi-file interaction seeds and deterministic arbiter seeds |
| General reviewer | none, ADR 0004 | none in 0004's sense; a systems reviewer with a mandate and an exclusion list, ADR 0006 |

The history is meant to separate them in three: the tag holds V1 as tested; the tool-execution fix (`a18fba7`, the tagged commit itself) is a defect found while testing V1; everything on `v2/hierarchical-review-model` is V2. As of `c339a07` the second step has not landed: the fix branch was never merged into `main`, and the V2 branch was cut from `main` at `b4732ea` without it, so `scripts/review.sh` on V2 still carries the `--allowedTools` line that denied every tool in Experiment 001's first condition. The evaluations were unaffected (`run-seeds.sh` has its own flags), any real review through `review.sh` would be. Recorded in `docs/research/v2-hybrid-review.md` section 9; the merge is pending.

## V2.1, recorded and not built

A different execution model was considered for V2 and set aside: run the systems review first, and let what it finds steer which specialists run or where they look. It might be cheaper and sharper. It was not built because Experiment 001 did not show that parallelism was the problem, because sequencing breaks the independence that makes V2's specialists comparable with V1's, and because in Claude Code the orchestrator would have to hand-write hints into each specialist's prompt, which makes it a reviewer. It is recorded here as V2.1 so it can be evaluated as its own arm if V2.0's results warrant it. Nothing in the repository implements it.

## What's deliberately missing

A general code reviewer, still. See `decisions/0004` for the V1 reasoning and `decisions/0006` for why the systems reviewer is not that agent: it has a mandate the specialists cannot fill and an exclusion list as binding as theirs, and the burying problem 0004 worried about is answered by the arbiter, not by a lane rule.

Any change to a specialist charter in response to Experiment 001. The security specialist was out-found in its own lane by two generalists; the observation is in `docs/security-charter-observation.md` and the charter is unchanged so that V2 stays comparable with V1.

A Copilot adapter. The format is nearly identical and adding one is cheap. But it would be untested, and an untested adapter is worse than none.

Automatic runs in CI. First the agents run by hand, on demand, so their output gets read by a person while it's still being tuned.
