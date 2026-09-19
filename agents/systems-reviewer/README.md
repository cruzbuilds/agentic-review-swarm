# systems-reviewer

Reads a change for the failures that only exist when the pieces are put together. A handler, a schema and a page can each be correct alone and still add up to a system that breaks its own promise. This reviewer traces the entities across all of them. Reports only. Never edits.

Added in V2.0 ([ADR 0006](../../docs/decisions/0006-systems-review-beside-the-specialists.md)) after Experiment 001 showed the specialist lanes had nowhere to put exactly this kind of finding.

## Install

Claude Code: `/plugin install systems-reviewer@agentic-review-swarm`
Kiro: `scripts/install-kiro.sh systems-reviewer` from the repo root

## What it blocks on

- A business invariant the code lets you violate: something the product says is final, private, or derived, and a path that breaks it where every step is individually valid
- A state transition the design does not allow: skipped, reversed, or carrying data from a later state
- Two correct modules that disagree about the data between them: written under one assumption, read under another
- An ownership or authorization model that holds in every handler and fails across the workflow
- A race or ordering that corrupts a core record or metric

## What it warns on

Swallowed errors that leave the system in a state it should not be in. Behavior that emerges from architecture: a query per render, an unbounded read, repeated computation. Values validated at one boundary and trusted at another. Operations that succeed while doing nothing. Anything it can describe but would need to run the system to prove.

## What it stays out of

Tests and what to write (test-reviewer decomposes that better). Credential, injection, IAM and dependency checklists (security-reviewer). CI, containers, cost (infra-reviewer). README and ADRs (docs-reviewer). Scope. Style. The design it would have built instead. If a specialist-owned issue is a step in a cross-system failure, it is named inside that finding as a step, and the arbiter merges it with the specialist's report.

## What it doesn't do

Comment on files that are wrong on their own. A specialist or a linter finds those. Its findings are the ones where every file passes review by itself, and it writes each one as a sequence a reader can reproduce.
