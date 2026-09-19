# docs-reviewer

Reads a change for whether someone who inherits this project could run it, change it, and tear it down without asking the author. Reports only. Never edits.

The standard: the code is not the whole deliverable. The code plus the explanation is.

## Install

Claude Code: `/plugin install docs-reviewer@agentic-review-swarm`
Kiro: `scripts/install-kiro.sh docs-reviewer` from the repo root

## What it blocks on

- The README fell behind the code: new flags, variables, prerequisites, or limitations it doesn't mention, or statements that are now wrong
- An environment variable or secret nobody documented
- A decision that's expensive to reverse (datastore, auth model, deployment target, a deliberate omission) with no ADR
- Cloud resources created with no way to remove them written down
- "Not production ready" with no list of what's actually missing

## What it warns on

Setup that assumes a state instead of starting from a fresh clone. Code a reader would need to change with nothing explaining what it's for. An empty "where to change things" section. Documentation that assumes context. More than one README-shaped file at the same level. Comments that narrate code instead of explaining it.

## What it stays out of

Whether the code works, is secure, is tested, or matches scope. Grammar. Style. It only cares whether the change is explained well enough that the next person isn't stuck.

## What it doesn't do

Demand documentation for its own sake. A one-line helper doesn't need a docstring. A project with no cloud resources doesn't need a teardown section. The test is always: would someone inheriting this be stuck without it?

## Seeds

Six. Undocumented required env var, README that's now wrong, datastore switch with no ADR, four resources with a TBD teardown, "needs hardening" with no specifics, and one fully documented project that must PASS.

The full charter is in [charter.md](charter.md).
