#!/usr/bin/env bash
# Run the whole swarm on a change in some repository, from a terminal, with no setup in that
# repository. This is how a pull request gets reviewed before it's opened.
#
#   scripts/review.sh /path/to/repo                 uncommitted changes plus this branch vs main
#   scripts/review.sh /path/to/repo main..HEAD      any git range
#   scripts/review.sh /path/to/repo abc123..def456
#
# What it does: copies the repository (including .git) into a scratch directory, installs every
# built agent from agents/*/dist/claude/ at project scope there, and runs the /swarm command
# with the Claude Code CLI in headless mode. The report goes to stdout. The repository you
# pointed it at is never modified.
#
# The agents get a tool allowlist wide enough to read files, grep, and run git, python, and the
# project's own test command. Without that, a test reviewer can't run tests and a scope reviewer
# can't see the diff, and both will tell you so under Noted instead of pretending.
#
# Bash IS named here, and the command-level allow list below is what scopes it. Leaving Bash out of
# --allowedTools does not narrow the grant, it closes the gate: every shell call is refused before the
# permission rules are ever consulted. That is how five reviewers ran an entire study with their tools
# denied while their reports looked normal. See docs/eval-log.md, 2026-09-18.
#
# Bash is not granted bare. A reviewer's only input is a diff written by whoever wrote the change
# under review, which is untrusted content reaching a command executor. Claude Code's agent
# frontmatter can only name tools, not commands, so the scoping lives here instead: an explicit
# allow list of the commands a reviewer actually runs, and a deny list for the ways git can be
# turned into a general command runner. Override with CLAUDE_FLAGS if you need something else,
# and know what you're widening when you do.
#
# Exit code: 0 for PASS, 1 for WARN, 2 for BLOCK, 3 if no verdict could be read from the output.
set -euo pipefail
cd "$(dirname "$0")/.."

repo="${1:?usage: scripts/review.sh /path/to/repo [git-range]}"
range="${2:-}"
: "${CLAUDE_FLAGS:=--allowedTools Read,Grep,Glob,Bash,Task --max-turns 60}"

[ -d "$repo/.git" ] || { echo "not a git repository: $repo" >&2; exit 3; }
command -v claude >/dev/null || { echo "claude CLI not on PATH" >&2; exit 3; }
[ -f agents/swarm/dist/claude/swarm.md ] || { echo "run scripts/build.sh first" >&2; exit 3; }

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
# Copy the working tree and history so the agents can diff, blame, and run tests exactly as
# they would in the real checkout.
tar -C "$repo" -cf - --exclude=node_modules --exclude=.venv --exclude=__pycache__ . | tar -C "$work" -xf -

mkdir -p "$work/.claude/agents" "$work/.claude/commands"

# Command-level permissions for this run. `deny` wins over `allow` in Claude Code, so the two
# git escapes below stay shut no matter what an agent asks for. Anything not listed is simply
# not permitted, and in headless mode an unpermitted call is refused rather than prompted, so a
# reviewer that needs something it doesn't have says so under Noted. That is the intended
# behavior: a review that quietly did less is worse than one that says what it couldn't do.
cat > "$work/.claude/settings.json" <<'JSON'
{
  "permissions": {
    "deny": [
      "Bash(git -c:*)",
      "Bash(git --exec-path:*)",
      "Bash(git config:*)",
      "Bash(git push:*)",
      "Bash(git commit:*)"
    ],
    "allow": [
      "Bash(git diff:*)",
      "Bash(git status:*)",
      "Bash(git log:*)",
      "Bash(git show:*)",
      "Bash(git ls-files:*)",
      "Bash(git rev-parse:*)",
      "Bash(git blame:*)",
      "Bash(pytest:*)",
      "Bash(ruff:*)",
      "Bash(npm test:*)",
      "Bash(npm run test:*)",
      "Bash(npm audit:*)",
      "Bash(pnpm test:*)",
      "Bash(pnpm run test:*)",
      "Bash(pnpm audit:*)",
      "Bash(pnpm exec:*)",
      "Bash(pnpm install:*)",
      "Bash(npx:*)",
      "Bash(tsc:*)",
      "Bash(eslint:*)",
      "Bash(node:*)",
      "Bash(pip-audit:*)",
      "Bash(gitleaks:*)",
      "Bash(semgrep:*)",
      "Bash(actionlint:*)",
      "Bash(checkov:*)",
      "Bash(tflint:*)",
      "Bash(hadolint:*)",
      "Bash(shellcheck:*)",
      "Bash(./scripts/check.sh)"
    ]
  }
}
JSON
for d in agents/*/; do
  d="${d%/}"; n="$(basename "$d")"; f="$d/dist/claude/$n.md"
  [ -f "$f" ] || continue
  if grep -q '"commands"' "$d/.claude-plugin/plugin.json" 2>/dev/null; then
    cp "$f" "$work/.claude/commands/$n.md"
  else
    cp "$f" "$work/.claude/agents/$n.md"
  fi
done

if [ -n "$range" ]; then
  what="the change is: git diff $range. Read the diff, then read every changed file in full."
else
  what="the change is: everything uncommitted plus every commit on this branch that is not on main."
fi
prompt="/swarm $what Ignore the .claude/ folder; it's review tooling, not part of the change. Read engagement/ and docs/decisions/ first if they exist."

started=$(date +%s)
report="$( cd "$work" && claude -p "$prompt" --output-format text ${CLAUDE_FLAGS} 2>/dev/null || true )"
elapsed=$(( $(date +%s) - started ))

printf '%s\n' "$report"
printf '\n<!-- swarm run: %ds, agents from %s -->\n' "$elapsed" "$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"

verdict="$(printf '%s' "$report" | grep -oE '\*\*Verdict:\*\*[[:space:]]*(BLOCK|WARN|PASS)' | head -1 | grep -oE 'BLOCK|WARN|PASS' || true)"
case "$verdict" in
  PASS) exit 0 ;;
  WARN) exit 1 ;;
  BLOCK) exit 2 ;;
  *) echo "no verdict found in the swarm's output" >&2; exit 3 ;;
esac
