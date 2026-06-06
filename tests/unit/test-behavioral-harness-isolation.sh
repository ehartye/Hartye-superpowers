#!/usr/bin/env bash
# Structural lint: the Claude Code behavioral harness must load EXACTLY the
# dev-tree plugin, not a duplicate of the globally-installed one.
#
# Why this exists: headless `claude -p` auto-loads globally-enabled plugins.
# The behavioral tests add `--plugin-dir <repo>` to load the dev tree — but if
# the global `h-superpowers@hartye-plugins` is still enabled, BOTH load and every
# skill is registered twice (nondeterministic, flaky). The harness must disable
# the global registry copy (via `--settings`) so only the dev copy remains.
# `--plugin-dir` is session-scoped and bypasses enabledPlugins, so it still loads.
#
# This is a deterministic grep lint (no tokens, no `claude` calls).
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HELPERS="$REPO_ROOT/tests/claude-code/test-helpers.sh"
PASS=0; FAIL=0
has()   { if grep -qE "$2" "$1"; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $(basename "$1") missing /$2/"; fi; }
hasnt() { if grep -qF "$2" "$1"; then FAIL=$((FAIL+1)); echo "FAIL: $(basename "$1") still contains '$2'"; else PASS=$((PASS+1)); fi; }

# run_claude must pass --settings disabling the installed registry plugin so the
# global copy doesn't load alongside the --plugin-dir dev copy.
has   "$HELPERS" '\-\-settings'                                  # the disable is wired in
has   "$HELPERS" '"h-superpowers@hartye-plugins"[[:space:]]*:[[:space:]]*false'  # CORRECT key, disabled
has   "$HELPERS" '\-\-plugin-dir'                                # dev tree still loaded

# The pre-existing create_test_project disable used the WRONG plugin key
# ("hartye-superpowers@..." — the plugin is named "h-superpowers"), so it never
# actually disabled anything. That wrong key must be gone.
hasnt "$HELPERS" "hartye-superpowers@hartye-plugins"

echo "behavioral-harness isolation lint: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
