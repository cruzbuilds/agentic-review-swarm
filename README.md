# agentic-swarm

Five AI critics that read the same code change at once, each from one angle, each with a written list of what it refuses to let through. Their findings merge into one verdict. Any single BLOCK is a BLOCK.

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
git clone https://github.com/cruzbuilds/agentic-swarm && cd agentic-swarm
scripts/review.sh /path/to/your/repo
```

It copies your repository to a scratch directory, runs the five reviewers there through the Claude Code CLI, and prints one merged report. **Your repository is never touched.** Exit code is 0 for PASS, 1 for WARN, 2 for BLOCK, so it drops into CI. A medium pull request takes four to six minutes.

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

All seven agents exist and have been used on real pull requests. The order they were built in, and why, is in [docs/design.md](docs/design.md).

## Install one agent

You don't need the whole repo. Each agent installs on its own.

**Claude Code**

```
/plugin marketplace add cruzbuilds/agentic-swarm
/plugin install security-reviewer@agentic-swarm
```

Then, in any project: "Use the security-reviewer subagent to review this change."

**Kiro**

```bash
git clone https://github.com/cruzbuilds/agentic-swarm
cd agentic-swarm
scripts/install-kiro.sh security-reviewer
```

That copies the agent into `~/.kiro/agents/` so it's available in every project. Add `--project` to install it into the current project only.

## The agents

Five critics, one interviewer, and one coordinator. Each critic has a narrow lane and a list of things it stays out of, because six agents commenting on the same naming issue bury the one real finding.

| Agent | It blocks on | It stays out of |
| --- | --- | --- |
| [security-reviewer](agents/security-reviewer/) | Credentials in source. Untrusted input reaching a query, shell, or path. Mutating endpoints with no auth check. IAM wildcards. Static cloud keys in CI. Critical dependency vulnerabilities. | Tests, docs, cost, style |
| [docs-reviewer](agents/docs-reviewer/) | README behind the code. Undocumented environment variables. Constraining decisions with no ADR. Cloud resources with no teardown. "Not production ready" with no specifics. | Whether the code works, is secure, or is tested |
| [infra-reviewer](agents/infra-reviewer/) | Hardcoded resource identifiers. Static cloud keys in CI. Mutable action versions on deploy steps. Infrastructure with no teardown. No `permissions:` block on a job that can reach something. Resources nobody could identify later. | Application logic, whether infrastructure is attackable, tests |
| [test-reviewer](agents/test-reviewer/) | New behavior with no test. A test that can't fail. A test removed or skipped to go green. Coverage dropped on the changed lines. | Whether the code is correct, secure, or documented |
| [scope-reviewer](agents/scope-reviewer/) | Work that wasn't agreed. Work that was explicitly excluded. A constraining decision with no ADR. A new dependency with no reason written down. | How the code is written, and whether the scope was a good idea |
| [engagement-guide](agents/engagement-guide/) | Not a critic. Interviews you to fill out the intake, discovery, scope, or handoff document, and never fills in a blank you didn't answer. | Writing anything you didn't say |
| [swarm](agents/swarm/) | Not a critic. Runs the five reviewers in parallel and merges their reports into one. Any single BLOCK is a BLOCK. | Reviewing anything itself |

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

`review.sh` copies the repository to a scratch directory, installs the built agents there, runs `/swarm` through the Claude Code CLI, and prints the merged report. Exit code is 0 for PASS, 1 for WARN, 2 for BLOCK. The repository you point it at is never touched. A five-agent review of a medium pull request takes four to six minutes.

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
- `README.md` doesn't mention the new `REPORTS_BUCKET` variable. That's docs-reviewer's call.
```

BLOCK means don't merge until it's fixed. WARN means there's a real problem that doesn't block on its own, or the agent sees something it can't prove. PASS means the agent checked everything in its lane and found nothing. It never means "looks good."

That last section, "Out of my lane," is what makes several agents work together. An agent that notices something outside its job hands it off instead of ignoring it or piling on. The full format and the rules behind it are in [shared/](shared/).

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

The runner needs the Claude Code CLI installed and signed in, and it costs tokens, roughly one short review per seed. Failed seeds save the agent's actual report under `.seed-reports/` so you can read what it said.

When an agent misses something on a real repository, that becomes a new seed.

## Adding an agent

1. Copy an existing agent's folder. Rename it.
2. Write `charter.md`. Mandate, what it blocks on, what it warns on, what it stays out of, how it works. Read [shared/review-contract.md](shared/review-contract.md) first.
3. Adjust the two adapter files. Usually just the name and description.
4. Write at least five seeds, including a clean one.
5. `scripts/build.sh`, then `scripts/run-seeds.sh your-agent` until they pass.
6. Add it to `.claude-plugin/marketplace.json` and to the table above.

## What's here besides the agents

| Path | What |
| --- | --- |
| `shared/` | The output format and the review rules every agent follows |
| `scripts/` | build, install, run-seeds, review (run the swarm on any repo), and the health check CI runs |
| `engagement/` | Why this exists: the intake, discovery, and scope that led to it |
| `docs/design.md` | The shape of the repo and the reasoning |
| `docs/decisions/` | Individual decisions, recorded as ADRs |
| `AGENTS.md` | Working agreement for coding agents changing this repo |

This repo was generated from [project-starter](https://github.com/cruzbuilds/project-starter) and is the first real use of it.

## Status

Working, and in use. Seven agents, 35 seeds passing, five real pull requests reviewed on [shelflife](https://github.com/cruzbuilds/shelflife), and two on this repository. Every review came back BLOCK at least once.

Across five swarm passes: 14 blocking findings, 19 should-fix, 3 handoffs, 1 noted. 32 accepted and fixed in the same pull request, 4 no change needed, 0 overridden, and by the author's own count 21 of 33 actionable findings would have been missed without the review. The per-finding scorecards, including the would-have-missed column, are in that project's [docs/review-log.md](https://github.com/cruzbuilds/shelflife/blob/main/docs/review-log.md).

Real use has fixed the swarm three times so far, all logged in [docs/eval-log.md](docs/eval-log.md): the agents were never told who else was on the team, so one invented a teammate to hand a finding to; the built agent files were gitignored, so the plugin install could not have worked for anyone but the author; and two reviewers were declared without a shell, so they could not run git and reviewed the working tree instead of the diff while their reports looked entirely normal ([ADR 0005](docs/decisions/0005-reviewers-get-git-not-a-shell.md)).

**What it is not.** It is not a substitute for a human reviewer, and it does not judge whether your code is any good, on purpose: there is no general code reviewer here, and [ADR 0004](docs/decisions/0004-no-general-code-reviewer.md) says why. Token cost per review has not been measured yet ([#5](https://github.com/cruzbuilds/agentic-swarm/issues/5)). The agents run on a copy of your repository and are told never to edit anything, which is enforced by the tools they are granted, not by trust.

This is a personal project, built in the open to find out whether narrow written charters beat one general "review this" prompt. So far the log says they do.
