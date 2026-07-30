#!/usr/bin/env bash
# Structural lint for the running-the-gauntlet skill (deterministic, no tokens).
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
G="$REPO_ROOT/skills/running-the-gauntlet"
PASS=0; FAIL=0
has()   { if grep -qF "$2" "$1"; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $(basename "$1") missing '$2'"; fi; }
must_exist() { if [ -f "$1" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: missing $1"; fi; }

# --- All five skill files exist ---
must_exist "$G/SKILL.md"
must_exist "$G/bar-types.md"
must_exist "$G/bar-definition.md"
must_exist "$G/builder-prompt.md"
must_exist "$G/critic-prompt.md"

# --- SKILL.md: frontmatter + the load-bearing rules ---
has "$G/SKILL.md" "name: running-the-gauntlet"
has "$G/SKILL.md" "Materialized"                   # bar contract invariant 1
has "$G/SKILL.md" "Perceivable"                    # invariant 2
has "$G/SKILL.md" "Ratified"                       # invariant 3
has "$G/SKILL.md" "Frozen"                         # invariant 4
has "$G/SKILL.md" "blindness rule"                 # critic never sees builder narration
has "$G/SKILL.md" "2 consecutive rounds"           # stall rule
has "$G/SKILL.md" "deviations.md"                  # deviation protocol
has "$G/SKILL.md" "ledger"                         # evidence ledger
has "$G/SKILL.md" "Can you enumerate the tasks"    # fork rubric
has "$G/SKILL.md" "verification-before-completion" # spine hookup

# --- bar-types.md: taxonomy + pass semantics ---
has "$G/bar-types.md" "Executable"
has "$G/bar-types.md" "Exemplar"
has "$G/bar-types.md" "UX mockup"
has "$G/bar-types.md" "Practices"
has "$G/bar-types.md" "parity"
has "$G/bar-types.md" "aspirational"
has "$G/bar-types.md" "grounding: latent"          # latent fallback must be marked
has "$G/bar-types.md" "Stills judge stills"        # motion caveat

# --- bar-definition.md: ordering + completeness machinery ---
has "$G/bar-definition.md" "Stack grounding first"
has "$G/bar-definition.md" "state-matrix"
has "$G/bar-definition.md" "Ratify and freeze"
has "$G/bar-definition.md" "Minimal worked example"

# --- Prompts: blindness enforced on both sides ---
has "$G/builder-prompt.md" "the critic will never see it"
has "$G/critic-prompt.md"  "never trust a summary"
has "$G/critic-prompt.md"  "BIGGEST REMAINING GAP"

# --- brainstorming fork is wired ---
BR="$REPO_ROOT/skills/brainstorming/SKILL.md"
has "$BR" "running-the-gauntlet"
has "$BR" "Tasks enumerable?"

# --- README arsenal entry ---
has "$REPO_ROOT/README.md" "running-the-gauntlet"

echo "running-the-gauntlet lint: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
