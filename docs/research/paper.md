# AI is not wrong. It needs direction.

**A field test of what kind of direction turns AI-written code into something a person can verify.
Five specialized reviewers against one good general prompt, on code neither of them had seen.**

Chris Cruz · started 2026-09-17 · Experiment 001 closed 2026-09-19 · V2 built and evaluated 2026-09-19

---

> **How this draft works.** Sections marked DRAFT are written and may still be edited for prose, not
> for substance. The results went in the way they came out. The swarm did not win, and this paper says
> so.
>
> Quotes attributed to Chris are his own words from the working interviews, lightly trimmed for length
> and never reworded.
>
> **Experiment 001 is closed. V2 is built.** Sections 6 through 12 are written from `ANALYSIS.md`
> sections 1 to 13 in the study repository; every number can be regenerated from `findings/`.
> Sections 13 through 17 cover what happened after: the V2 hypothesis, what was built, what the
> evaluations showed, and the question that is left. Every number there is from a graded run
> preserved under `docs/evals/` in this repository. Section 11 was written before V2 existed and
> is kept as written.
>
> **Where this lives.** The canonical copy is `docs/research/paper.md` in
> [agentic-review-swarm](https://github.com/cruzbuilds/agentic-review-swarm). The research map that
> puts it in order with the experiment records is [`docs/research/README.md`](README.md).

---

## Abstract

DRAFT.

I vibe-coded a three-tier TypeScript application from one paragraph, froze it, and had three things
review it: my five-agent specialist swarm, one general reviewer given a strong 170-word prompt, and,
added after I had seen those results, one general reviewer given twenty-four words and no domain map.
Same model, same commit, three runs each. Seventy-nine distinct claims came back. I checked every
one against the code.

The hypothesis was that five specialists with deeper instructions would beat one generalist. They
did not. The swarm and the strong generalist tied at 38 confirmed defects, the naive generalist found
30, and precision was about 80% for all three. The naive prompt found every merge-blocking defect in
every run. The swarm's real advantage was narrower and more useful than the hypothesis: it turned
"there are no tests" into thirteen module-level items with assertions, every run, and it produced
the only per-agent record of what was checked, what could not be run, and what was noticed but owned
by nobody.

That last bucket is where the most consequential defect in the codebase went. A logic flaw that lets
a user falsify the product's core metric was found by both generalists, noticed by a swarm agent in
two runs, and filed as unowned because no specialist lane covered it. The architecture, not the
model, lost it. Four of five sealed predictions failed. The result of Experiment 001 is a different
architecture, proposed here as a hypothesis and not yet tested.

## 1. The thesis, and the day it arrived

DRAFT.

I did not start with a thesis. I started with an objection I kept hearing at a conference, from people
in different industries and different sized companies who had no reason to be comparing notes.

> "We can't trust AI and we don't want our dev team using AI coding tools, because we can't trust the
> output."

Same sentence, nearly word for word, all week. When a concern shows up that consistently across
organizations that do not talk to one another, it is not a preference. It is a missing control.

My first instinct was to build agentic development, agents that write the code. I dropped it fairly
quickly, because Claude and Kiro already write decent code. Generation was not the gap. If the code is
fine and the blocker is that nobody trusts it, the thing worth building is whatever makes a customer
comfortable with their own developers using these tools. That is a review problem.

Then, on the first day of this experiment, the thing I was going to argue happened in front of me, by
accident, in the build I was only supposed to be producing as a specimen.

### What the agent did, and what it left behind

The coding agent finished and told me the application was "fully smoke-tested," and at the commit
prompt, "tested end-to-end, and ready." It then described, unprompted, exactly what it had done:

> "I tested the full flow with curl against a live dev server: register/login, cross-user privacy
> (404s, not leaky 403s), create/rank ideas, record hindsight, share/revoke a link, and confirmed
> unauthenticated requests get redirected or 401'd correctly."

That is a real test plan. It covers cross-user privacy, which is the thing that matters most in an
application whose whole promise is that your ideas are yours. Nobody asked it to do any of it.

The repository contains no test file, no test framework, and no `test` script. `pnpm test` exits 1
with nothing to run. Every one of those checks happened in a terminal session that no longer exists.

**The capability was there. The instruction was not.**

That reframed the paper. I had expected to find that a fast build skips testing, which is the easy
story about AI-written code. What I found was an agent that tested competently and left no evidence,
which is not an AI failure at all. It is the oldest process failure in software. I have worked with
engineers who tested carefully, fixed what they found, and wrote none of it down. The work was real.
Six months later nobody could prove it happened, so in practice it did not.

And it matters twice. An engineer inheriting that repository sees no tests and concludes either that
nothing was tested or that nothing can be reproduced. Both conclusions are wrong about the effort and
right about the consequence. The agent's own summary makes it worse rather than better, because
"tested end-to-end" in a handoff means a suite you can run, and here it meant curl in a scrollback
buffer. If someone handed me that at the end of an engagement, I would not have blinked.

One detail cuts the other way and belongs here rather than in a footnote: **every claim the agent made
that a tool could verify was true.** `tsc`, eslint and `next build` are clean, exactly as promised. It
overstated only the thing no tool checks. That is probably not a coincidence, and it says something
about where direction is most needed.

### The claim, stated so it can lose

"AI needs direction" is too comfortable to be a thesis. Any result confirms it, which means it says
nothing, and a reader is right to distrust a claim that cannot fail.

So the sharper version, written before any results:

> **Direction is what converts capability into evidence, and how much direction is required is an
> empirical question.**

The build is the zero-direction case: real work, no record. A single good review prompt is some
direction. My swarm is a lot of direction, five written charters saying what must be checked and what
must be reported. This study measures whether the extra buys anything real.

It can lose. If five charters produce no more valid findings than one strong prompt, then a paragraph
of direction is enough, my charters are over-engineering, and this paper says so. That commitment was
written down before anything ran:

> "It has application for customer experience FUD, but if a genuine one prompt is that good, then yes,
> it proves an agentic review is not necessary."

### The uncomfortable part

I built the thing I am testing, which makes me the worst possible judge of it.

I have a log of 37 findings across five real pull requests, none overridden, where by my own count I
would have missed 21 of the 33 actionable ones reading the diff alone. That log has a hole a reviewer
would find in ten seconds: there is no control group. I never checked what one general prompt would
have caught on the same code. Section 4 is what I did about that.

## 2. What I was actually asking

DRAFT.

**The question.** On the same code, the same model, the same day, does a swarm of narrow reviewers
find materially more real problems than one general reviewer, and what does each one miss?

**The second question, registered before the results.** Independent of the counts: does the swarm
produce an audit trail that a general review does not? A per-finding record tied to a written rule,
showing what was checked, by which charter, and what was deliberately let through. This is registered
in advance precisely because it would be a convenient thing to reach for after losing on counts.
Stated now it is a hypothesis; stated afterwards it would be an excuse.

It is also the question closest to the thesis. Assurance is not a byproduct of finding more bugs. It
is a separate output, and direction is what produces it.

## 3. Baselines, and where none exist

DRAFT.

Predictions are anchored to published sources where they exist. Where they do not, that is stated
plainly rather than papered over with a number that sounds researched.

| Lane | Published baseline | Source quality |
| --- | --- | --- |
| Security | ~45% of AI-generated code introduces an OWASP Top 10 issue; pass rate stalled near 56% in the Spring 2026 update. An independent research note tracks the CVE surge in vibe-coded projects. | Two organizations, independent, same direction |
| Infrastructure | A benchmark on LLM-generated Terraform, a static-analysis study of Terraform tooling, and a peer-reviewed study on developer adoption of security policies in Terraform. | Academic and benchmark, multiple sources |
| Tests | **None.** Mutation testing is the right method for "would this test fail if the code broke," and there is recent work applying it to agent-written code, but no population rate exists. | No baseline. Prediction is intuition, labeled as such. |
| Documentation | **None.** No published rate for README drift, undocumented environment variables, or resources with no teardown path. | No baseline |
| Scope | **None.** No published rate for work that was not agreed, or decisions with no record. | No baseline |

**The lanes with baselines are the lanes everybody already scans for. The lanes with no baselines are
three of my five agents.** A category nobody measures is a category nobody tools for, which is a
plausible reason those findings survive to production. It is also why a comparison counting only
security findings would flatter the general reviewer: it scores the game on the half of the field
everyone already plays on.

How the results are displayed follows two published conventions I went and read before touching the
numbers: declare the scope up front and never normalize away a category one system was not asked to
cover, and when there is no ground truth, report each system's share of the union rather than calling
it recall. Sources in Appendix D.

## 4. How it was set up

DRAFT, written after the build and before any review, with one addition after.

### The subject

A three-tier TypeScript application, generated from one paragraph by a fresh Claude Code session
(v2.1.274, Sonnet 5) with no knowledge of this experiment. The paragraph is in Appendix A. It names
features and one architecture constraint, and says nothing about security, tests, documentation, error
handling, logging, performance or deployment, because those are what a fast build skips, and asking
for them would prompt away the phenomenon.

A full specification exists and the builder never saw it. It is the reference the reviewers are judged
against, not an input to the build. The gap between the two documents is the measurement.

Twelve minutes thirty-two seconds of agent work produced 60 files and 6,985 lines: Next.js 16 App
Router, TypeScript, PostgreSQL via Prisma, Tailwind, Docker Compose for the database, and hand-rolled
cookie and JWT authentication using jose and bcryptjs rather than an auth library.

Four of those were unprompted. Nothing in the paragraph mentioned Docker, a database engine, an
authentication approach, or instruction files for future agents, and it produced all four. It pinned
Prisma with a written reason, "Prisma 7 just shipped and requires driver adapters, not worth the
churn here," which is more deliberation about dependency risk than the stereotype predicts. It also
gitignored the `JWT_SECRET` it generated. Where it had a habit, the habit was good.

### The freeze

Committed exactly as produced, nothing tidied, tagged `v0-raw` at
`b38c5b0dc51206bda7cd97fc27d0d252d6fd6a02`. Three repositories at that one hash: the sealed original
and one working copy per arm, demonstrated rather than asserted.

### The baseline

| Tool | Exit | Result |
| --- | --- | --- |
| `tsc --noEmit` | 0 | clean |
| `eslint .` | 0 | clean |
| `next build` | 0 | compiled, 16 routes |
| `pnpm test` | 1 | no test script exists |
| `pnpm audit` | 1 | one high severity, `deepmerge-ts` via Prisma, GHSA-ggr8-5vv4-36mx |
| tracked secrets | 0 | none; `.env` correctly gitignored |

This is the floor. Anything a scanner catches earns no credit for either arm, and the same output is
the corroboration source during adjudication.

### The arms

Both on Sonnet, because the swarm's adapters pin `model: sonnet` and an Opus-versus-Sonnet comparison
dressed up as swarm-versus-single would be worthless. Three runs each, alternating, all preserved
including failures. Neither sees the other's output. Arm A's prompt is published verbatim and written
to be strong: it names breadth, asks for absences as well as defects, permits investigation, and
requires the same output fields the swarm's contract requires.

### Two conditions, not one

Added after the first six runs. I had tightened the review harness so reviewers could not get a bare
shell, and in doing so I closed the gate on every shell command. All six runs in the first condition
ran with their tools silently denied. The reviewers read code and reported; they could not run
anything. I found out from the reports, not from an error.

The first reaction was that the experiment had failed and had to be thrown out. The second, better
reaction was that a review with no tools is a legitimate condition, so long as it is labeled. So the
study became two conditions: tools denied, then tools allowed, three runs per arm per condition,
twelve reports total. The fix, the reason, and the fact that it was decided after seeing results are
all in `DEVIATIONS.md` as D-003 and D-004.

### Four lanes, not five

The swarm's scope agent holds a change against an engagement folder and decision records. A repository
generated from one paragraph has neither, so per its charter it reports that and returns PASS.

Supplying the specification to both arms would give that lane something to check, and was rejected:
the specification lists security, tests and documentation as requirements, so supplying it hands both
reviewers a checklist and destroys the sharpest prediction. Four of five charters are under test, and
the fifth returning PASS is reported as a finding about the swarm rather than hidden. It depends on
process artifacts that fast-generated repositories do not have.

### What I did about being the judge

Four constraints, all decided before any review ran. The tool-corroborated subset is the headline
number and does not depend on my opinion. I score blind, arm A first. A second judge runs on a
different model than the reviewers and the disagreement rate is published. Verdicts are open and
versioned, so a reader who thinks I scored something wrong can say so and see the change logged.

## 5. Predictions, sealed

DRAFT. Committed publicly at `9e2155d` before either arm ran.

I declined to predict absolute counts, not having read the source: "I'd be silly to just throw a
number in thin air." That refusal is registered as-is rather than replaced with an invented number,
and the predictions are directional, which is what the hypothesis claims anyway.

| # | Prediction |
| --- | --- |
| 1 | The swarm finds more real findings **in every category**. The strongest form: it fails if the single reviewer wins even one lane. |
| 2 | The single review misses a critical that the swarm catches. |
| 3 | The biggest gap is documentation, then security. |
| 4 | The swarm's precision is higher. Recorded as an expectation rather than a reasoned case: "it should be." |
| 5 | The single reviewer does **not** flag the missing test suite. |

Prediction 5 is the sharpest and the closest to the thesis. The repository has no tests, and noticing
that an entire class of artifact is absent is a different move from finding a bug in something
present. `test-reviewer` has it in its charter and cannot miss it. If the general reviewer catches it
anyway, then that much direction was unnecessary and I will say so.

Prediction 4 is the weakest and is labeled so. Five agents each hunting in a lane is five chances to
report something that is not there, while one reviewer with no charter has nothing pushing it to
produce findings.

## 6. What happened

DRAFT. Final numbers, from `ANALYSIS.md` sections 1 through 13.

### Three arms, not two

Two were registered. Arm A, one strong prompt naming eleven domains. Arm B, the swarm. After their
results were in and analysed, I added arm C: twenty-four words, no domain map, no output format, no
instruction to look for what is missing.

> Review this repository as if it were about to go into production. Find anything you think should
> be fixed or investigated before it ships.

Arm C is labeled post-hoc everywhere it appears. No prediction is about it. No A/B verdict was
revisited for it. It exists because the re-analysis of A and B ended on a confound I could not live
with: arm A's prompt was written by me, after weeks inside the swarm's charters, and it names every
lane the swarm has. I needed to know how much of arm A was the prompt and how much was the model.

### The definitions, because they move the numbers

Fifteen reports, 79 distinct claims after de-duplication. Each checked against the frozen commit:
`yes`, `partly` (real, citation off), `no`. Separately, `already prevented elsewhere` when another
part of the system blocks the failure. A **true positive** below is the strict reading, code matches
and nothing prevents it: 64 of 79.

There is no recall. Nobody seeded defects. Each arm gets its share of the union of true things any
arm found. **Shared scope** is the five domains the swarm has charters for. Correctness is named in
arm A's prompt only. Performance and accessibility were named by nobody.

### The table

| | C, goal only | A, one good prompt | B, five critics |
| --- | --- | --- | --- |
| Prompt | 24 words | 170 words | five charters, contract, orchestrator |
| Distinct claims | 37 | 47 | 48 |
| Strict precision | 81% | 81% | 79% |
| True positives, all domains | 30 | 38 | 38 |
| True positives, shared scope | 18 | 24 | 35 |
| Shared scope without tests | 17 | 23 | 22 |
| High-value defects found | 4 of 4 | 4 of 4 | 3 of 4 |
| High-value found in every run | 4 | 3 | 2 |
| Calibration defect (C26) | 3 of 3 | 5 of 6 | 0 of 6 |
| No tests noticed | 3 of 3, as one item | 6 of 6, as one item | 6 of 6, as thirteen |
| Security | 11 | 11 | 7 |
| Correctness | 10 | 11 | 3 |
| Seen in all three runs (tools condition) | 60% | 44% | 66% |
| Report length, words | 877 to 1,199 | 2,176 to 2,901 | 1,708 to 2,136 |
| Per-agent inspection record | no | no | every run |

Ordered by amount of direction. It is an ordering, not a scale: A to B changes the amount of
direction and the decomposition into agents at once, and B covers fewer domains than A by design.

### Per domain, true positives

| Domain | C | A | B | Declared by |
| --- | --- | --- | --- | --- |
| Tests | 1 | 1 | **13** | A, B |
| Security | **11** | **11** | 7 | A, B |
| Infrastructure | 4 | 7 | **8** | A, B |
| Documentation | 1 | 2 | **5** | A, B |
| Dependencies | 1 | 3 | 2 | A, B |
| Correctness | 10 | **11** | 3 | A only |
| Performance | 2 | 2 | 0 | none |
| Accessibility | 0 | 1 | 0 | none |

### The predictions

| # | Prediction | Result |
| --- | --- | --- |
| 1 | Swarm wins every category | **Failed.** Generalist won security, dependencies, correctness. |
| 2 | Single misses a critical the swarm catches | **Failed, and the reverse happened.** |
| 3 | Biggest gap is documentation, then security | **Half.** Docs was the swarm's second lead. Security inverted. Tests, unnamed, was the biggest. |
| 4 | Swarm precision higher | **Failed.** Equal. |
| 5 | Single does not flag the missing tests | **Failed, 6 of 6.** Then arm C failed it again, 3 of 3, with no instruction to look for absences. |

Four failed, one half held. The one I called sharp, the one I said would be the cleanest illustration
of what charters buy, failed most completely. They stay in `PREDICTIONS.md` as sealed.

## 7. The nine findings

DRAFT.

**1. Defect discovery did not favor the swarm.** 38, 38, 30. Precision within two points. This paper
does not describe the swarm as better at finding bugs, because it was not.

**2. The naive generalist was the surprise.** Twenty-four words found all four high-value defects
in every run, the calibration defect three times, the missing tests three times, eleven security
defects, ten correctness defects. Unprompted, every run read every file, ran `tsc`, eslint, audit
and the build, and wrote a Node script to prove a bcrypt truncation. Every run opened by saying what
it had not done. This changes how arm A reads. I had argued arm A did well because I handed it the
map. Most of the high-value capability was in the model before the map existed. The 170 words added
breadth in moderate and hygiene findings. They did not add high-value discovery.

**3. The swarm's real advantage was decomposition inside testing, and it has to be stated at two
levels.** Atomic: thirteen test findings against one from each generalist, each naming a module and
the assertions to write, all thirteen every run. Root cause: all three arms recognized the same
condition, no meaningful test suite, and the generalists said so once and moved on. The specialist
turned one observation into a work queue. That is evidence for specialist depth and actionability.
It is not thirteen independent defects, and a reader who counts it as one gets shared-scope parity
between the swarm and arm A.

**4. Lane boundaries produced a structural blind spot, and it cost the most important finding.** The
subject lets a user rewrite an idea's original scores after recording the outcome. The calibration
view, the whole point of the product, becomes fiction. Arm A found it in five of six runs. Arm C in
three of three. Inside the swarm, `test-reviewer` noticed it in two runs and the merged report put it
under "Handoffs nobody picked up" with the note "no agent in the roster owns this." Never a finding.
Never a severity. The swarm has no correctness reviewer by decision, ADR 0004, which says that a gap
nobody covers is the signal to write a new specialist. This is an architecture-induced coverage gap.
The model saw it. The design had nowhere to put it. The same reports show the handoff mechanism
working in the other direction, the test reviewer flagging things the security and docs reviewers
missed. Cross-agent noticing works. Ownership is what fails.

**5. The generalists beat the security specialist in its own lane, twice.** Eleven, eleven, seven.
One generalist told to check security, one not. I do not know why. Hypotheses, untested: the
security charter is checklist-shaped and this application did not fit the checklist; application
security rewards whole-system context a lane does not have; lane restriction suppresses cross-domain
security reasoning (the enumeration leak in one swarm run was noticed by the test reviewer, not the
security reviewer); this repository favors broad reasoning.

**6. The swarm was the most repeatable and produced the only inspection record.** 66% of its true
positives in every run, against 44% for arm A and 60% for arm C. And in every run, a per-agent
account of which reviewer checked which domain, which tools ran and which failed, which files were
not read, where two agents disagreed, and what was noticed but unowned. Neither generalist produced
that. Review observability. Assurance evidence. An inspection record. It is a real product property
even where the totals tie. It is not the same claim as a better review, and I am keeping the two
apart.

**7. More prompting did not improve the important findings.** Arm A's 170 words bought eight more
true positives than arm C's 24. None high-value. Same precision. Less repeatable. Twice the length.
Arm C already had every high-value defect every run. On this subject, with this model, prompt
engineering past the goal statement showed diminishing returns. Narrowly: this repository, this
model, one naive prompt.

**8. Tools were not really tested.** A handful of findings swapped in each direction, one
tool-dependent true positive. No tests to run, no infrastructure code, no CI. Three of five
specialist tools had nothing to operate on. Tools had little effect on this repository. That is not
"tools do not help AI review."

**9. The subject starved some lanes.** The swarm was built as a pull-request gate for repositories
with engagement documents and decision records. This study pointed it at a whole freshly generated
repository with neither. Scope had nothing to check. Infra had one compose file. Test reviewed
absence, not a suite. Every arm reviewed the same repository, so this is not an excuse. It is an
external-validity limit: one kind of subject, and the kind the architecture was least built for.

## 8. The audit trail question

DRAFT.

Registered before results: does the swarm produce an account of the review that a general review
does not, and is it worth anything to someone who has to sign off on AI-written code?

It does, every run, and it is the one thing only the swarm produced. Put it against the objection in
section 1. "We can't trust the output" is not answered by more findings. It is answered by a record
a person can check. Arm A gave a good reviewer's opinion. Arm C gave the same plus one honest line
about what it had not done. The swarm gave an inspection record. On counts they tied. On this they
did not.

And the same structure paid for it in section 7: "Handoffs nobody picked up" is both the most honest
line in the swarm's report and the place the best finding in the study went to die.

## 9. What this does not show

DRAFT.

- One application, one stack, one model, one author, one week. No claim about multi-agent review in
  general.
- Three runs per condition describes stability. No statistics, none claimed.
- Four of five charters under test, and the subject was the kind the swarm was least built for.
- No seeded defects, no recall. Anything every arm missed is invisible.
- I built one arm and judged all three. Mitigated, not removed. The second judge the protocol
  registered has not run. Verdicts are one judge's and open for dispute in `findings/`.
- Arm C is one naive prompt written by someone who had seen the results. One draw, not a population.
- Arm A and B ran once with tools silently denied by my own harness bug and once with tools working;
  both conditions are reported (D-003, D-004). My baseline measurement had a bug (`tee`'s exit code)
  and the harness leaked into the subject (`.claude/settings.json`); both recorded and excluded.
- The value rubric was applied twice and the moderate/low split moved by a few items. The high tier
  did not.

## 10. Final interpretation

DRAFT.

The question this study started with, five critics or one good prompt, which one wins, is the wrong
question and the data says so.

Different review structures produce different kinds of evidence. The generalist, prompted or not,
was strong at whole-system reasoning and at the high-value cross-cutting defects, and found the one
that mattered most every time. The specialist swarm was strongest where a narrow reviewer could
systematically decompose a domain, testing above all, and it produced an explicit assurance record
nothing else did. Pure specialist parallelization also created blind spots when an important finding
crossed lanes or fell between them, and the swarm's own rule for that case, hand it to nobody, is
where the most consequential finding in the study went.

The thesis held, but not the way I expected. Direction is what converts capability into evidence.
The capability to find the worst defect and to notice the absent tests was there at zero direction.
What direction produced was coverage of lanes nobody thinks to check, a decomposed work list, and a
record of what was checked and what was not. Those are evidence artifacts. They are not detection.

The most interesting result of Experiment 001 is that it changed the architecture.

## 11. V2: a hypothesis, not a result

**This is a design hypothesis motivated by Experiment 001. Nothing below has been built or measured.**

Pure specialist parallelization is insufficient for comprehensive AI code review. A hybrid that
combines one broad whole-system review with targeted specialist reviewers may preserve cross-cutting
reasoning while keeping the depth, repeatability, actionability and auditability that specialization
produced here.

1. **Broad systems review.** One reviewer, whole repository, no lane. Owns whole-system correctness,
   business invariants, cross-file interactions, emergent behavior, and everything that belongs to
   nobody else.
2. **Specialist reviewers**, in parallel where the subject allows. Tests, security, infrastructure,
   documentation, scope. Charters, seeds, tools, as in V1.
3. **Arbiter.** Deduplicates across all reviewers, reconciles conflicts, preserves specialist
   evidence, preserves unowned broad findings as findings with a severity and a verdict, and produces
   the final assurance record.

The rule that changes: **an important finding must never disappear because it does not fit a lane.**
"Handoffs nobody picked up" stops being a terminal state.

This reverses ADR 0004, which rejected a general reviewer because it has no lane and would bury the
one thing only it noticed under twenty things everyone noticed. Experiment 001 is the evidence that
decision was made against. The thing only the generalist noticed was the most important finding in
the study. The arbiter, not the lane rule, is the proposed answer to burying. Whether it works is
the next experiment's question, and I would not bet on my own predictions this time.

## 12. Experiment 002: future work, not started

**Experiment 002 has not happened. Nothing here is a result.** (Written before V2 was built; V2 now
exists, sections 13 to 15, and 002 is still not designed.)

Compare V1 and V2 on a subject that actually contains existing automated tests, CI/CD, infrastructure
and deployment configuration, documentation, and meaningful application logic, so the test and infra
specialists review what exists rather than notice what is missing, and the tools have something to
run against.

The question: does a hybrid broad-plus-specialist architecture recover the cross-cutting defects
missed by strict specialist lanes while preserving the swarm's depth, repeatability, actionability
and assurance evidence?

A possible design: four arms, naive generalist, strong generalist, V1 swarm, V2 hybrid. Predictions
sealed first. Cold naive prompts from people who have not read this study, so the naive arm is a
population and not a draw. The actionability and documentation-quality rubrics applied to every
finding; they were registered for 001 and never used. A second judge on a different model. Report
length and cost from the harness for every arm.

That is a paragraph, not a plan.

---

## 13. What I did about it

DRAFT. Written after the work, from the record.

Section 11 was the hypothesis. This is what happened when I built it, the same day, on a branch cut
from the swarm's main line with V1 tagged first so nothing about what Experiment 001 tested could
drift. Every commit named here is on `v2/hierarchical-review-model` in the swarm repository.

Before writing a line of the new reviewer I re-read all seven charters, the two shared contracts, the
orchestrator, ADRs 0001 to 0005, the runner scripts, and the two swarm reports from the experiment
where C26 went to die. The reading changed one thing in the plan and confirmed the rest.

The thing it changed: my first instinct, and the one I had written into the lab roadmap, was to run
the broad review first and let it steer the specialists. Reading the V1 orchestrator's charter talked
me out of it. V1's whole reason for parallel independence is "don't let one agent's output influence
another's input," and Experiment 001 never showed that parallelism was the problem. It showed a
coverage gap and a synthesis gap. Sequencing would fix neither, would double the wall time, and would
make V2's specialists incomparable with V1's, so a later experiment could not say which change
helped. The broad-first version is written down as V2.1 and not built.

The thing it confirmed: the failure was three rules interacting. `test-reviewer`'s charter says
correctness is not its job, say so and move on. The contract says route only to the roster,
otherwise "no owner." The orchestrator counts only Blocking and Should fix. Each rule is fine. The
report has one lane for text and one for verdicts, and unowned findings were in the wrong one.

### What V2 is

Six reviewers instead of five, still parallel, still independent. The five specialists and their
charters are untouched, including security's, whose lane loss in section 7 is written up separately
and deliberately not tuned to the findings it missed. The sixth, `systems-reviewer`, has the lane none
of them can: the failures that only exist when the pieces are put together. Its charter blocks on
five kinds of interaction and on nothing else, and above all five sits one rule I added after the
first draft and now think is the most important sentence in the charter: a BLOCK from this reviewer
must require reasoning across a sequence, a boundary, shared state, or an interaction. If
the defect can be established by looking at one operation in isolation, it is not this reviewer's.
That sentence is what stops a "systems reviewer" from turning into the general code reviewer ADR
0004 rejected, with a better name.

The merge became an arbiter. It keeps every V1 rule: any BLOCK is BLOCK and it cannot downgrade one,
duplicates merge with attribution, nothing is dropped, it adds nothing of its own. It gains two
judgments and only two: the severity and confidence of a finding nobody owns, and the reconciliation
of two reviewers who disagree. It cannot open a file, run a tool, or read the diff. I went back and
forth on that. The first draft let it check a cited line before assigning confidence. I cut it,
because the moment it does that it is a seventh reviewer nobody chartered, and the assurance record
would be lying about who checked what.

"Handoffs nobody picked up" no longer exists. What went there becomes an unowned finding with the
originating reviewer, the evidence as written, a severity, a confidence, and one line of basis. It
can affect the verdict. It can be blocking only when the reviewer supplied a reproduction or a
deterministic sequence and stated a consequence for a user, data, money or access, in its own words.
The arbiter classifies that evidence; it may not supply the consequence itself. And a reviewer that
is configured and missing caps the verdict at WARN. No "PASS, five of six." If you want five, configure
five.

Two outputs instead of one, because section 8 showed they were two products: findings, for whoever
fixes the code, and an assurance record, for whoever has to decide whether to trust the review.

## 14. Testing the pieces

DRAFT. Numbers from `docs/evals/systems-reviewer/run-001/` and `docs/evals/swarm/run-001/`.

### The systems reviewer

Six seeds, each several files, each file locally reasonable, the defect only in how they interact.
One per category and a clean one. Not the calibration bug; I wanted the reasoning, not the memory.
Run once each at commit `53445c2`.

Five of five defect seeds: BLOCK, the intended interaction reconstructed, all five parts of a systems
finding present (invariant, interaction, why each step looks fine, failure, fix). Five of six reports
ran a reproduction and said what happened. Zero specialist checklist items in any Blocking section.
Lane routing right every time.

The clean seed came back BLOCK, and it was right. I had written a ticket system where `reopen` was
documented as "only from RESOLVED" and checked `satisfaction is None` instead, and the shared
transition table allowed PENDING to OPEN for the reply path. So a requester could put a ticket back in
the agents' queue without saying anything. README and docstring both forbid it. I missed it. The
reviewer also found a README diagram that disagrees with a function in the orders fixture and a second
real interaction in the job-stats fixture I had not designed in.

I want to be precise about what that is evidence of. It is evidence that the mandate produces
nontrivial reasoning: the clean-fixture defect is a handler's implicit assumption meeting a shared
table's permissiveness, which is exactly the class the charter describes, and it was found by tracing,
not by matching a list. It is not evidence that V2 is better than V1. No V1 reviewer was run on those
fixtures. No generalist was. The person who wrote the charter wrote the fixtures. What it does mean is
that the clean seed cannot measure false positives as written, and that fixtures need the same review
as the code they test.

Two things the run showed the charter lacked, both deferred until the arbiter existed: the reviewer
had nowhere to send local nits it noticed while tracing (there is no roster entry for local
correctness), so it kept them in Should fix and labeled them local; and severity was binary, so a real
interaction with a mild consequence got BLOCK. Both went into the contract when the arbiter did.

### The arbiter

You cannot seed an arbiter through live reviewers; the input varies every run. So its eight seeds are
saved reviewer reports plus a prompt that says arbitrate these and do not read the source. The reports
cite an invoicing application whose source does not exist in the seed, so an arbiter that tried to
open a file could not. Run at `c6352b5`.

Eight of eight on the rule each seed tests, plus the V1 live seed now spawning six reviewers, nine of
nine. The pair I care most about is `unowned-severe` and `unowned-low`: the same file and line, once
with "I reproduced it" and a stated consequence, once with "I did not see," "could not confirm," and
"might." Blocking and high, verdict BLOCK; should-fix and low, verdict WARN; and a basis line in each
that quotes the reviewer. The guardrail worked in both directions on the first run.

The other one I care about is `disagreement`. I had botched the fixture: a `.py` file described with
JavaScript types, and two contradictory coverage lines from my generator. The arbiter noticed from the
reports alone, wrote "I could not reconcile these without opening the file," and did not open it.
That is the rule holding when it cost something.

On the live seed, four reviewers handed "no test step before deploy" to infra-reviewer, which did not
pick it up. In V1 that was four lines with no severity. In V2 it is one unowned finding at should-fix,
medium confidence, four observers credited, infra-reviewer named as having missed it. That is the
mechanism C26 needed. Whether it would have caught C26 on the idea-log application is not tested.
Nobody has run that subject through V2.

## 15. Testing the whole

DRAFT. Numbers from `docs/evals/integrated/run-001/`.

Every agent, every seed, one run, at `5514f27`: 35 V1 seeds, 6 systems, 8 arbiter. Forty-nine
reports. Forty-five passed the runner's checks. Four did not, and I classified each from the
preserved report before touching anything, into architecture, implementation, evaluation-definition,
fixture, or harness.

None of the four is architecture or implementation. `infra-reviewer/no-tags` returned WARN because
the reviewer read its charter literally ("no tags, no name, and no comment"; the Lambda has a name)
and the expectation wanted BLOCK; it also found an IAM role the seed references and never defines.
Two `test-reviewer` seeds found the exact planted defect and the exact fix and used "patch" and
"MM/DD/YY" where the expectation's term list said "mock" and "two-digit." And the live swarm seed
failed a string check that passes on replay: the report contained one `×` character and macOS's grep,
with case-insensitive and fixed-string flags together, gives up on multibyte input. Same seed, same
check, passed three hours earlier with no `×` in it.

Zero regressions from V1. Every V1 seed is correct on reading. One V1 specialist, `test-reviewer`,
used the new `-> no owner` form unprompted, with a reproduction attached, to report that a date
parser accepts a four-digit year and returns 4026.

### What V2 has shown

On its own evaluations: the systems reviewer follows its mandate and reconstructs the planted
interactions; it finds interactions nobody planted; it declines to raise a finding where no invariant
is stated; the arbiter follows its contract, seventeen of seventeen across two runs; dead-end
handoffs become findings with severity, confidence, ownership and provenance; and none of it
regressed the specialists.

### What V2 has not shown

That it finds more or better defects than V1 on any subject. That it would have caught C26. That its
false-positive rate is acceptable on real code. Cost, latency, anything about real pull requests: it
has reviewed zero. Whether the security lane result changes. And whether any of this is the right
axis at all, which is section 17.

## 16. Things I found while writing this down

DRAFT.

The tool-execution fix is not on the V2 branch. The commit Experiment 001's tools condition ran on,
`a18fba7`, the one tagged as V1, was on a branch that was never merged into the main line, and V2 was
cut from main without it. So the review script on V2 still has the exact line that denied every tool
in the experiment's first condition. None of the evaluations in sections 14 and 15 were affected; the
seed runner has its own flags. A real review through the script would be. I found this by checking
the history while writing section 13, not by any test, and it is recorded in the research record
rather than quietly fixed, because the design document and the lab both said the merge had happened
and both were wrong.

Five fixtures have defects the reviewers under test found and I did not plant. The seed runner's term
check breaks on a correct synonym and, on a Mac, on any non-ASCII byte. All recorded, none repaired
yet, and the earlier gradings will stay as graded when they are.

## 17. The question after this one

DRAFT.

V2 improved the architecture without adding hierarchy or iterative control. That was deliberate, and
I still think it was right for this step. But it leaves something in place that every version so far
has shared: a reviewer receives a task, investigates once, and returns a report. Nothing looks at what
it found halfway through and decides whether it should keep going, reach for a different tool, or
change its mind about what it is looking for. The arbiter cannot, by design. Nobody else is
chartered to.

Two moments in the record point at this. In Experiment 001 the single reviewer, given tools, ran a
bcrypt timing benchmark and a truncation reproduction on its own initiative, and that turned a
code-read claim into a demonstrated one. In the arbiter's evaluation the right next step was obvious,
open the file and settle which description was true, and the architecture forbade it, correctly.

So the next question, written down here and not designed past this paragraph:

> Does review quality improve when static reviewers become managed investigators, able to gather
> evidence iteratively, choose tools, revise hypotheses, and be directed to continue when their
> evidence is incomplete?

Before that: V2 on real pull requests, its failures into seeds the way V1's were, the fixtures
repaired, the fix landed, and a decision about whether Experiment 002 compares V1 with V2 or V2 with
whatever answers this.

---

### Appendix A: the build prompt

The entire input to the coding agent, issued once:

> Build me a web app where I can log ideas I have as a builder, score each one from 1 to 5 on
> differentiation, evidence, cost and reversibility, and see them ranked by total score. When I finish
> or abandon an idea I want to record what actually happened and score it again in hindsight, so I can
> see over time where my predictions were off. It needs accounts so my ideas are private, and I want
> to be able to share a single idea with someone by link without them signing up. Use TypeScript for
> everything, a real API and a real database, not a toy. Make it look decent.

### Appendix B: raw reports

In the study repository under `reports/`: `A1`, `A2`, `A3`, `B1`, `B2` (aborted, kept), `B2r`, `B3`
for the no-tools condition, `A1.2` through `B3.2` for the tools condition, and `C1` through `C3` with
their full event streams. Unedited. `reports/runs.csv` has timestamps, model, harness commit and exit
status for each, and tokens, cost and tool calls for arm C.

### Appendix C: the scored findings table

In the study repository under `findings/`: `adjudication-key.json` (77 A/B claims, arm and run each
was seen in), `adjudication-key-C.json` (arm C's 37, with overlap), `evidence-01.json` through
`evidence-04.json` (per-claim verdicts against the frozen commit), `value-rubric-applied.json`,
`reconciled.json`, and the five raw extraction CSVs. `ANALYSIS.md` at the repository root regenerates
every table in sections 6 and 7; its section 13 is the closing interpretation. The frozen subject is
public at `cruzbuilds/idea-log`. V2's evaluation records are in the swarm repository under
`docs/evals/{systems-reviewer,swarm,integrated}/run-001/`, each with a `GRADING.md` and the raw
reports, and the research record is `docs/research/v2-hybrid-review.md` there. Verdicts are open. If one is wrong, the correction goes in
`findings/corrections.csv`, which is append-only and enforced by a script.

### Appendix D: sources

- Veracode, 2025 GenAI Code Security Report: https://www.veracode.com/blog/genai-code-security-report/
- Veracode, Spring 2026 GenAI Code Security Update: https://www.veracode.com/blog/spring-2026-genai-code-security/
- Help Net Security summary: https://www.helpnetsecurity.com/2025/08/07/create-ai-code-security-risks/
- Cloud Security Alliance, AI-generated code vulnerability surge: https://labs.cloudsecurityalliance.org/research/csa-research-note-ai-generated-code-vulnerability-surge-2026/
- Security-First Evaluation of Text-to-Terraform: https://pith.science/paper/2608.02672
- University of West London, Terraform IaC analysis tools: https://repository.uwl.ac.uk/id/eprint/13358/
- Adoption of security policies by developers in Terraform (PMC): https://pmc.ncbi.nlm.nih.gov/articles/PMC11868142/
- Mutation testing for agent-written code: https://www.awesome-testing.com/2026/08/mutation-testing-for-agent-written-code
- Reporting conventions (declared scope, per-category reporting, agreement as overlap over the smaller
  set, relative recall against the union): the six-tool static analysis comparison by Palomba et al.,
  and the LLM-versus-SAST benchmark at arXiv 2508.04448. Full citations to be added with the
  remaining literature sweep.

---

## Interview log

Working interviews recorded as the experiment runs. Newest at the bottom. Notes, not prose.

### 2026-09-17, before the build

**Where the idea came from.** A conference. The same statement from customers across industries and
organization sizes. The consistency across unrelated organizations is what made it register as a real
gap rather than one company's caution.

**The first idea, and why it was dropped.** Agentic swarm *development*, agents that write the code.
Abandoned because Kiro and Claude are already good at that. Generation was not the problem.

**The actual question.** "How do you prove it, and make a customer comfortable with their own dev team
using these tools?"

**What a null result means.** "It has application for customer experience FUD, but if a genuine one
prompt is that good, then yes, it proves an agentic review is not necessary."

**On predicting counts.** Declined without research: "I'd be silly to just throw a number in thin
air."

**Still open:** which conference and roughly when; what roles were saying it; whether anyone described
what *would* make them comfortable; whether to name the venue in the published version.

### 2026-09-17, after the build

**The thesis, in his words.** "The agent had the capability and lacked the instruction. This is what I
want to show. AI is not wrong, it needs direction."

**On the framing of the testing finding.** Rejected the gotcha reading. "It should be: I was expecting
X, not Y, which honestly is a good thing. The agent tested but didn't document, which could lead an
engineer to think no tests were done or that tests can't be replicated. Rather than the idea that
agents just don't do anything. They just need rules like any human."

**On the scope lane.** Chose to run with four of five charters rather than hand both arms the
specification, and asked that the inert fifth be documented as a finding rather than a footnote.

**On documentation style.** "All things should be documented as almost a narrative with interesting
things doc'd along the way."

**Still open:** the absolute-count predictions he declined to make, which stay unmade rather than
backfilled.

### 2026-09-18, first results (tools denied, not yet known)

**First reaction to parity.** "interesting.... I guess our swawm was a waste lowkey lol"

**Second reaction.** "i thought regardess a specific agent would beat a generic prompt but hey the
more you know"

**Next move, before learning the tools were denied.** "my thought is making the reviewer agents even
more specialized by giving them tools"

**On discovering the tools were denied in all six runs.** "technically the expeirement failed... we
hve to retest." Then, after discussion: keep the six as a labeled condition, fix the harness, run
again with tools.

### 2026-09-19, second results and re-analysis

**On the first display of the numbers.** "why judge things the swarm isnt deisned to review??? that
skews the numberss... this is not proper scientific display of data. do research into whats the right
way to display this"

**On his own bias, both directions.** "i refuse to fudge data but its tough for me to believe we are
representing this prop"

**On what to measure.** "maybe use other metrics such as time, quality of reporting and documenation
of findings... maybe the win is not just in the quantative but also the qaulitatitive"

**On learning why the generalist did so well.** "wtf so the prompt was to crazy good lol... what was
the prompt?"

**Still open:** whether he wants to run arm C before or after writing this up; whether the test
reviewer's thirteen items should stay thirteen in the published headline or be shown both ways.

**On arm C's result.** "sheshhh"

### 2026-09-19, closing

**On what the swarm should have been.** After seeing the calibration defect filed under "nobody owns
this" in two swarm runs, and arm C finding it three times out of three: the swarm's advantage is
depth and the record, not detection, and a broad reviewer next to the specialists with an arbiter
over both is the hypothesis for V2. He asked that it be written as a hypothesis, not a result, and
that Experiment 002 be documented as not started.

**On tone.** "Keep the research honest and relatively modest. This is a personal engineering
experiment, not a claim about all multi-agent systems. The most interesting result is that the
experiment changed the architecture. The original hypothesis did not survive contact with the data.
That is part of the story."

### 2026-09-19, building V2

**On the arbiter's access to code.** Rejected letting it open a cited line: "Otherwise the arbiter
becomes a hidden seventh reviewer. Confidence should be based entirely on the evidence provided in
the report."

**On missing reviewers.** "I do not want `PASS, 5 of 6`. If five reviewers are intentionally desired,
the configured roster should contain five. Missing expected coverage means we cannot claim PASS."

**On elevating an unowned finding.** "The arbiter may classify that evidence, but it should not
create the blocking consequence through its own interpretation."

**On the systems reviewer's scope.** "This is important. The systems-reviewer should not slowly
become a renamed general-code-reviewer. Its value is specifically in defects that emerge from
interactions."

**On the clean seed failing.** Asked that it stay documented as it happened: "Do not rewrite history
by making the original seed suite look cleaner than it was."

**On the integrated run.** "Do not tune the reviewer or arbiter based on a single integrated failure
until the cause is classified."
