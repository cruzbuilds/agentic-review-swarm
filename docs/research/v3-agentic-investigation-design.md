# V3: agentic investigation. Design for review

**Status: design only. Nothing here is implemented. No manager, no investigator, no runtime, no tool
registry, no seed exists for V3. This document is the proposal a reviewer approves, changes, or
rejects before a line is written. V2 on `v2/hierarchical-review-model` is the frozen baseline and is
not modified by this track.**

**Track:** branch `v3/agentic-investigation`, cut from the V2 consolidation commit `21c0e29`. Revision 2 (second design commit): V3 inherits the V2 charters, so the first experiment tests the investigation loop and not the role wording; blind scoring of manager steering; evidence-based budgets; coverage on the state card; budget-limited findings measured separately. Revision 1 is the previous commit on this branch.
Provisional name: Agentic Investigation Architecture. The name can change once the design is settled.

**Question this design would let us answer.** Does giving specialized reviewers iterative
investigative autonomy, dynamic selection from a known tool set, and manager-directed follow-up
produce better-supported findings than the one-pass V2 workflow, and at what cost?

**What precedes it.** [v3-agentic-investigation.md](v3-agentic-investigation.md), the question;
[v2-hybrid-review.md](v2-hybrid-review.md), the baseline and its evaluations;
[experiment-001.md](experiment-001.md), the evidence that most high-value detection is already in the
model and that the remaining gaps are architectural.

---

## 0. The progression this sits in

| Stage | Execution | Who decides the next action |
| --- | --- | --- |
| 0. Simple prompt | one call | a human, once, before the call |
| 1. Structured prompt | one call, more guidance | a human, once, before the call |
| 2. V1, parallel workflow | fixed reviewers run in parallel, fixed merge | the harness; the graph is fixed |
| 3. V2, managed workflow | fixed reviewers plus a systems reviewer, evidence-aware arbiter | the harness still fixes execution; synthesis reasons over evidence |
| 4. V3, agentic investigation (proposed) | a manager assigns investigations; investigators choose tools, gather evidence, revise hypotheses; the manager decides whether each continues; the arbiter synthesizes | a human sets objectives, roles, tools, budgets and rules; within them, the manager and investigators decide parts of the graph from evidence found during execution |

In Anthropic's terms ([Building effective agents](https://www.anthropic.com/research/building-effective-agents)),
stages 0 to 3 are *workflows*: "LLMs and tools orchestrated through predefined code paths." Stage 4
is the first point at which any part of this system is an *agent*: "LLMs dynamically direct their own
processes and tool usage." The design keeps that boundary narrow on purpose.

## 1. Proposed architecture

```
                                 CHANGE
                                   |
                                   v
                       +-----------------------+
                       | INVESTIGATION MANAGER |   assigns; never investigates
                       +-----------+-----------+
                                   |  objective, scope, tool registry, budget
             +---------------------+---------------------+
             |                     |                     |
     +-------v-------+     +-------v-------+     +-------v-------+
     |   security    |     |    systems    |     |     tests     |   ... infra, docs, scope
     | investigator  |     | investigator  |     | investigator  |
     +-------+-------+     +-------+-------+     +-------+-------+
             |  hypothesis -> choose tool -> evidence -> revise      (own context, own turns)
             |                     |                     |
             +---------------------+---------------------+
                                   |  STATE CARD per investigator (compact, structured)
                                   v
                       +-----------------------+
                       | INVESTIGATION MANAGER |   reads state cards, not transcripts
                       +-----------+-----------+
                                   |  per investigator, with a reason:
                     +----------+--+-------+-----------+
                     |          |          |           |
                 CONTINUE   REDIRECT    COMPLETE     STOP
                     |          |          |           |
                     +----+-----+          |           |
                          |                |           |
                          v                |           |
                    investigator           |           |   bounded loop:
                    resumes from           |           |   rounds, redirects, tool calls,
                    its state card         |           |   tokens, wall time
                          |                |           |
                          +--------> manager  <--------+
                                        |
                                   final reports (shared output format) + investigation log
                                        v
                       +-----------------------+
                       |        ARBITER        |   the V2 arbiter, unchanged in principle
                       +-----------+-----------+
                                   |
                       +-----------+-----------+
                       |                       |
                   FINDINGS            ASSURANCE RECORD
                                       (+ manager actions, per-investigator budgets used)
```

Three roles, kept apart. The **manager** operates during investigation and asks whether evidence is
complete. The **investigators** investigate their domains. The **arbiter** operates after
investigation and asks what the completed evidence adds up to. The manager is not the arbiter, and
the arbiter does not manage. Merging them would put "should this continue" and "what does this add up
to" in one place, and the assurance record could no longer say who decided what.

**Mapping to Anthropic's patterns.** This is orchestrator-workers (the manager delegates and
synthesizes coverage, not findings) wrapped around per-investigator agent loops (tool use with
environmental feedback and stopping conditions), with the V2 arbiter as a final evaluator stage. It
is not evaluator-optimizer: the manager evaluates *completeness of evidence*, not quality of the
report, and never rewrites anything. It is the lead-agent/subagent shape from
[How we built our multi-agent research system](https://www.anthropic.com/engineering/built-multi-agent-research-system),
with three deliberate differences listed in section 12.

## 2. Manager contract

The manager manages epistemic completeness. It does not perform domain investigation.

**Inputs.** The change; the roster; each investigator's state card after each round; the budget
ledger. Never a raw transcript. Never the code, except the diff summary it hands out at the start.

**Outputs, per investigator, per round.** One of four decisions, each with a stated reason and a
reference to the state-card fields that justify it:

- **CONTINUE**: the hypothesis is promising and the evidence is incomplete; the investigator's own
  proposed next action is sound. The manager passes back the state card and "proceed as proposed."
- **REDIRECT**: a specific claim is unproven or a specific unknown is unaddressed. The manager names
  the unknown as a question. Example of the allowed form: "You have shown that the route accepts a
  resource id but have not established whether ownership is validated downstream. Trace that
  boundary." Example of the forbidden form: "Inspect `AssumeRolePolicyDocument` for wildcard
  principals because that is probably the defect." The first names what is unproven; the second
  supplies a domain answer. A redirect may also carry a question that another investigator's state
  card raised at a boundary, phrased as a question and stripped of the other investigator's
  conclusion.
- **COMPLETE**: the evidence is sufficient to report a finding or to dismiss the hypothesis. The
  investigator writes its final report.
- **STOP**: further investigation is unlikely to change the conclusion, or a budget is exhausted.
  The investigator writes its final report from what it has, and the report says it was stopped.

**Rules.**

1. The manager never states, suggests, or ranks a defect. It asks questions about evidence.
2. Every decision is logged with its reason. The log is part of the assurance record.
3. A REDIRECT is a question, and it cites the card field it comes from: an `unknowns` entry, a
   `boundary_questions` entry from another card, or a `not_examined` item. If the manager cannot
   phrase it without naming a suspected defect, or cannot point at a field, it issues CONTINUE
   instead. Every redirect is later scored blind for how much it implied (section 10).
4. The manager may not extend a budget. Budgets are set by the harness before the run.
5. The manager may not read a transcript. If a state card is too thin to decide on, that is a
   REDIRECT asking for the missing field, not a reason to look deeper.
6. Round 0 is fixed: every configured investigator is assigned its domain with the same description
   of the change, exactly as V2's fan-out does. The manager's first decision comes after round 0.
   This keeps round 0 comparable with V2.
7. COMPLETE is the default. The manager must justify not completing; it does not have to justify
   completing. This is the guard against "go deeper" as a reflex.

## 3. Investigator contract

**Revised.** The first experiment holds the reviewer's *mandate* constant between V2 and V3. A V3
investigator is a V2 reviewer with the same charter, given the ability to keep going. Concretely,
each investigator's prompt is:

1. the V2 charter for that role, verbatim (`agents/<role>/charter.md`, including its blocking list,
   warn list, exclusions, and "how you work"), with the two shared contracts prepended exactly as the
   V2 build does; then
2. one **investigation addendum**, identical for every role, that changes how the reviewer proceeds
   and nothing about what it looks for:

> You are running as an investigator. Your charter says what you are responsible for and what you
> stay out of; that has not changed. What has changed: you may take more than one pass. Work from
> hypotheses. For each, gather the evidence that would establish or disprove it, choosing from the
> tools listed below when one can do that. Do not assume a defect exists; a suspicious observation is
> not a finding until you have the evidence. Revise or abandon a hypothesis when the evidence says
> to, and record that you did. When you reach a boundary that belongs to another reviewer, write it
> down as a question rather than crossing it. At the end of this pass, write the state card exactly
> in the shape below, including what you have and have not examined, and propose what you would do
> next. You may be sent back with a directive; if so, resume from your card. You may not modify any
> file. Your final report is in the shared output format, and every finding carries an `evidence:`
> line naming what you gathered.

The one-paragraph "thin role" from revision 1 is **deferred to a future ablation** (section 17).
Testing it in the same experiment as the loop would leave a V3 loss uninterpretable: it could mean
iteration does not help, or that the roles were too thin at round 0. With the charter held constant,
round 0 of V3 is a V2 reviewer with an investigation addendum, and the difference between round 0's
card and V2's report is the first thing the analysis looks at.

**Rules.**

1. A suspicious observation is not a finding. A finding is a claim plus the evidence that
   establishes it, and the evidence is something the investigator gathered in this run.
2. Hypotheses may be revised or abandoned. Abandoning one is recorded with the evidence that
   disproved it and is reported as a dismissed hypothesis, not deleted. The hypothesis lifecycle
   (formed, supported, disproved, upgraded to reproduced, stopped) is preserved in the cards and is
   analysed (section 10).
3. The investigator proposes its own next action at the end of every round. The manager decides
   whether it happens.
4. Cross-boundary observations go to the card's `boundary_questions` field, as questions, for the
   manager to route. The investigator does not investigate another role's domain unless redirected
   to a specific question there.
5. No file is modified. Reproduction scripts run only in a scratch location outside the repository.
6. The final report is in the shared output format (`shared/output-format.md`) so the arbiter
   consumes it unchanged, with one addition: every finding carries an `evidence:` line naming the
   tool calls or reproductions that support it, and a report from an investigator that was STOPped
   says so at the top.

## 4. Investigator state model

The unit of communication between investigator and manager. Compact, structured, and the only thing
the manager sees. Target size: a few hundred tokens. This is the "condensed, distilled summary"
pattern from [Effective context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents),
applied per round rather than only at the end.

```
investigator: security
round: 2
budget_used: tool_calls 7/20, tokens ~18k/60k
hypotheses:
  - id: H1
    claim: PATCH /invoices/{id} trusts user_id from the request body
    status: supported | disproved | open
    evidence:
      - E1 read src/auth.py:40, require_owner compares body user_id
      - E2 grep: no other caller sets user_id from session
    confidence: high | medium | low
    consequence: (in the investigator's words, or "not yet established")
  - id: H2 ...
unknowns:
  - U1: whether billing.run treats status=paid as terminal (boundary: systems)
dismissed:
  - H3: jwt algorithm confusion; disproved by E4 (key is Uint8Array; HMAC only)
boundary_questions:
  - to systems: does any downstream job key off invoice.status without re-checking ownership?
coverage:
  examined: src/auth.py, src/invoices.py, src/api/* (all handlers), package.json
  not_examined: src/billing.py, migrations/, the HTTP middleware
  blocked: could not run pnpm test (no database); checkov unavailable
proposed_next: trace billing.run's handling of status=paid (tool: grep, read)
self_assessment: complete | incomplete
stopped: no | yes, by <budget or manager>
```

The `coverage` block is what the manager reasons about. Epistemic completeness is not only whether
the active hypotheses are proven; it is whether the parts of the change the charter is responsible
for were looked at. `not_examined` is the manager's main source of REDIRECT questions of the
coverage kind ("your charter covers CI workflows; `.github/` is under not_examined; is that a
decision or an omission?"). `blocked` feeds the assurance record directly, the way V2's Noted
section did. All three are lists of paths or one-line items, kept short.

The investigator writes it; the manager reads it; on CONTINUE or REDIRECT the investigator receives
it back as its starting context together with the manager's directive. **Resumption is by state
card, not by conversation.** This is a consequence of the runtime, not a preference: in Claude Code,
subagents do not retain context between invocations and cannot spawn subagents, so the manager is
the main session and each round is a fresh subagent call. Anthropic's research system resumes agents
from durable state for the same reason. It has a side effect worth measuring: an investigator that
resumes from a card has lost its scratch reasoning and keeps only what it chose to write down, which
is either a loss of nuance or a forcing function for explicit evidence, and probably both.

## 5. Tool-selection model

**Experiment A only: dynamic selection from a known registry.** No tool discovery, no acquisition,
no MCP browsing. That is a separate variable (Experiment B, not designed) and changing both at once
would make the result unattributable.

The registry is what V2 already grants through `review.sh`'s allow list, made explicit and
described for the investigator in the form
[Writing tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents) recommends:
few tools, consolidated, unambiguous descriptions, semantic returns, helpful errors.

| Capability | Backed by | Notes |
| --- | --- | --- |
| read file | `Read` | as today |
| search code | `Grep`, `Glob` | as today |
| trace references | `Grep` with a described pattern | no new tool; a described use |
| inspect change and history | `git diff`, `log`, `show`, `blame`, `ls-files`, `rev-parse`, `status` | read-only git; `-c`, `--exec-path`, `config`, `push`, `commit` denied, as V2 |
| run tests | `pytest`, `npm test`, `pnpm test` | as today |
| static analysis | `ruff`, `eslint`, `tsc`, `semgrep`, `gitleaks`, `actionlint`, `checkov`, `tflint`, `hadolint`, `shellcheck` | as today; each reports "unavailable" honestly |
| dependency inspection | `npm audit`, `pnpm audit`, `pip-audit` | as today |
| controlled reproduction | `node -e`, `python3 -`, a heredoc script under `$TMPDIR` | already used by V2 reviewers in Run 001; made explicit, bounded to scratch, no writes into the repository |

The investigator chooses which capability to use, when, and how many times, inside its budget. The
registry is published to it as a short list with one line each. Nothing is added to the registry
for V3; the experiment is about selection, not capability.

## 6. Context flow

Designed so that no context grows without bound and no investigator inherits another's conclusions.

| Who | Receives | Does not receive |
| --- | --- | --- |
| Investigator, round 0 | its V2 charter verbatim with the shared contracts, the investigation addendum, the change description, the tool registry, its budget | any other investigator's anything |
| Investigator, round n | its own last state card, the manager's directive, the registry, remaining budget | its own earlier transcript; other investigators' cards |
| Manager | every state card each round, the budget ledger | any transcript; the code beyond the diff summary |
| Arbiter | final reports in the shared format, the manager's decision log, the budget ledger | state cards, transcripts, the code (as V2) |

A boundary question crosses investigators only through the manager, as a question, with the
originating investigator's conclusion removed. This is the V1/V2 independence principle kept where it
matters (no investigator is anchored on another's finding) and relaxed where V1 and V2 had no answer
(a boundary nobody owned). Whether that relaxation reintroduces the anchoring V1 was built to avoid
is measured, not assumed (section 10, H5).

## 7. Stopping and budget model

Values are initial and are set from the evidence this repository already holds, not guessed. They
are recorded per run so they can be revised from data.

**What the evidence says about one pass.** The only instrumented one-pass reviews in the record are
Experiment 001's arm C: 10, 13 and 12 tool calls per pass on a 60-file repository, 171 to 216
seconds, 10k to 14k output tokens ([`runs.csv`](https://github.com/cruzbuilds/Five-Critics-or-One-Good-Prompt/blob/main/reports/runs.csv)).
V2's own runs were not instrumented for calls; the systems-reviewer Run 001 reports show three of six
reviewers running a reproduction script on top of reading, and `run-seeds.sh` caps a pass at
`--max-turns 40`. So a working pass is roughly 10 to 15 calls, and a pass that reproduces something
is at the top of that range. Revision 1's 20 calls per run would have bound at round 2 for any
investigator that used round 0 normally, which would have made the design one and a half rounds
while calling itself three.

| Control | Initial value | Basis | Enforced by |
| --- | --- | --- | --- |
| Rounds per investigator | 3 (round 0 plus two) | two chances for the manager to matter | manager, hard |
| Manager redirects per investigator | 2 | one per follow-up round | manager, hard |
| Tool calls, soft expectation per round | 12 | arm C's mean; an investigator past it in a round is asked by the manager to state what the extra calls were for, not cut off | investigator reports it on the card; manager reads it |
| Tool calls, hard ceiling per run | 36 | three rounds at the soft expectation | harness, per subagent call via `--max-turns`, and the ledger |
| Tokens per investigator per run | 60k output | arm C's 10k to 14k per pass, times three, with headroom for reproductions | harness |
| Wall time per run, all investigators | 20 minutes | arm C's pass times, times three rounds, in parallel | harness |
| Early completion | the investigator's `self_assessment: complete` and the manager agrees | manager |
| Mandatory STOP | any hard budget exhausted; two consecutive rounds whose cards add no new `evidence` entries; the same `proposed_next` twice in a row | manager, hard |

Before the first V3 run, the V2 baseline runs on both subjects are instrumented with
`--output-format stream-json` (as arm C was), so that V2's actual tool calls and tokens per reviewer
are on record and the V3 budgets can be checked against them rather than against arm C alone. If
V2's per-reviewer numbers differ materially from arm C's, the soft expectation and hard ceiling are
reset from them, before the V3 runs and with the change logged.

A run that ends by STOP is still a run; the report says so, and the assurance record shows which
budget was hit. There is no "go deeper" without a new unknown or an unexamined coverage item named
on the card. Round 0 alone, with every investigator COMPLETE, is exactly V2 with the addendum,
which is the null result the experiment must be able to detect (H0, H2).

**Budget-limited is not missed.** A STOP can leave behind a supported-but-not-reproduced claim (the
arbiter will carry it at medium confidence, should-fix at most), an open hypothesis, a finding whose
evidence could not be upgraded, or a `not_examined` entry that was never reached. Each of those is
recorded on the final card and counted separately in the analysis (section 10). A defect V3 was on
the way to and ran out of budget for is a different result from a defect V3 never saw, and the
write-up keeps them apart.

## 8. Arbiter integration

The V2 arbiter is downstream and unchanged in its rules. Its inputs gain two things, both additive:
the manager's decision log, carried into the assurance record under a new "Investigation" block
(rounds per investigator, decisions with reasons, budgets used, STOPs); and an `evidence:` line on
every finding, which is what the arbiter's confidence classification was already trying to infer
from prose. The elevation guardrail for unowned findings is unchanged: a reproduction and a stated
consequence in the investigator's own words. Nothing about the manager's decisions can affect the
verdict; the manager's log is coverage information, like the tools list.

## 9. Failure modes, and what the design does about each

| Failure | Guard | Detectable how |
| --- | --- | --- |
| The manager becomes a hidden reviewer, steering investigators to its own suspicion | rule 1 and 3; redirects are questions; the syntactic rule is a guardrail, not the measurement | two measures: the syntactic audit (any redirect that names a defect), and blind semantic scoring of every redirect by a reader who has not seen the manager's context, 0 neutral / 1 suggestive / 2 clearly implies a specific defect (section 10) |
| A neutral-sounding redirect still steers by *which* unknown it chooses | the manager must cite the card field (an `unknowns` entry or a `not_examined` item) that the question comes from | the blind score above; plus, per redirect, whether the cited field existed on the card before the redirect |
| Budget exhaustion silently downgrades findings | STOPped reports are labeled; the card records what was left unproven and unexamined | counted as budget-limited findings, unresolved hypotheses, un-upgraded evidence, and unexplored coverage, separately from misses (section 10) |
| Infinite deepening | hard round, redirect and tool budgets; mandatory STOP on no new evidence | budget ledger |
| Round 0 is the whole story and iteration adds nothing | round 0 is V2-comparable by design | count findings that exist only after round 1+ (H2) |
| Investigators anchor on each other through boundary questions | conclusions stripped; questions only; manager-mediated | compare findings with and without boundary routing (H5) |
| Lost nuance on resumption from a state card | the card format forces evidence to be written down | compare a resumed investigator's final report with round-0 reports on the same seed |
| Cost explodes | token and call budgets; the ~15x figure from Anthropic's research system is the warning | cost per confirmed finding, versus V2 (H4) |
| Duplicate effort across investigators | manager sees all cards and may STOP a duplicate line; round 0 lanes stay separate | count duplicate findings before arbitration |
| Reproduction scripts touch the repository | scratch-only; no write tool; git write commands denied | `git status` clean after every run, asserted by the harness |
| Non-deterministic paths make runs incomparable | evaluate outcomes and evidence quality, never the path (section 10) | by construction |
| The investigation addendum changes what the charter looks for, not only how | the charter is verbatim; the addendum says what it does not change | out-of-lane findings per report versus V2; round-0 cards compared with V2 reports on the same subject |

## 10. Evaluation protocol

Written before implementation, because the biggest mistake available is to build the loop and then
ask whether it feels better. The objective is not for V3 to win; it is for V2 versus V3 to be
interpretable.

**Design.** Two arms, V2 (frozen at its baseline tag) and V3, same subject, same model, same tool
registry, same charters, three runs each per subject. Round 0 of V3 uses the same change description
as V2's fan-out. **Per-run measurement is primary**; aggregates across three runs describe stability
and are reported as such. Outcomes and evidence are evaluated; paths are not prescribed, following
Anthropic's "evaluate end state, not process."

**Subjects, two, kept apart in every table.**

1. **The known subject:** `idea-log` at `b38c5b0`, Experiment 001's. 79 claims already adjudicated,
   64 confirmed, a value rubric applied, so every V2 or V3 claim matching an existing one inherits its
   verdict and only new claims need judging. Its cost is contamination: the people who designed V2
   and V3 know its defects, C26 above all. No prompt, charter, addendum or manager rule mentions it,
   and the protocol says the designers knew it. Results on this subject are reported as *replication
   on a known subject*, never as discovery.
2. **The primary-discovery subject:** a repository with existing tests, CI, infrastructure code and
   business logic, chosen and frozen before any run, reviewed by nobody beforehand, its hash recorded
   in the experiment repository before the first V2 baseline run. This is where the experiment's
   discovery claims come from, and it is the one Experiment 001 lacked.

**Measurements, per run.** Each is computable from preserved artifacts: final reports, state cards
per round, the manager log, the budget ledger, and the harness stream. Four properties of a finding
are scored separately and never collapsed: **factual correctness** (the adjudicated verdict),
**evidence quality** (read-only, tool-corroborated, or reproduced), **severity** (the consequence
rubric, applied blind to arm), and **actionability** (the 0 to 3 rubric registered in Experiment
001's protocol and never used, applied blind).

| Measure | Definition |
| --- | --- |
| Confirmed defects | strict rule from Experiment 001: code matches, nothing prevents it |
| Consequential defects | high tier of the value rubric, applied before knowing the arm |
| False positives | claims with verdict `no` |
| Unsupported or hedged findings | findings without an `evidence:` line naming a gathered artifact, or with hedge language and no reproduction |
| Evidence quality, per confirmed finding | read-only / tool-corroborated / reproduced |
| Hypothesis lifecycle, V3 only | per hypothesis across cards: formed at round n, supported, disproved (with evidence), upgraded to reproduced, stopped open. Preserved in full; summarized as counts |
| Upgraded findings | hypotheses present on a round-n card and demonstrated (reproduced) in the final report |
| Disproved and discarded | `dismissed:` entries with evidence that do not appear in the final findings |
| Load-bearing iteration | confirmed findings absent from every round-0 card and present in the final report (H2) |
| Load-bearing redirects | confirmed findings whose evidence chain includes a REDIRECT |
| Budget-limited outcomes, V3 only | at STOP: supported-but-not-reproduced findings; unresolved hypotheses; findings whose evidence quality could not be upgraded; `not_examined` items never reached. Each counted, and each compared against whether V2 or the other V3 runs found the corresponding defect |
| Coverage | confirmed defects per domain, as in Experiment 001; plus, V3 only, `examined` versus `not_examined` at the final card |
| Duplicate work | the same defect investigated by two investigators before arbitration |
| Manager integrity, syntactic | redirects that name a suspected defect, counted by a human reading the log; the guardrail; target zero |
| Manager integrity, semantic | every redirect scored blind by a reader who has not seen the manager's context or the investigator's cards: 0 neutral evidence or coverage question, 1 somewhat suggestive, 2 clearly implies a particular suspected defect. Reported as the distribution and the mean; no redirect scored 2 is the target |
| Compute efficiency | tool calls, rounds, redirects, output tokens, elapsed time, per investigator and per run, from the ledger and the stream; and tokens per confirmed defect, per arm |
| Repeatability | share of confirmed findings seen in all three runs, per arm per subject |
| Lane hygiene | out-of-lane findings per report, per arm |
| Human adjudication | one judge blind to arm, verdicts open and versioned, corrections logged; a second judge if resources allow |

**Preregistered qualitative analysis.** Written before the runs, so it cannot be chosen after: (a)
for every load-bearing redirect, the chain from question to evidence to finding, read for whether the
question was necessary or the investigator would have got there; (b) for every disproved hypothesis,
whether the disproof was correct; (c) for every STOP, what was left and whether another arm found it;
(d) round-0 cards against V2 reports on the same subject, for whether the addendum changed what the
charter looked at; (e) five randomly chosen redirects per subject, read alongside the card they came
from, for whether the cited field justified the question.

**Reporting.** Per arm, per subject, per run, with the declared-scope discipline of Experiment 001:
arms are compared on what both were asked to do, and out-of-scope discoveries are reported
separately. Nothing is normalized away. Sealed hypotheses (section 15) are graded whether they held
or not. **Causal claims are limited to what the design controls:** the charters, the model, the tool
registry, the subject and the round-0 input are held constant, so a difference is attributable to the
V3 treatment as a bundle (section 16); it is not attributable to any one element of that bundle, and
the write-up does not say otherwise.

## 11. What remains deterministic versus model-directed

| Deterministic, set by a human or the harness before the run | Model-directed, decided during the run |
| --- | --- |
| The roster of investigators, their V2 charters verbatim, and the one shared investigation addendum | which hypothesis each investigator forms |
| Round 0: every investigator assigned, same change description | which tool it uses, in what order, how often (within the registry) |
| The tool registry and its permission scoping | what evidence it gathers and what it writes on its card |
| Every budget and every stopping condition | whether it proposes to continue, and what next |
| The state card schema, including the coverage block | the manager's CONTINUE / REDIRECT / COMPLETE / STOP, and the question in a REDIRECT, which must cite a card field |
| The manager's rules, including "questions only" | how a boundary question is phrased |
| The arbiter's contract, unchanged from V2 | the final report's content |
| The output format | |
| Evaluation measures and predictions | |

The line is: humans decide what may happen; the model decides what does, within it. That is bounded
agentic investigation, and it is the only sense in which this design is agentic.

## 12. Mapping to the Anthropic reference material, and where code review differs

| Reference | Pattern | Used here as | Where we differ |
| --- | --- | --- | --- |
| Building effective agents | workflow vs agent | stages 0 to 3 are workflows; V3's investigators are agents inside a workflow | the outer loop stays a workflow: fixed roster, fixed round 0, fixed arbiter |
| | orchestrator-workers | manager assigns and reads state; investigators work | the manager synthesizes *coverage*, never findings; synthesis of findings is the arbiter's, downstream |
| | evaluator-optimizer | not used | the manager evaluates completeness, not quality, and never rewrites |
| | environmental feedback, ground truth from tools, stopping conditions, sandboxing | every investigator round; hard budgets; scratch-only reproduction | ground truth here is stronger than in research: the code is the world, and a claim is checkable |
| | ACI design: tokens to think, natural formats, no formatting overhead | state card is short and plain; tools are the existing CLI | |
| Multi-agent research system | lead agent delegates objective, output format, tools, boundaries | round 0 assignment carries exactly those four | our lead does not decide *how many* workers or *which*; the roster is fixed, to stay comparable with V2 |
| | parallel subagents with isolated contexts | investigators run in parallel with their own contexts | |
| | 15x token cost; multi-agent poor at interdependent coding tasks | budgets; cost is a primary measurement, not a footnote | review is reading, not writing: parallel, breadth-first, closer to research than to the coding tasks the article warns about; but a cross-boundary defect is an interdependency, and the manager's question routing is our answer to it |
| | evaluate end state, not process; LLM-as-judge rubric; human eval | section 10 | our ground truth is adjudication against code, which is stronger than a rubric; a rubric is used only for actionability |
| | durable state, resume from where the agent was | state cards; resumption by card | forced by the runtime rather than chosen |
| | scale effort to complexity | not adopted | every investigator gets the same budget in the first experiment, so effort is a controlled variable |
| Effective context engineering | context rot; minimal viable tools; just-in-time retrieval; subagents return condensed summaries | the card is the condensed return; the manager never sees transcripts; tools are the existing minimal set | applied per round, not only at the end |
| Writing tools for agents | few consolidated tools, clear descriptions, meaningful returns, evaluate tool use | registry published with one line each; tool calls counted and classified | no new tools are written for V3; that is Experiment B |

Three deliberate differences from the research system, stated plainly. First, the manager may not
choose the number or kind of workers; the roster is fixed so V3 stays comparable with V2. Second, the
manager may not synthesize findings; that stays with the arbiter, whose rules are already evaluated.
Third, the investigator's world is a frozen repository with verifiable claims, so "evidence" has a
stricter meaning than "sources," and reproduction is possible and expected.

## 13. Proposed branch, version and name

- Branch: `v3/agentic-investigation`, cut from `21c0e29`. This document is its first commit.
- Version: V3.0 when built. V2 is tagged as the baseline before any V3 code lands (see the pending
  `v2.0-baseline` proposal; it should follow the tool-execution fix merge).
- Name: "Agentic Investigation Architecture," provisional. If the evaluation shows the manager is
  rarely load-bearing, "managed investigation" would be the honest name; if it shows the
  investigators' own tool selection carried the result, "investigative review" would be. The name
  follows the data.

## 14. The ASCII diagram, in the form used across the research record

```
Simple prompt
    v   LLM responds once
Advanced prompt
    v   LLM responds once, with better instructions
V1, parallel workflow
    v   fixed reviewers run  ->  fixed merge
V2, managed workflow
    v   fixed reviewers run  ->  systems reviewer adds cross-boundary reasoning  ->  arbiter reasons over completed reports
V3, AGENTIC INVESTIGATION (proposed)
    v   manager assigns investigation
        investigator forms hypothesis
        investigator chooses tool
        environment returns evidence
        manager evaluates the state card
          |-- CONTINUE
          |-- REDIRECT (a question, never an answer)
          |-- COMPLETE
          '-- STOP
        loop, bounded
        v
        arbiter (V2, unchanged)  ->  findings + assurance record (+ investigation log)
```

## 15. Hypotheses, stated so they can fail

To be sealed in the experiment repository before any V3 run, in this form or as amended by review.
All are per run, per subject, unless stated; the known subject and the primary-discovery subject are
graded separately.

- **H0, the null.** Round 0 with every investigator COMPLETE reproduces V2: every measure in section
  10 is within noise of V2's on the same subject. If H0 holds, the answer to the research question is
  no, on these subjects, and that is published.
- **H1.** V3 produces more confirmed defects at evidence quality *reproduced* or *tool-corroborated*
  than V2, per run. Fails if V3 ≤ V2 on the primary-discovery subject.
- **H2.** Iteration is load-bearing: at least one confirmed defect per run on the primary-discovery
  subject is absent from every round-0 card and present in the final report. Fails if every confirmed
  finding was already on a round-0 card, in which case the loop added nothing beyond the addendum.
  (With the charters held constant, round 0 is a faithful V2-comparable baseline, so this test is now
  clean.)
- **H3a, syntactic.** Zero redirects name a suspected defect, by a human reading the log. Fails on
  one. This is the guardrail.
- **H3b, semantic.** Under blind scoring, no redirect scores 2 and the mean score is below 0.5.
  Fails if any redirect scores 2, or the mean is 0.5 or above. This is the measurement.
- **H4.** Compute is bounded: V3's output tokens per confirmed defect are no more than three times
  V2's, per subject. Fails above that, regardless of H1.
- **H5.** Boundary routing does not anchor: findings whose evidence chain includes a boundary
  question are confirmed at a rate within ten points of findings that do not. Fails otherwise.
- **H6.** The addendum does not change the lane: out-of-lane findings per report are within one of
  V2's, and round-0 cards cover the same files as V2's reports on the same subject. Fails otherwise.
  (Revised from revision 1's thin-role hypothesis, which is deferred.)
- **H7.** Repeatability does not collapse: the share of confirmed findings seen in all three runs is
  within ten points of V2's, per subject. Fails otherwise.
- **H8, new.** Budget exhaustion is not the dominant terminator: fewer than a third of investigations
  end by mandatory STOP, and no confirmed defect found by V2 is, in V3, left as a budget-limited
  outcome in two or more of three runs. Fails otherwise, which would mean the budgets, not the
  architecture, decided the result, and the experiment is rerun with revised budgets before anything
  is concluded.

The disconfirming outcomes are written down first: the manager mostly says COMPLETE (H2 fails); cost
rises faster than findings (H4 fails); redirects introduce the anchoring V1 and V2 were built to avoid
(H5 fails); the budgets bind before the loop can matter (H8 fails). Any of those would be the result.

## 16. Variables: what is held constant, what is bundled

**Held constant between V2 and V3, by design.** The model. The six charters, verbatim. The two
shared contracts. The tool registry and its permission scoping. The subject, its hash, and the
description of the change given at round 0. The arbiter and its rules. The output format. The judge,
the rubrics, and the adjudication procedure.

**Bundled inside the V3 treatment, and not separable by this experiment.** Iterative investigation
across rounds. Investigator-controlled tool selection from the registry (V2 reviewers also choose
tools inside one pass; what is new is choosing across rounds with a stated hypothesis). State-card
resumption in place of continuous context. The manager's CONTINUE / REDIRECT / COMPLETE / STOP
decisions. Boundary-question routing through the manager. Additional evidence gathering after round
0. The investigation addendum itself. A difference between arms is attributable to this bundle and to
nothing narrower.

## 17. Deferred ablations, intentionally

Each isolates one element of the bundle and is a separate experiment with its own preregistration.
None is part of Experiment A.

| Ablation | Question | Why deferred |
| --- | --- | --- |
| Thin roles | Does a one-paragraph role at round 0 match the V2 charter, with the loop held constant? | Would confound a V3 loss in the first experiment |
| Full context versus state card | Does an investigator that keeps its whole transcript across rounds find more, or less, than one that resumes from its card? | Requires a runtime that can keep context; changes the treatment |
| Manager removed | Investigators self-direct to a fixed round budget with no manager; does the manager add anything beyond "keep going"? | Tests the manager alone |
| Boundary routing removed | No boundary questions cross investigators; does routing account for the cross-domain findings? | Tests routing alone |
| Tool discovery (Experiment B) | Investigators may find or acquire tools beyond the registry | Second variable; explicitly excluded from A |
| Effort scaling | Budgets vary with change size | Anthropic's research system does this; held constant here so effort is controlled |

## 18. What this design does not do

Discover or acquire tools (Experiment B). Modify any file in the reviewed repository. Remediate.
Change V2. Change any charter. Let the manager or investigators change the roster, the budgets, or
the arbiter's rules. Claim causal isolation of any single element of the treatment. Claim to be
autonomous. Claim to work.

---

**Next, after review of this document and not before:** land the tool-execution fix on V2 and tag the
baseline; instrument V2 baseline runs on both subjects; seal the hypotheses; choose and freeze the
primary-discovery subject; implement the state card, the manager, the investigation addendum and the
loop as a new `/investigate` command beside `/swarm`; write seeds for the manager (deterministic state cards in, decisions out,
the same way the arbiter is seeded) and for investigators (the V2 interaction fixtures, plus fixtures
where the round-0 evidence is insufficient by construction); run the protocol; write it up whichever
way it comes out.
