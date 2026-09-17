#!/usr/bin/env bash
# One command that tells you whether the repo is healthy.
# CI runs exactly this, so "it passes locally" and "it passes in CI" mean the same thing.
set -euo pipefail

fail=0
step() { printf '\n\033[1m── %s\033[0m\n' "$1"; }
warn() { printf '\033[33m!  %s\033[0m\n' "$1"; }
ok()   { printf '\033[32m✓  %s\033[0m\n' "$1"; }

step "Secret scan"
# Catches the mistake that is expensive and silent: a credential file that got
# tracked before .gitignore covered it. .gitignore is not retroactive.
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  printf '\033[31m✗  Not a git repository — cannot verify what is tracked.\033[0m\n'
  exit 1
fi
# Seeds deliberately contain credential-shaped files. They are the test cases.
tracked_secrets=$(git ls-files | grep -v '/seeds/' | grep -Ei '(^|/)\.env($|\.)|\.pem$|\.p12$|\.pfx$|(^|/)id_rsa|\.tfstate$' | grep -v '\.example$' || true)
if [ -n "$tracked_secrets" ]; then
  printf '\033[31m✗  Tracked files that look like secrets:\033[0m\n%s\n' "$tracked_secrets"
  echo "   Remove with: git rm --cached <file>"
  fail=1
else
  ok "no credential-shaped files tracked"
fi

step "Built agent files are current"
if ./scripts/build.sh --check >/dev/null 2>&1; then
  ok "dist/ matches charters and shared/"
else
  printf '\033[31m✗  dist/ is stale. Run scripts/build.sh and commit.\033[0m\n'; fail=1
fi

step "Every reviewer can run git"
# A reviewer with no git reviews the working tree instead of the change, and that failure is
# silent: the report reads exactly like a real one. AS-6 is where it was found.
#
# The first version of this check grepped the whole adapter file for "bash" or "shell", which
# matched the word inside a description line and passed an adapter that granted nothing. So it
# parses the declaration instead: the `tools:` value for a Claude adapter, the `allowedTools`
# entries for a Kiro one, where the capability is only usable if git is actually permitted.
blind=""
reviewers=0
for d in agents/*-reviewer/; do
  [ -d "$d" ] || continue
  n="$(basename "${d%/}")"
  reviewers=$((reviewers+1))
  found=0
  for a in "$d"adapters/*.yaml; do
    [ -f "$a" ] || continue
    found=$((found+1))
    case "$(basename "$a")" in
      claude.yaml)
        # one line: `tools: Read, Grep, Glob, Bash`
        grant="$(sed -n 's/^tools:[[:space:]]*//p' "$a")"
        printf '%s' "$grant" | grep -q '\bBash\b' || blind="$blind  $n ($(basename "$a")): tools has no Bash, so no git\n"
        ;;
      *)
        # a list: `allowedTools:` followed by `  - "@shell/git ..."`
        grant="$(sed -n '/^allowedTools:/,/^[^[:space:]-]/p' "$a")"
        printf '%s' "$grant" | grep -q '@shell/git' || blind="$blind  $n ($(basename "$a")): allowedTools permits no git\n"
        ;;
    esac
  done
  [ "$found" -gt 0 ] || blind="$blind  $n: no adapter files at all\n"
done
if [ "$reviewers" -eq 0 ]; then
  printf '\033[31m✗  No agents/*-reviewer/ found. This check is scoped by that name; rename or fix it.\033[0m\n'
  fail=1
elif [ -n "$blind" ]; then
  printf '\033[31m✗  Reviewers that cannot run git, so cannot read the diff:\033[0m\n'
  printf '%b' "$blind"
  fail=1
else
  ok "all $reviewers reviewers are permitted to run git"
fi

step "Every seed has an expected.md"
missing=$(for d in agents/*/seeds/*/; do [ -f "$d/expected.md" ] || echo "$d"; done)
if [ -n "$missing" ]; then printf '\033[31m✗  seeds with no expected.md:\033[0m\n%s\n' "$missing"; fail=1
else ok "all seeds have expectations"; fi

step "Project checks"
if [ -f package.json ]; then
  npm run --silent lint  2>/dev/null || warn "no lint script"
  npm run --silent test  2>/dev/null || { echo "tests failed or missing"; fail=1; }
elif [ -f pyproject.toml ] || [ -f requirements.txt ]; then
  command -v ruff   >/dev/null && ruff check . || warn "ruff not installed"
  command -v pytest >/dev/null && pytest -q     || { echo "tests failed or missing"; fail=1; }
else
  ok "no language runtime here; the checks above are the project checks"
fi

echo
[ "$fail" -eq 0 ] && ok "check.sh passed" || printf '\033[31m✗  check.sh failed\033[0m\n'
exit "$fail"
