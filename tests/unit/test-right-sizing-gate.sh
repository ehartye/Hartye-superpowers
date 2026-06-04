#!/usr/bin/env bash
# Structural lint for the reversibility-centered right-sizing gate (deterministic, no tokens).
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
US="$REPO_ROOT/skills/using-superpowers/SKILL.md"
PASS=0; FAIL=0
has()   { if grep -qF "$2" "$1"; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $(basename "$1") missing '$2'"; fi; }
hasnt() { if grep -qF "$2" "$1"; then FAIL=$((FAIL+1)); echo "FAIL: $(basename "$1") still contains '$2'"; else PASS=$((PASS+1)); fi; }

# using-superpowers: the reversibility gate
has   "$US" "rollback fully undo it"          # the one reversibility question
has   "$US" "schema migrations"               # irreversible list
has   "$US" "external side effects"           # irreversible list
has   "$US" "Obviously large"                 # the obvious-size override
has   "$US" "test-driven-development"          # discipline spine retained
hasnt "$US" "requirements are ambiguous or underspecified"  # v2 ambiguity-trigger removed

echo "right-sizing gate lint: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
