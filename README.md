# agentic-swarm

[![CI](https://github.com/cruzbuilds/agentic-swarm/actions/workflows/ci.yml/badge.svg)](https://github.com/cruzbuilds/agentic-swarm/actions/workflows/ci.yml)
[![Agents](https://img.shields.io/badge/agents-7-8A2BE2)](agents/)
[![Seeds passing](https://img.shields.io/badge/seeds-35%20passing-brightgreen)](docs/eval-log.md)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

Specialized AI review agents. Each one reads a code change from one angle, refuses to pass specific problems, and reports in a shared format. Install one, or all of them.

**Agentic Swarm Development** is the idea behind it: many narrow reviewers examine the same change at once, each with a defined lane and a list of what it won't let through, and their findings merge into a single verdict. Agents criticize. People build.

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

Each agent is three things kept separate:

```
agents/security-reviewer/
├── charter.md          what it's for, what it blocks on, what it stays out of. The source of truth.
├── adapters/
│   ├── claude.yaml     a few lines of frontmatter for Claude Code
│   └── kiro.yaml       a few lines of frontmatter for Kiro
├── dist/               generated. adapter + shared contracts + charter, per tool. Don't edit.
└── seeds/              tests. Each one is a planted defect with an expected verdict.
```

`scripts/build.sh` glues the adapter onto the charter and writes `dist/`. It's not a build system, it's `cat`. But it means the thinking behind an agent lives in one file and never drifts between tools.

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

Working, and in use. Seven agents, 35 seeds passing, and four real pull requests reviewed on [shelflife](https://github.com/cruzbuilds/shelflife), a project built with this swarm reviewing every change before it opens. Every review came back BLOCK at least once. Across four swarm passes: 12 blocking findings, 16 should-fix, 27 accepted and fixed in the same pull request, none overridden, and by the author's own count 18 of 30 would have been missed without the review. The per-finding scorecards are in that project's [docs/review-log.md](https://github.com/cruzbuilds/shelflife/blob/main/docs/review-log.md).

Two findings worth naming. A reviewer stood up a local server and proved the tool would follow an HTTP redirect to `127.0.0.1`, a request-forgery hole in code written an hour earlier. And on a second pass, the agents were handed a review log claiming everything had been fixed, treated that as a claim to verify rather than a fact, and found what it missed.

Real use has fixed the swarm twice so far, both logged in [docs/eval-log.md](docs/eval-log.md): the agents were never told who else was on the team, so one invented a teammate to hand a finding to; and the built agent files were gitignored, so the plugin install could not have worked for anyone but the author.

Not done: no CI integration, reviews run when a person runs them. Token cost per review has not been measured. The seeds test each agent alone; the interactions between agents have only been exercised on real pull requests.

## License

MIT. See [LICENSE](LICENSE).
