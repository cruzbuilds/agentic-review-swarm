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

step "Every reviewer can read a diff"
# A reviewer with no shell cannot run git, and a reviewer that cannot run git
# reviews the working tree instead of the change. That failure is silent: the
# report looks exactly like a real one. AS-6 is where this was found.
blind=""
for d in agents/*-reviewer/; do
  n="$(basename "${d%/}")"
  for a in "$d"adapters/*.yaml; do
    [ -f "$a" ] || continue
    grep -qiE '(^| )bash|shell' "$a" || blind="$blind$n ($(basename "$a"))\n"
  done
done
if [ -n "$blind" ]; then
  printf '\033[31m✗  Reviewers with no shell, so no git, so no diff:\033[0m\n'
  printf "$blind"
  fail=1
else
  ok "every reviewer adapter grants a shell"
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
