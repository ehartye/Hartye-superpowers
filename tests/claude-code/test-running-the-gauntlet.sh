#!/usr/bin/env bash
# Test: running-the-gauntlet skill
# Verifies the skill is loaded and covers the bar contract, blindness rule,
# stop conditions, and the brainstorming fork rubric.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

FAILURES=0

show_output() {
    echo "  --- Claude output ---"
    echo "$CLAUDE_OUTPUT" | sed 's/^/  | /'
    echo "  --- end output ---"
}

check() {
    if ! "$@"; then
        FAILURES=$((FAILURES + 1))
    fi
}

echo "=== Test: running-the-gauntlet skill ==="
echo ""

# Test 1: Skill recognition and core concept
echo "Test 1: Skill loading and core concept..."

run_claude "What is the running-the-gauntlet skill? Describe it briefly." 90
show_output

check assert_contains "$CLAUDE_OUTPUT" "running-the-gauntlet\|[Gg]auntlet" "Skill is recognized"
check assert_contains "$CLAUDE_OUTPUT" "bar" "Mentions the bar"
check assert_contains "$CLAUDE_OUTPUT" "critic" "Mentions the critic"
check assert_contains "$CLAUDE_OUTPUT" "builder\|build" "Mentions builders"

echo ""

# Test 2: The bar contract
echo "Test 2: Bar contract invariants..."

run_claude "In the running-the-gauntlet skill, what four invariants must the bar satisfy before the loop can start?" 90
show_output

check assert_contains "$CLAUDE_OUTPUT" "[Mm]aterialize" "Materialized invariant"
check assert_contains "$CLAUDE_OUTPUT" "[Pp]erceiv" "Perceivable invariant"
check assert_contains "$CLAUDE_OUTPUT" "[Rr]atif" "Ratified invariant"
check assert_contains "$CLAUDE_OUTPUT" "[Ff]rozen\|[Ff]reeze" "Frozen invariant"

echo ""

# Test 3: The blindness rule
echo "Test 3: Blindness rule..."

run_claude "In running-the-gauntlet, what is the critic allowed to see, and what must it never see? Why?" 90
show_output

check assert_contains "$CLAUDE_OUTPUT" "never.*\(narration\|summary\|summaries\|report\|builder\)\|builder.*\(narration\|summary\|report\)" "Critic never sees builder narration"
check assert_contains "$CLAUDE_OUTPUT" "screenshot\|run.*test\|perceive\|actual.*output\|launch" "Critic perceives actual output"

echo ""

# Test 4: Stop conditions
echo "Test 4: Stop conditions..."

run_claude "What are the stop conditions for a piece in the running-the-gauntlet loop? What happens when the loop stalls?" 90
show_output

check assert_contains "$CLAUDE_OUTPUT" "PASS\|pass" "PASS condition"
check assert_contains "$CLAUDE_OUTPUT" "stall\|2.*round\|two.*round\|no.*improvement" "Stall rule"
check assert_contains "$CLAUDE_OUTPUT" "budget" "Budget cap"
check assert_contains "$CLAUDE_OUTPUT" "escalate\|human" "Stall escalates to human"

echo ""

# Test 5: Fork rubric (brainstorming integration)
echo "Test 5: When gauntlet vs writing-plans..."

run_claude "After brainstorming produces an approved design, how do I decide between the writing-plans skill and the running-the-gauntlet skill?" 90
show_output

check assert_contains "$CLAUDE_OUTPUT" "enumerate\|enumerable\|task list\|list.*tasks" "Enumerable tasks -> plans"
check assert_contains "$CLAUDE_OUTPUT" "recognize\|see it\|looking\|quality\|polish" "Recognized done -> gauntlet"

echo ""

# Test 6: Pass semantics for aspirational bars
echo "Test 6: Exemplar pass semantics..."

run_claude "In running-the-gauntlet, my reference exemplar is far above what's achievable (say, a AAA game as the bar for a browser game). How does the skill handle a bar the work can never fully reach?" 120
show_output

check assert_contains "$CLAUDE_OUTPUT" "aspirational\|threshold\|score\|anchored\|rubric" "Aspirational scoring semantics"
check assert_contains "$CLAUDE_OUTPUT" "10\|reference.*=\|ceiling\|ratif" "Reference-anchored threshold"

echo ""

# Summary
echo "========================================"
if [ "$FAILURES" -eq 0 ]; then
    echo "✓ All running-the-gauntlet tests passed"
    exit 0
else
    echo "✗ $FAILURES check(s) failed"
    exit 1
fi
