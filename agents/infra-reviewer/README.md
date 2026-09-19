# infra-reviewer

Reads infrastructure code, deployment scripts, CI workflows, and container definitions for three questions: will this run, what does it cost, and can it be removed. Reports only. Never edits.

It shares one concern with security-reviewer, static cloud credentials in CI, and the two use the same words for it on purpose so it's obvious when they agree. Everything else about whether infrastructure is attackable belongs to security-reviewer. This agent cares whether it runs and what it costs.

## Install

Claude Code: `/plugin install infra-reviewer@agentic-review-swarm`
Kiro: `scripts/install-kiro.sh infra-reviewer` from the repo root

## What it blocks on

- Resource identifiers hardcoded in source: account IDs, bucket names, ARNs, endpoints
- Static cloud credentials in CI where OIDC is available
- Deploy steps pinned to a mutable action version, like `@main` or `@v3`, when the step touches credentials or deploys
- Infrastructure with no teardown. If it can be created it has to be destroyable, and the command has to exist
- A workflow with no `permissions:` block on a job that deploys, publishes, holds secrets, or assumes a role. A job that only runs tests gets "should fix" instead
- A resource nobody could identify later: no tags, no name, no owner

## What it warns on

Log groups that never expire, billing modes that don't match the usage pattern, container images pinned to `latest`, unversioned installs in a Dockerfile, deploys to production with no environment gate, secrets passed as build args.

## What it stays out of

Application logic, whether the infrastructure is attackable, tests, and whether the README explains the infrastructure. Whether teardown exists is this agent's call; whether it's documented well is docs-reviewer's.

## Tools it uses

`actionlint` for workflows, `checkov` or `tflint` for Terraform, `hadolint` for Dockerfiles. If a tool isn't installed it says so under Noted and reviews by reading.

## Seeds

Six. Hardcoded account ID, no permissions block, no tags, a resource with no teardown, an unpinned deploy action, and one clean setup that must PASS. The clean seed was rejected twice while being written, both times for real gaps (no remote state backend, a referenced tfvars file that didn't exist). A clean seed is harder to write than a broken one.

The full charter is in [charter.md](charter.md).
