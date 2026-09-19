# test-reviewer

Reads a change for one question: if the new behavior broke, would anything notice. It looks at what tests exist for what changed, whether those tests can actually fail, and whether anything was removed or skipped to make the build go green. Reports only. Never edits.

It does not judge whether the code is correct, secure, or documented. It judges whether it's covered. A test's only job is to fail when the thing it tests breaks; a test that can't fail is decoration.

## Install

Claude Code: `/plugin install test-reviewer@agentic-review-swarm`
Kiro: `scripts/install-kiro.sh test-reviewer` from the repo root

## What it blocks on

- New behavior with no test. An explicitly coded error path counts as behavior; an exception that would merely propagate does not (that's a warn)
- A test that can't fail: asserts nothing, asserts a constant, mocks the thing it's supposed to test
- A test removed, skipped, or weakened in the same change that would have made it fail
- Coverage that dropped on the lines that changed

## What it warns on

Tests that depend on wall-clock time, the network, or a real service with no note on determinism. Tests that only pass in a certain order. Slow tests with no reason. One giant test instead of one per behavior. Implicit failure paths with no test. A `sleep` or retry loop in a test, which usually means someone papered over flakiness.

## What it stays out of

Whether the code is correct, secure, or documented. Credentials in test data are the one security thing it flags, as a warn with a handoff to security-reviewer.

## How it works

It runs the test suite if it can, and says so under Noted either way. On a real pull request in this collection's first use, it could not get shell approval in the sandbox it was running in and said so plainly rather than claiming it ran anything. That honesty is the contract. `scripts/review.sh` now passes an allowlist so it can run `git`, `python`, and the project's test command.

## Seeds

Six. Happy path only, a test that mocks its own subject, a new branch with no test, a test skipped to make the build pass, a test that cannot fail, and one clean module with real tests that must PASS.

The full charter is in [charter.md](charter.md).
