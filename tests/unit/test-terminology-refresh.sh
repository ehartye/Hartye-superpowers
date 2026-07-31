#!/usr/bin/env bash
# Structural lint: retired agent-teams-era terminology must not reappear on
# live surfaces (skills/, READMEs, docs/testing.md). Deterministic, no tokens.
# Historical docs under docs/ are exempt — they carry a historical banner.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PASS=0; FAIL=0

# --- 1. Banned tokens on live surfaces ---
# TeamCreate/TeamDelete: tools no longer exist. shutdown_request/team_name:
# retired protocol. EXPERIMENTAL_AGENT_TEAMS/Opus 4.6: retired gating.
BANNED='TeamCreate|TeamDelete|shutdown_request|team_name|EXPERIMENTAL_AGENT_TEAMS|Opus 4\.6'
LIVE_SURFACES=("$REPO_ROOT/skills" "$REPO_ROOT/README.md" "$REPO_ROOT/README_normie.md" "$REPO_ROOT/docs/testing.md")

hits="$(grep -rEn "$BANNED" "${LIVE_SURFACES[@]}" 2>/dev/null || true)"
if [ -n "$hits" ]; then
  FAIL=$((FAIL+1))
  echo "FAIL: retired agent-teams terminology found on live surfaces:"
  echo "$hits" | sed 's/^/  /'
else
  PASS=$((PASS+1))
fi

# --- 2. Renamed prompt templates exist; old names are gone ---
must_exist() { if [ -f "$1" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: missing $1"; fi; }
must_not_exist() { if [ -f "$1" ]; then FAIL=$((FAIL+1)); echo "FAIL: stale file still present: $1"; else PASS=$((PASS+1)); fi; }

SP="$REPO_ROOT/skills/shared-perspectives"
must_exist     "$SP/perspective-persistent-agent-prompt.md"
must_exist     "$SP/synthesis-persistent-agent-prompt.md"
must_not_exist "$SP/perspective-teammate-prompt.md"
must_not_exist "$SP/synthesis-teammate-prompt.md"

# No dangling references to the old template filenames anywhere live
dangling="$(grep -rn "teammate-prompt" "$REPO_ROOT/skills" 2>/dev/null || true)"
if [ -n "$dangling" ]; then
  FAIL=$((FAIL+1))
  echo "FAIL: dangling references to renamed teammate prompt templates:"
  echo "$dangling" | sed 's/^/  /'
else
  PASS=$((PASS+1))
fi

# --- 3. Current-primitive vocabulary present where the retired flow lived ---
has() { if grep -qF "$2" "$1"; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $(basename "$(dirname "$1")")/$(basename "$1") missing '$2'"; fi; }

TDD_SKILL="$REPO_ROOT/skills/team-driven-development/SKILL.md"
has "$TDD_SKILL" "run_in_background"            # background agents, not team spawns
has "$TDD_SKILL" "SendMessage"                  # continuation/messaging survives
has "$TDD_SKILL" "TaskStop"                     # runaway handling replaces TeamDelete
has "$TDD_SKILL" "no shutdown ritual"           # teardown ceremony removed

PR="$REPO_ROOT/skills/perspective-review/SKILL.md"
PRS="$REPO_ROOT/skills/perspective-research/SKILL.md"
has "$PR"  "Path B: Persistent-Agent"
has "$PRS" "Path B: Persistent-Agent"
has "$PR"  "persistent-agent-prompt.md"
has "$PRS" "persistent-agent-prompt.md"

# --- 3b. Headless coordination protocol (verified against run transcripts) ---
# Task board is lead-only; peers address by agent ID via a lead-broadcast roster.
has "$TDD_SKILL" "Coordination Mechanics"
has "$TDD_SKILL" "roster"
has "$TDD_SKILL" "lead-only"
IMPL="$REPO_ROOT/skills/team-driven-development/implementer-prompt.md"
SPECR="$REPO_ROOT/skills/team-driven-development/spec-reviewer-prompt.md"
QUALR="$REPO_ROOT/skills/team-driven-development/code-quality-reviewer-prompt.md"
has "$IMPL"  "Address peers by their agent ID"
has "$IMPL"  "do not attempt TaskUpdate yourself"
has "$SPECR" "names do not resolve between agents"
has "$QUALR" "names do not resolve between agents"

# --- 4. Historical docs carry the banner ---
for doc in "docs/analysis-agent-teams.md" "docs/comparison-agent-teams-vs-subagents.md" "docs/IMPLEMENTATION-SUMMARY.md"; do
  has "$REPO_ROOT/$doc" "Historical document"
done

echo "terminology refresh lint: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
