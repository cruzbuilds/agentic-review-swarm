# 0005: Reviewers get git, not a shell

**Status:** Accepted
**Date:** 2026-09-17

## Context

Every review charter says to read the diff. Two agents, `scope-reviewer` and `docs-reviewer`,
were declared with `Read, Grep, Glob` and nothing else, so neither could run `git`. On two real
reviews `scope-reviewer` said so under Noted and then reviewed the working tree instead. The
report looked exactly like a real one, which is the part that matters: a review of the wrong
thing is worse than no review, because nobody can tell from the output.

Fixing it means giving a reviewer a way to run git. That is not free. A reviewer's only input is
a diff written by whoever wrote the change under review, so the content steering it is untrusted
by construction. Handing that agent a shell is handing untrusted content to a command executor.

The swarm's own security reviewer blocked the first version of this fix for exactly that, and
proved the second half of the problem too: `git` is itself a general command runner.
`git -c alias.x='!sh -c ...' x`, `git -c diff.external=...` and `git -c core.pager=...` all
execute arbitrary commands. So "allow git" is not a restriction unless `-c` is denied.

## Decision

Reviewers are permitted the read-only git subcommands they need, and nothing else.

- **Kiro** can express this in the adapter, so it does: explicit `@shell/git diff*`,
  `git status*`, `git log*`, `git show*` in `allowedTools`, plus `permissions.rules` denying
  `git -c*`, `git --exec-path*`, `git config*` and all `fs_write`. `allowedTools` alone was not
  enough: it is an auto-approval list, not a capability list, and in a headless run there is
  nobody to answer the prompt it falls back to.
- **Claude Code** cannot express command scoping in agent frontmatter. The frontmatter names
  tools; only permission rules name commands. So the adapter grants `Bash` and the scoping lives
  at the run boundary: `scripts/review.sh` writes a `.claude/settings.json` into the scratch
  workspace with an explicit allow list and a deny list for the git escapes, and no longer passes
  bare `Bash` in `--allowedTools`. Deny wins over allow, so the escapes stay shut.
- `scripts/check.sh` fails if any `agents/*-reviewer/` adapter does not permit git, so the
  original defect cannot come back quietly.

## Consequences

**What this costs.** An agent installed by hand into someone's `~/.claude/agents/` carries the
frontmatter but not our settings file, and inherits whatever that person allows `Bash` to do.
The guarantee above holds for `scripts/review.sh`, which is how this repository runs the swarm.
`agents/*/README.md` says so where someone copying a file will see it.

**What remains.** The swarm reviews a throwaway copy in a temp directory, never the real
checkout, so a write goes nowhere that survives. Reads outside the copy and network egress are
not prevented by any of this. A reviewer that is talked into `curl` by a hostile diff is still a
reviewer that ran `curl`. The honest mitigation is the allow list being short and the deny list
being specific, not a claim that the agent is sandboxed. It is not.

**What we gave up.** A bare `Bash` grant would let a reviewer run anything a future charter asks
for without touching this file. Every new command a reviewer needs is now a line in
`scripts/review.sh` and a line in an adapter. That friction is the point.
