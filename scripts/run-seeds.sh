#!/usr/bin/env bash
# Runs every agent against its seeded-defect tests and checks the verdicts.
#
# This is the eval. It's how you find out whether an agent is real or just
# confident. Each seed is a small folder with one planted problem (or none, for
# the clean seed) and an expected.md that says what the correct verdict is and
# which words the report must (or must not) contain.
#
# It runs the agent through the Claude Code CLI in non-interactive mode. That
# means you need `claude` installed and signed in on this machine. It will cost
# tokens: roughly one short review per seed.
#
# Usage:
#   scripts/run-seeds.sh                    all agents, all seeds
#   scripts/run-seeds.sh security-reviewer  one agent
#   scripts/run-seeds.sh security-reviewer clean   one seed
#
# Exit code is the number of failed seeds, so 0 means everything passed.
#
# Failed seeds always save the agent's report under .seed-reports/. Set
# SEED_KEEP_ALL=1 to save passing reports too, which is useful for reading what
# a good review looks like or for writing up results.
set -uo pipefail
cd "$(dirname "$0")/.."

command -v claude >/dev/null || { echo "claude CLI not found. Install: npm install -g @anthropic-ai/claude-code"; exit 2; }

# Headless runs need tool permissions granted up front or the agent stalls on a
# prompt nobody can answer. Override with CLAUDE_FLAGS if you want something else.
: "${CLAUDE_FLAGS:=--allowedTools Read,Grep,Glob,Bash,Task,Write --max-turns 40}"

only_agent="${1:-}"
only_seed="${2:-}"
passed=0; failed=0; results=()

# Pull a top-level scalar out of expected.md, e.g. "verdict: BLOCK" -> BLOCK
yaml_scalar() { grep -E "^$2:" "$1" | head -1 | sed -E "s/^$2:[[:space:]]*//" | tr -d '"'; }
# Pull a top-level list out of expected.md, one item per line
yaml_list() { awk -v key="$2" '
  $0 ~ "^"key":" {on=1; next}
  on && /^[[:space:]]+-[[:space:]]/ { sub(/^[[:space:]]+-[[:space:]]*/, ""); gsub(/^"|"$/, ""); print; next }
  on && !/^[[:space:]]/ {on=0}
' "$1"; }

for agent_dir in agents/*/; do
  agent_dir="${agent_dir%/}"; agent="$(basename "$agent_dir")"
  [ -n "$only_agent" ] && [ "$agent" != "$only_agent" ] && continue
  dist="$agent_dir/dist/claude/$agent.md"
  [ -f "$dist" ] || { echo "skip $agent: run scripts/build.sh first"; continue; }
  [ -d "$agent_dir/seeds" ] || continue

  for seed_dir in "$agent_dir"/seeds/*/; do
    seed_dir="${seed_dir%/}"; seed="$(basename "$seed_dir")"
    [ -n "$only_seed" ] && [ "$seed" != "$only_seed" ] && continue
    expected="$seed_dir/expected.md"
    [ -f "$expected" ] || { echo "skip $agent/$seed: no expected.md"; continue; }

    # Stage the seed in a scratch dir with the agent installed at project scope,
    # so the CLI discovers it the same way a real project would.
    work="$(mktemp -d)"
    cp -R "$seed_dir"/. "$work"/
    rm -f "$work/expected.md" "$work/prompt.md"
    # Bytecode caches are not part of any fixture. They appear when someone imports a seed's
    # modules in place to check it, and once copied here they get committed into the scratch repo
    # and every reviewer reports them (systems-reviewer Run 001: six of six). Same class of harness
    # leak as Experiment 001's settings file. Strip them before the seed becomes a repository.
    find "$work" -type d -name __pycache__ -prune -exec rm -rf {} +
    mkdir -p "$work/.claude/agents" "$work/.claude/commands"
    for d in agents/*/; do
      d="${d%/}"; n="$(basename "$d")"; f="$d/dist/claude/$n.md"
      [ -f "$f" ] || continue
      if grep -q '"commands"' "$d/.claude-plugin/plugin.json" 2>/dev/null; then
        cp "$f" "$work/.claude/commands/$n.md"
      else
        cp "$f" "$work/.claude/agents/$n.md"
      fi
    done
    ( cd "$work" && git init -q && git add -A && git -c user.name=seed -c user.email=seed@example.invalid commit -qm "seed" )

    if [ -f "$seed_dir/prompt.md" ]; then
      prompt="$(cat "$seed_dir/prompt.md")"
    else
      prompt="Use the $agent subagent to review every file in this directory as if it were a proposed change. Ignore the .claude/ folder; it's tooling, not part of the change. Report using the agent's required output format and nothing else."
    fi
    report="$( cd "$work" && claude -p "$prompt" --output-format text ${CLAUDE_FLAGS:-} 2>/dev/null )"
    # An agent that writes a document (engagement-guide) puts the substance in
    # the file, not the final message. Read back anything under engagement/ so
    # the checks see what was actually produced.
    if [ -d "$work/engagement" ]; then
      report="$report"$'\n'"$(cat "$work"/engagement/*.md 2>/dev/null)"
    fi

    want="$(yaml_scalar "$expected" verdict)"
    got="$(printf '%s' "$report" | grep -oE '\*\*Verdict:\*\*[[:space:]]*(BLOCK|WARN|PASS)' | head -1 | grep -oE 'BLOCK|WARN|PASS' || echo 'NONE')"

    ok=1; why=()
    if [ "$want" = "NONE" ]; then
      : # no verdict expected (interviewer seeds); only the mention checks apply
    # PASS expected: accept PASS, and accept WARN as a soft pass (agent had a real reason)
    elif [ "$want" = "PASS" ]; then
      [ "$got" = "PASS" ] || [ "$got" = "WARN" ] || { ok=0; why+=("verdict $got, wanted PASS"); }
    else
      [ "$got" = "$want" ] || { ok=0; why+=("verdict $got, wanted $want"); }
    fi
    while IFS= read -r term; do
      [ -z "$term" ] && continue
      printf '%s' "$report" | grep -qiF -- "$term" || { ok=0; why+=("missing: $term"); }
    done < <(yaml_list "$expected" must_mention)
    while IFS= read -r term; do
      [ -z "$term" ] && continue
      # only look in the Blocking/Should fix sections, "out of my lane" mentions are fine
      # headers like "### Blocking" would false-match "BLOCK"; only scan finding lines
      printf '%s' "$report" | awk '/^### Noted/{exit} !/^#/ {print}' | grep -qiF -- "$term" && { ok=0; why+=("must not mention: $term"); }
    done < <(yaml_list "$expected" must_not_mention)
    # Every agent name in the report must be a real agent. An "Out of my lane" handoff
    # to an agent that doesn't exist is a finding that silently goes nowhere.
    while IFS= read -r name; do
      [ -z "$name" ] && continue
      [ -d "agents/$name" ] || { ok=0; why+=("routed to unknown agent: $name"); }
    done < <(printf '%s' "$report" | grep -oE '\b[a-z]+-(reviewer|guide)\b' | sort -u)

    if [ $ok -eq 1 ]; then passed=$((passed+1)); results+=("PASS  $agent/$seed  ($got)")
      [ "${SEED_KEEP_ALL:-}" = "1" ] && { mkdir -p .seed-reports; printf '%s\n' "$report" > ".seed-reports/$agent--$seed.md"; }
    else failed=$((failed+1)); results+=("FAIL  $agent/$seed  ($got)  ${why[*]}")
      mkdir -p .seed-reports; printf '%s\n' "$report" > ".seed-reports/$agent--$seed.md"
    fi
    rm -rf "$work"
  done
done

echo
printf '%s\n' "${results[@]}"
echo
echo "passed: $passed  failed: $failed"
[ $failed -gt 0 ] && echo "failed reports saved under .seed-reports/ so you can read what the agent actually said."
exit $failed
