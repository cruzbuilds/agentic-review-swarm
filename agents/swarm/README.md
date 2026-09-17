# swarm

Runs every installed review agent on the same change at the same time and folds their five reports into one. It reviews nothing itself. It coordinates and it merges.

On Claude Code this is the `/swarm` command rather than a subagent, because subagents can't spawn subagents there. On Kiro it's an agent that lists the others as available. Either way you get one report with one verdict.

## Install

Claude Code: `/plugin install swarm@agentic-swarm` (install the reviewers too, or it has nothing to run)
Kiro: `scripts/install-kiro.sh --all` from the repo root

Then: `/swarm` on Claude Code, or `/swarm main..HEAD` for a specific range. From a terminal with no setup in the target repository, use `scripts/review.sh /path/to/repo` from this repo.

## How it merges

- Any single BLOCK is a BLOCK. WARN if any agent warned and none blocked. PASS only if every agent passed
- Findings are grouped by file, not by agent, so a person fixes things in the order they'd open files
- When two agents report the same line, one entry, both names
- Each agent's "Out of my lane" handoffs are matched against what the target agent actually reported. A handoff that landed is dropped as redundant. A handoff nobody picked up goes into its own section so it can't be lost
- Agents that were not installed are listed under Skipped, so a PASS from three agents is never mistaken for a PASS from five

## What it caught on its first real use

On the first pull request of [shelflife](https://github.com/cruzbuilds/shelflife), one agent handed a finding to a "code-reviewer" that does not exist in this collection. The merge step listed it under "Handoffs nobody picked up" instead of dropping it, which is the right failure mode. The root cause, that no agent was told who else exists, was fixed the same day: the shared contract now carries the roster. Details in [docs/eval-log.md](../../docs/eval-log.md).

## Seeds

One, `three-lanes`: a change with a secret, a missing README section, and an untested function, so the merge has to pull one finding from each of three different agents and attribute each correctly.

The full charter is in [charter.md](charter.md).
