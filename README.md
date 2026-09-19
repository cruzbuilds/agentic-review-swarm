# agentic-review-swarm

Six AI reviewers read the same code change at once. Five have a narrow lane and a written list of what they refuse to let through. One has a wide lane on purpose: the failures that only exist between the pieces. An arbiter turns their reports into one verdict, one list of findings, and one record of what was and was not checked. Any single BLOCK is a BLOCK.

**Broad reasoning catches what crosses boundaries. Specialists go deep where consistency and explicit coverage matter. The arbiter combines both into one review record.**

This is V2. V1 was five specialists and a merge, and it was tested before it was trusted: [Experiment 001](https://github.com/cruzbuilds/Five-Critics-or-One-Good-Prompt) put it against one strong generalist prompt and one naive one on a frozen application. The specialists tied the strong generalist on confirmed defects, were more repeatable, and produced the only inspection record; they also filed the most consequential defect in the subject under "nobody owns this" because no lane covered it. V2 is the architecture that came out of that. It has not been measured yet; that is Experiment 002, which has not started. The full V1 record is preserved at [`v1-experiment-final`](https://github.com/cruzbuilds/agentic-review-swarm/releases/tag/v1-experiment-final), and the decision is [ADR 0006](docs/decisions/0006-systems-review-beside-the-specialists.md). The program narrative lives in [agentic-review-lab](https://github.com/cruzbuilds/agentic-review-lab).

## Reading order

This repository is a research record as well as a tool. If you are here to understand how the architecture evolved and what each experiment found, read in this order; each link goes one level deeper and nothing is repeated across levels more than it has to be.

1. This README, through the [evolution](#how-the-architecture-evolved) and [next question](#the-next-question) sections at the end.
2. [`docs/research/v2-hybrid-review.md`](docs/research/v2-hybrid-review.md): the V2 research record. V1 as tested, what Experiment 001 did and did not establish, the hypothesis, what changed, every evaluation with its numbers, what is and is not demonstrated, contradictions found, the next question.
3. [Experiment 001](https://github.com/cruzbuilds/Five-Critics-or-One-Good-Prompt), a separate repository: `README.md`, then `ANALYSIS.md` section 13, then the rest as needed. Raw reports, sealed predictions, deviations and verdicts are all there.
4. [`docs/design.md`](docs/design.md): the shape of this repository, the V1/V2 comparison table, the V2.1 variant that was set aside.
5. [`docs/decisions/`](docs/decisions/): the individual choices. [0004](docs/decisions/0004-no-general-code-reviewer.md) is V1's reasoning against a general reviewer; [0006](docs/decisions/0006-systems-review-beside-the-specialists.md) supersedes its central assumption and says why.
6. [`docs/eval-log.md`](docs/eval-log.md): chronological, what evaluation found, including the runs that found bugs in the fixtures.
7. [`docs/evals/`](docs/evals/): every graded run with its raw reports: `systems-reviewer/run-001`, `swarm/run-001`, `integrated/run-001`. Read a `GRADING.md` first, then the report it cites.
8. The charters themselves: [`agents/*/charter.md`](agents/) and [`shared/`](shared/). The systems reviewer's and the swarm's are the V2 ones.
9. [agentic-review-lab](https://github.com/cruzbuilds/agentic-review-lab): the program narrative across all the repositories, and the paper draft when it is published.

## What it caught

Every pull request on [shelflife](https://github.com/cruzbuilds/shelflife) was reviewed by this swarm before it opened. Five pull requests, **37 findings**, 14 of them blocking, **0 overridden**. By the author's own count, **21 of the 33 actionable findings would have been missed** reading the diff alone. Every finding is written down, with an honest column for whether a human would have caught it: [docs/review-log.md](https://github.com/cruzbuilds/shelflife/blob/main/docs/review-log.md).

Three of them are worth naming, because they are the ones a careful person reading the diff does not find.

- A reviewer **stood up a local HTTP server and proved** the tool would follow a redirect to `127.0.0.1`. A request-forgery hole, in code written an hour earlier, that its author felt fine about.
- On a second pass, the agents were handed a review log saying everything had been fixed. They treated that as **a claim to verify rather than a fact**, and found what it missed.
- Asked to review a change to *this repository* that widened its own agents' permissions, the swarm **blocked it twice** and proved both blocks: that `git -c alias.x='!sh -c ...'` makes "allow git" mean "allow everything", and that the guard added in the same commit could be fooled by the word "shell" appearing in a description line.

That last one is the argument in miniature. The author wrote the guard, believed it worked, and the reviewer disproved it with a command instead of an opinion.

## Sixty seconds to your first review

No install, any repository, from a terminal:

```bash
git clone https://github.com/cruzbuilds/agentic-review-swarm && cd agentic-review-swarm
scripts/review.sh /path/to/your/repo
```

It copies your repository to a scratch directory, runs the six reviewers there through the Claude Code CLI, and prints the arbitrated report: findings first, assurance record second. **Your repository is never touched.** Exit code is 0 for PASS, 1 for WARN, 2 for BLOCK, so it drops into CI. A medium pull request takes four to six minutes.

## How an agent is put together

One file is the agent. Everything else is plumbing.

```
charter.md          what it blocks on, warns on, and stays out of. Written in English. The source of truth.
     │
     ├── adapters/claude.yaml ──┐
     └── adapters/kiro.yaml ────┤   scripts/build.sh
                                └──> dist/claude/<agent>.md   installable in Claude Code
                                     dist/kiro/<agent>.md     installable in Kiro

seeds/              planted defects with the verdict each one should get. The agent has to pass them
                    before it reviews anything real.
```

The charter is the part you would argue with. It is prose, not configuration, and changing what an agent cares about means editing a paragraph rather than tuning a prompt you cannot read. The adapters are a few lines of frontmatter each, so the same thinking installs in two different tools without drifting apart.

All eight agents exist. The seven from V1 have been used on real pull requests; `systems-reviewer` has passed its seeds and is waiting for real use. The order they were built in, and why, is in [docs/design.md](docs/design.md).

## Install one agent

You don't need the whole repo. Each agent installs on its own.

**Claude Code**

```
/plugin marketplace add cruzbuilds/agentic-review-swarm
/plugin install security-reviewer@agentic-review-swarm
```

Then, in any project: "Use the security-reviewer subagent to review this change."

**Kiro**

```bash
git clone https://github.com/cruzbuilds/agentic-review-swarm
cd agentic-review-swarm
scripts/install-kiro.sh security-reviewer
```

That copies the agent into `~/.kiro/agents/` so it's available in every project. Add `--project` to install it into the current project only.

## The agents

Six reviewers, one interviewer, and one arbiter. Five reviewers have a narrow lane and a list of things they stay out of, because six agents commenting on the same naming issue bury the one real finding. The sixth has the lane none of them can: the behavior of the whole.

| Agent | It blocks on | It stays out of |
| --- | --- | --- |
| [security-reviewer](agents/security-reviewer/) | Credentials in source. Untrusted input reaching a query, shell, or path. Mutating endpoints with no auth check. IAM wildcards. Static cloud keys in CI. Critical dependency vulnerabilities. | Tests, docs, cost, style |
| [docs-reviewer](agents/docs-reviewer/) | README behind the code. Undocumented environment variables. Constraining decisions with no ADR. Cloud resources with no teardown. "Not production ready" with no specifics. | Whether the code works, is secure, or is tested |
| [infra-reviewer](agents/infra-reviewer/) | Hardcoded resource identifiers. Static cloud keys in CI. Mutable action versions on deploy steps. Infrastructure with no teardown. No `permissions:` block on a job that can reach something. Resources nobody could identify later. | Application logic, whether infrastructure is attackable, tests |
| [test-reviewer](agents/test-reviewer/) | New behavior with no test. A test that can't fail. A test removed or skipped to go green. Coverage dropped on the changed lines. | Whether the code is correct, secure, or documented |
| [scope-reviewer](agents/scope-reviewer/) | Work that wasn't agreed. Work that was explicitly excluded. A constraining decision with no ADR. A new dependency with no reason written down. | How the code is written, and whether the scope was a good idea |
| [systems-reviewer](agents/systems-reviewer/) | New in V2. A business invariant the code lets you violate across individually valid steps. A state transition the design does not allow, reached by a valid operation. Two correct modules that disagree about shared data. An ownership model that holds per handler and fails across the workflow. A race that corrupts a core record. Every one must require reasoning across a boundary. | Style. Test decomposition. Specialist checklists. Any defect it can establish from one local operation, which it hands to the arbiter as unowned. |
| [engagement-guide](agents/engagement-guide/) | Not a critic. Interviews you to fill out the intake, discovery, scope, or handoff document, and never fills in a blank you didn't answer. | Writing anything you didn't say |
| [swarm](agents/swarm/) | Not a critic. Runs the six reviewers in parallel, then arbitrates: merges with attribution, carries unowned findings with a severity and confidence, records disagreements, and writes the assurance record. Any single BLOCK is a BLOCK; a missing reviewer caps at WARN. | Reviewing anything itself. It may not open a file or run a tool. |

Each agent's folder has a README with the full list and the reasoning behind it, and a `charter.md` that is the agent.

## Run the whole swarm

Inside a project on Claude Code, after installing the agents:

```
/swarm
/swarm main..HEAD
```

From a terminal, against any repository, with nothing installed in it:

```bash
scripts/review.sh /path/to/repo              # this branch vs main, plus uncommitted changes
scripts/review.sh /path/to/repo main..HEAD   # any git range
```

`review.sh` copies the repository to a scratch directory, installs the built agents there, runs `/swarm` through the Claude Code CLI, and prints the arbitrated report. Exit code is 0 for PASS, 1 for WARN, 2 for BLOCK. The repository you point it at is never touched. A six-reviewer review of a medium pull request takes about five to seven minutes; the V1 figure was four to six.

## What a review looks like

Every agent reports in the same shape, every time:

```markdown
## security-reviewer

**Verdict:** BLOCK

### Blocking
- `src/handler.py:5` AWS access key hardcoded. It's live the moment it's pushed and
  stays in git history after it's deleted. Rotate it now and load it from the
  environment.

### Should fix
(none)

### Noted
- semgrep isn't installed here, so static analysis was skipped. Findings above are
  from reading the code directly.

### Out of my lane
- `README.md` -> docs-reviewer. Doesn't mention the new `REPORTS_BUCKET` variable.
- `src/export.py:27` -> no owner. Filename built from `account.name` with no sanitizing; reproduced a write outside the export root. Sanitize and resolve against the root.
```

BLOCK means don't merge until it's fixed. WARN means there's a real problem that doesn't block on its own, or the agent sees something it can't prove. PASS means the agent checked everything in its lane and found nothing. It never means "looks good."

That last section, "Out of my lane," is what makes several agents work together. An agent that notices something outside its job hands it off instead of ignoring it or piling on. In V1 a handoff that nobody owned stayed visible but could never affect the verdict; in V2 the `-> no owner` form carries enough for the arbiter to give it a severity, and it can. The full format and the rules behind it are in [shared/](shared/).

The arbitrated report has two parts. **Findings**, grouped by file, tagged with every reviewer that raised each one, with unowned findings and disagreements as their own sections. **Assurance record**: which reviewer ran, what each says it covered, which tools ran or failed, how many findings two reviewers found independently, every severity the arbiter assigned and why, and how the verdict was derived. The first is for whoever fixes the code. The second is for whoever has to decide whether to trust the review. Both templates are in [agents/swarm/charter.md](agents/swarm/charter.md).

## How it's built

The three layers are sketched at the top. What that leaves out:

`scripts/build.sh` glues the adapter onto the charter and writes `dist/`. It is not a build system, it is `cat`. But it means the thinking behind an agent lives in one file and never drifts between tools, and `scripts/check.sh` fails if a committed `dist/` no longer matches its charter.

`dist/` is generated and should never be edited by hand. Each built file carries the two shared contracts ([shared/](shared/)) prepended, so an installed agent is self-contained once it is copied into someone's `~/.claude/agents/` and can no longer reach back into this repository.

The reasoning for all of this is in [docs/design.md](docs/design.md) and the individual decisions are in [docs/decisions/](docs/decisions/).

## Proving an agent works

This is the part that separates a review agent from a confident prompt.

```bash
scripts/run-seeds.sh                       # every agent, every seed
scripts/run-seeds.sh security-reviewer     # one agent
scripts/run-seeds.sh docs-reviewer clean   # one seed
```

Each seed is a small folder with one deliberate problem and a file saying what the agent should say about it. There's also a clean seed with nothing wrong, because an agent that blocks everything is as useless as one that passes everything.

Two kinds of seed are different in V2. The systems reviewer's seeds are several files each, every file locally reasonable, with a defect that exists only in their interaction; the grading asks whether the reviewer reconstructed the interaction, not just whether it said BLOCK. The arbiter's seeds are saved reviewer reports with a prompt to arbitrate them, so its rules are tested without the reviewers' variance. Every eval run is preserved as graded under [docs/evals/](docs/evals/), including the runs where the fixtures turned out to be wrong.

The runner needs the Claude Code CLI installed and signed in, and it costs tokens, roughly one short review per seed. Failed seeds save the agent's actual report under `.seed-reports/` so you can read what it said.

When an agent misses something on a real repository, that becomes a new seed.

## Adding an agent

1. Copy an existing agent's folder. Rename it.
2. Write `charter.md`. Mandate, what it blocks on, what it warns on, what it stays out of, how it works. Read [shared/review-contract.md](shared/review-contract.md) first.
3. Adjust the two adapter files. Usually just the name and description.
4. Write at least five seeds, including a clean one.
5. `scripts/build.sh`, then `scripts/run-seeds.sh your-agent` until they pass.
6. Add it to `.claude-plugin/marketplace.json`, to the roster in [shared/review-contract.md](shared/review-contract.md) and in `agents/swarm/charter.md`, and to the table above.

## What's here besides the agents

| Path | What |
| --- | --- |
| `shared/` | The output format and the review rules every agent follows |
| `scripts/` | build, install, run-seeds, review (run the swarm on any repo), and the health check CI runs |
| `engagement/` | Why this exists: the intake, discovery, and scope that led to it |
| `docs/design.md` | The shape of the repo and the reasoning |
| `docs/decisions/` | Individual decisions, recorded as ADRs. 0004 (no general reviewer) is the V1 decision; 0006 supersedes its central assumption and says why |
| `docs/evals/` | Every evaluation run, graded, with the raw reports, including the ones that found bugs in the fixtures |
| `AGENTS.md` | Working agreement for coding agents changing this repo |

This repo was generated from [project-starter](https://github.com/cruzbuilds/project-starter) and is the first real use of it.

## Status

**V2.0, on a branch, seeds passing, not yet used on a real pull request.** Eight agents. Every V1 seed still passes. The systems reviewer passed five of five interaction seeds on its first run and found a real defect in the sixth, which had been written as clean. The arbiter passed nine of nine, including the case where opening a file would have resolved an ambiguity and it refused. Both runs are graded in [docs/evals/](docs/evals/) exactly as they happened.

**V1** is tagged [`v1-experiment-final`](https://github.com/cruzbuilds/agentic-review-swarm/releases/tag/v1-experiment-final): seven agents, 35 seeds, five real pull requests reviewed on [shelflife](https://github.com/cruzbuilds/shelflife), two on this repository, every review BLOCK at least once. Across five swarm passes: 14 blocking findings, 19 should-fix, 3 handoffs, 1 noted; 32 accepted and fixed in the same pull request, 4 no change needed, 0 overridden, and by the author's own count 21 of 33 actionable findings would have been missed without the review. Scorecards in that project's [docs/review-log.md](https://github.com/cruzbuilds/shelflife/blob/main/docs/review-log.md).

Real use fixed V1 three times before the experiment and the experiment fixed it once more, all logged in [docs/eval-log.md](docs/eval-log.md): one agent invented a teammate to hand a finding to; the built files were gitignored so nobody else could install them; two reviewers had no shell and reviewed the working tree instead of the diff ([ADR 0005](docs/decisions/0005-reviewers-get-git-not-a-shell.md)); and then all five ran an entire study with their tools silently denied by the harness that was meant to scope them.

**What Experiment 001 found, honestly.** The five specialists tied a strong generalist prompt on confirmed defects and beat a naive one by eight hygiene items. Their real advantages were decomposition (thirteen module-level test items where a generalist said "no tests" once), repeatability, and the per-agent inspection record. Their real cost was a structural blind spot: the most consequential defect in the subject was noticed by a specialist and filed under "Handoffs nobody picked up" because no lane owned correctness. Both generalists beat the security specialist inside its own lane, and the reason is not established. Four of five sealed predictions failed. The write-up is in the [experiment repository](https://github.com/cruzbuilds/Five-Critics-or-One-Good-Prompt); this README does not claim five critics beat one prompt, because they did not.

**What V2 changes, and what it does not.** A systems reviewer beside the specialists, an arbiter in place of the merge, unowned findings that can affect the verdict, disagreements as a section, and the assurance record as its own document. No specialist charter changed. No sequencing: every reviewer still runs independently and in parallel, so V2 stays comparable with V1. The broad-first variant, where the systems review runs first and steers the specialists, is recorded as V2.1 in [docs/design.md](docs/design.md) and is not built.

**What it is not.** It is not a substitute for a human reviewer. The systems reviewer is not a general code reviewer; it has a mandate and an exclusion list, and [ADR 0006](docs/decisions/0006-systems-review-beside-the-specialists.md) explains the difference from the agent [ADR 0004](docs/decisions/0004-no-general-code-reviewer.md) rejected. V2 is not claimed to be better than V1; it is the hypothesis Experiment 001 produced, with evals behind the mechanism and no measurement yet of the outcome. Token cost per review is recorded for V2 evals and was not for V1. The agents run on a copy of your repository and are told never to edit anything, which is enforced by the tools they are granted, not by trust.

## How the architecture evolved

Four steps, each one measured against the one before it, with the evidence preserved.

**1. A simple review prompt.** Twenty-four words: "Review this repository as if it were about to go into production. Find anything you think should be fixed or investigated before it ships." Run as arm C of Experiment 001, after the fact. It found every merge-blocking defect in the subject in every run, ran the build and the linters without being told to, and wrote a probe to prove a bcrypt truncation. It found 30 confirmed defects at 81% precision. Most of what the next two steps were built to add was already in the model.

**2. A structured prompt.** One hundred seventy words naming eleven domains, asking for absences as well as defects, and fixing an output shape. Arm A. It found 38 confirmed defects at 81% precision, eight more than the simple prompt, none of them high-value, at the cost of consistency (44% of its findings recurred in every run against 60%) and roughly double the report length. What direction bought was breadth in hygiene lanes, not detection of the things that mattered most.

**3. V1: parallel specialist review.** Five reviewers with written charters, run independently, merged by any-BLOCK-is-BLOCK. Built on the assumption that comprehensive review decomposes into lanes and that a narrow charter finds more inside its lane. It tied the structured prompt at 38 confirmed defects, was the most repeatable (66%), decomposed "no tests" into thirteen actionable items every run, and produced the only per-agent record of what was checked. It also filed the most consequential defect in the subject under "Handoffs nobody picked up" because no lane owned correctness, and lost its own security lane to both generalists, 11 and 11 to 7. Four of five sealed predictions failed. Tagged [`v1-experiment-final`](https://github.com/cruzbuilds/agentic-review-swarm/releases/tag/v1-experiment-final).

**4. V2: specialists, a systems reviewer, and an evidence-aware arbiter.** The reading of step 3 was that the specialists were not poor reviewers; the architecture had no owner for defects that emerge between reasonable local operations, and its merge did not reason about provenance, corroboration, disagreement, coverage, or findings nobody owned. V2 keeps the five specialists unchanged and parallel, adds a sixth reviewer whose mandate is interactions and whose eligibility rule forbids local findings, and replaces the merge with an arbiter that assigns severity and confidence to unowned findings from the reviewer's own evidence, records disagreements, caps the verdict when coverage is incomplete, and cannot open a file. On its evaluations it does what it was designed to do: five of five interaction seeds reconstructed, seventeen of seventeen deterministic arbitrations, no regressions in the V1 suite, and three fixtures found to contain defects their author had not planted. It has not been compared with V1 on any subject and has not reviewed a real pull request. The full record is [`docs/research/v2-hybrid-review.md`](docs/research/v2-hybrid-review.md).

What changed between each step is the amount and shape of direction: none, a paragraph, five charters, five charters plus a lane for what falls between them and a rule for what to do with it. What the evidence says so far is that direction bought breadth, decomposition, repeatability and a record, and did not buy detection of the worst defects, which the model found at zero direction. The architecture changed because that is what the data showed, and the change is a hypothesis until it is measured.

## The next question

V2 improved the architecture without adding hierarchy or iterative control. Every reviewer still receives a task, investigates once, and returns a report. The arbiter reasons over those reports and nothing else, on purpose. Nothing in the system looks at a reviewer's intermediate evidence and decides whether the investigation should continue, which tool it should reach for next, or whether its hypothesis should change. In the arbiter's own evaluation there was a moment where the right next step was obvious, open the file and settle which of two descriptions was true, and the architecture correctly forbade it, because nobody was chartered to go back and look.

That produces the next research question, recorded here and not yet designed:

> Does review quality improve when static reviewers become managed investigators, able to gather evidence iteratively, choose tools, revise hypotheses, and be directed to continue when their evidence is incomplete?

Nothing in this repository implements that. Before it: V2 on real pull requests, its failures collected into seeds, the known fixture defects repaired, and a decision about whether Experiment 002 compares V1 with V2 or V2 with what comes after.

This is a personal project, built in the open. It started to find out whether narrow written charters beat one general "review this" prompt. The answer was no, not on their own, and the architecture changed because the evidence did.
