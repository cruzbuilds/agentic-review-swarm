# scope-reviewer

Reads a change for two questions: is this what was agreed to build, and was the reasoning behind any big choice written down. It reads the diff against `engagement/03-scope.md` and `docs/decisions/`. It does not care how the code is written. It cares whether it should have been written. Reports only. Never edits.

This agent only makes sense in a repository with an `engagement/` folder. Without one it says so under Noted and returns PASS, because blocking for a missing document would be blocking the wrong thing.

## Install

Claude Code: `/plugin install scope-reviewer@agentic-review-swarm`
Kiro: `scripts/install-kiro.sh scope-reviewer` from the repo root

## What it blocks on

- Work that isn't in scope. Not "bad work," just work nobody agreed to
- Work that the scope document explicitly lists as out of scope
- A decision that constrains future work with no ADR: a datastore, an auth model, a public interface, a boundary between components
- A new dependency with no justification written down

## What it warns on

Acceptance criteria that can't be checked against the change. A change that touches an assumption the discovery document listed as unverified. A scope document with no confirmed-with line, or one older than the intake. An ADR still marked Proposed while the code treats it as settled. A handoff document that the change has made wrong.

## What it stays out of

Whether the code works, is secure, is tested, or is documented. Whether the scope itself was a good idea (it was agreed; this agent holds the change to it). Style. Whether an ADR is well written, which is docs-reviewer's call; whether it exists is this agent's.

## What it caught on its first real use

On the first pull request of [shelflife](https://github.com/cruzbuilds/shelflife), it found that JSON input had shipped as a documented feature when scope said YAML only, and that the comment justifying it in the code was not true. The author had added it to make tests easier and dressed it up as a feature. The reviewer named the rationalization. That finding is in that project's `docs/review-log.md`.

## Seeds

Seven. Out-of-scope feature, explicitly excluded work, a decision with no ADR, an unjustified dependency, a repository with no engagement folder (must PASS), a change with dead code that no agent owns (must not invent a "code-reviewer" to hand it to), and one clean change that must PASS.

The full charter is in [charter.md](charter.md).
