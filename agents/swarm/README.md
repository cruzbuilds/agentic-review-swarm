# swarm

Runs every configured review agent on the same change at the same time, then arbitrates their reports into one verdict, one findings list, and one assurance record. It reviews nothing itself. It coordinates, and then it reasons over what the reviewers wrote and nothing else.

On Claude Code this is the `/swarm` command rather than a subagent, because subagents can't spawn subagents there. On Kiro it's an agent that lists the others as available.

## Install

Claude Code: `/plugin install swarm@agentic-review-swarm` (install the reviewers too, or it has nothing to run)
Kiro: `scripts/install-kiro.sh --all` from the repo root

Then: `/swarm` on Claude Code, or `/swarm main..HEAD` for a specific range. From a terminal with no setup in the target repository, use `scripts/review.sh /path/to/repo` from this repo.

## The roster

security-reviewer, docs-reviewer, infra-reviewer, test-reviewer, scope-reviewer, systems-reviewer. All six run in parallel and independently; none sees another's output.

## How it arbitrates

Kept from the first version:

- Any single BLOCK is a BLOCK. The arbiter cannot downgrade or remove a reviewer's Blocking finding
- Findings are grouped by file, and when two reviewers report the same defect it is one entry with both names
- Tools that ran, failed, or were unavailable stay visible, per reviewer
- Nothing a reviewer wrote is dropped, and the arbiter adds no findings of its own

New in V2 ([ADR 0006](../../docs/decisions/0006-systems-review-beside-the-specialists.md)):

- **Unowned findings are findings.** A `-> no owner` line from any reviewer, or a handoff the named owner did not report, becomes an entry with the reviewer's evidence, an arbiter-assigned severity and confidence, and the basis for both. It can affect the verdict. It can be blocking only when the reviewer supplied a reproduction or deterministic sequence *and* stated a meaningful consequence for a user, data, money or access, in its own words
- **Disagreements are a section.** Two reviewers on the same defect at different severities are both recorded; the higher stands; the human decides
- **Provenance survives merging.** Independent discovery by two reviewers is counted, not flattened. A specialist's local citation that is a step in the systems reviewer's chain is kept inside the merged finding, tagged
- **Incomplete coverage caps the verdict.** A configured reviewer that is not installed, failed, timed out, or said the change was too big makes PASS impossible. The verdict line says which and why
- **Two documents.** Findings, for the developer. Assurance record, for whoever signs off: coverage, per-reviewer status and coverage statement, tools, corroboration count, handoffs, unowned findings by severity, every arbiter action, and how the verdict was derived

The arbiter may not open a source file or run a tool. Its two judgments, severity and confidence of unowned findings and the reconciliation of disagreements, are bounded by the reports.

## Testing it

`seeds/three-lanes` runs the reviewers live and checks the merge. The other seeds under `seeds/` are deterministic: saved reviewer reports plus a prompt that says to arbitrate them, so the arbiter's rules can be tested without the reviewers' variance. `scripts/run-seeds.sh swarm` runs all of them.
