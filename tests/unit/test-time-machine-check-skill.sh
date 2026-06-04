#!/usr/bin/env bash
# Structural lint for the time-machine-check skill (deterministic, no tokens).
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
S="$REPO_ROOT/skills/time-machine-check/SKILL.md"
PASS=0; FAIL=0
has() { if grep -q "$1" "$S"; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: missing '$1'"; fi; }
[ -f "$S" ] || { echo "FAIL: SKILL.md not found"; exit 1; }
grep -qE '^name: time-machine-check' "$S" && PASS=$((PASS+1)) || { FAIL=$((FAIL+1)); echo "FAIL: frontmatter name"; }
has "drift measure"          # references the executable
has "on-track"               # documents the verdict vocabulary
has "diverged"
has "narrative"              # documents the reusable narrative input
has "caller"                 # documents that the caller owns the response
echo "skill lint: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
