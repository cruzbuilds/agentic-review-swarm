# security-reviewer

Reads a change for the ways it can be attacked or leak something it shouldn't. Reports only. Never edits.

## Install

Claude Code: `/plugin install security-reviewer@agentic-review-swarm`
Kiro: `scripts/install-kiro.sh security-reviewer` from the repo root

## What it blocks on

- Credentials anywhere git can see them: keys, tokens, passwords, tracked `.env` files
- Untrusted input reaching a query, a shell command, a file path, a deserializer, or an HTML response without validation
- Create, update, or delete operations with no authorization check
- IAM with `*` where the workload could be scoped
- Static cloud credentials in CI where OIDC is available
- A dependency with a known critical or high vulnerability

## What it warns on

Sensitive values in logs, weak password hashing, TLS verification off, `CORS: *` on authenticated routes, tokens with no expiry, no rate limiting on auth endpoints, stack traces in error responses, secrets with hardcoded fallback values, moderate dependency vulnerabilities.

## What it stays out of

Tests, documentation, cost, tagging, teardown, scope, style, performance. It notes those under "Out of my lane" and moves on.

## Tools it uses

`git ls-files` for credential-shaped filenames, `gitleaks` for secrets by content including history, `semgrep` with the security-audit and secrets rulesets, and `npm audit` or `pip-audit` for dependencies. If a tool isn't installed it says so and reviews by reading.

```bash
brew install gitleaks semgrep
pip install pip-audit
```

## Seeds

Six. Hardcoded AWS key, SQL from a request parameter, delete endpoint with no auth, static keys in a workflow, IAM wildcard, and one clean file that must PASS. The static-keys seed also checks lane discipline: the workflow has no `permissions:` block, which is infra-reviewer's finding, and this agent must not report it as its own.

The full charter is in [charter.md](charter.md).
