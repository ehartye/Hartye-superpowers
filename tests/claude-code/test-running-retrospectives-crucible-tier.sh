#!/usr/bin/env bash
# Behavioral: with crucible "installed" (stub on PATH), the running-retrospectives
# skill should route validation through the crucible tier, not the inline floor.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/test-helpers.sh"

# Stub crucible so detect-engine resolves to the crucible tier without spending tokens.
STUBDIR="$(mktemp -d)"
# Run from a clean test project: inside this repo, Claude can reconstruct the
# Phase 3 subcommands from commit history / script sources, which spuriously
# passes the test even when SKILL.md never mentions the crucible tier.
TEST_PROJECT="$(create_test_project)"
trap 'rm -rf "$STUBDIR"; cleanup_test_project "$TEST_PROJECT"' EXIT
cat > "$STUBDIR/crucible" <<'SH'
#!/usr/bin/env bash
case "$1" in
  --version) echo "crucible 0.6.1";;
  validate)  echo "editable surface OK for all approaches";;
  run)       echo "verdict=keep_baseline winner=baseline"; echo "report: /tmp/r.md";;
  query)     echo "{'r': 'baseline:0/3'}"; echo "{'r': 'green:3/3'}";;
esac
exit 0
SH
chmod +x "$STUBDIR/crucible"
export PATH="$STUBDIR:$PATH"

cd "$TEST_PROJECT"

echo "Test: running-retrospectives routes to crucible tier when installed"

run_claude "I'm running a retrospective using the running-retrospectives skill. A lesson has already recurred across two distinct sessions and is eligible for validation. crucible is installed on this machine. According to the skill's documented procedure, explain exactly how you would validate this lesson before promoting it — name the validation engine you'd select and list the concrete commands you would run, in order." 120

echo "  --- Claude output ---"
echo "$CLAUDE_OUTPUT" | sed 's/^/  | /'
echo "  --- end output ---"

assert_contains "$CLAUDE_OUTPUT" "detect-engine" "skill selects engine via detect-engine"
R1=$?
assert_contains "$CLAUDE_OUTPUT" "crucible" "routes to the crucible tier"
R2=$?
[ "$R1" -eq 0 ] && [ "$R2" -eq 0 ]
