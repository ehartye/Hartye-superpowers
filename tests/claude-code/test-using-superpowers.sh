#!/usr/bin/env bash
# Test: using-superpowers skill (bootstrap)
# Verifies that the bootstrap skill loads correctly and its core rules are followed
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

FAILURES=0

# Helper to show Claude's response for debugging
show_output() {
    echo "  --- Claude output ---"
    echo "$CLAUDE_OUTPUT" | sed 's/^/  | /'
    echo "  --- end output ---"
}

# Helper to run assertion without exiting on failure
check() {
    if ! "$@"; then
        FAILURES=$((FAILURES + 1))
    fi
}

echo "=== Test: using-superpowers skill (bootstrap) ==="
echo ""

# Test 1: Skill is recognized and describes the skill system
echo "Test 1: Skill loading and recognition..."

run_claude "What is the using-superpowers skill and what does it set up?" 30
show_output

check assert_contains "$CLAUDE_OUTPUT" "using-superpowers\|skills system\|skill system\|superpowers" "Skill is recognized"
check assert_contains "$CLAUDE_OUTPUT" "skill\|Skill" "Mentions the skills system"

echo ""

# Test 2: Skill teaches how to discover and invoke skills
echo "Test 2: Skill discovery mechanism..."

run_claude "According to the using-superpowers skill, how should Claude find and use skills from the h-superpowers plugin?" 30
show_output

check assert_contains "$CLAUDE_OUTPUT" "Skill.* tool\|skill.* tool\|h-superpowers:\|plugin\|invoke.*skill\|Skill.*invoke" "Mentions skill invocation mechanism"

echo ""

# Test 3: Skill establishes that skills should auto-trigger
echo "Test 3: Auto-triggering behaviour..."

run_claude "According to the using-superpowers skill, when should Claude use skills — only when explicitly asked, or automatically?" 30
show_output

check assert_contains "$CLAUDE_OUTPUT" "automatic\|proactively\|trigger\|before.*asked\|without.*asking\|relevant" "Skills auto-trigger"
check assert_not_contains "$CLAUDE_OUTPUT" "^only when explicitly\|should only.*when asked\|skills are only" "Not only when explicitly asked"

echo ""

# Test 4: Skill references the brainstorming prerequisite for creative work
echo "Test 4: Brainstorming as prerequisite..."

run_claude "According to the using-superpowers skill, what skill should be used before starting to build a new feature?" 30
show_output

check assert_contains "$CLAUDE_OUTPUT" "brainstorm\|Brainstorm\|brainstorming\|Brainstorming" "References brainstorming"

echo ""

# Test 5: Skill establishes that skills are mandatory, not optional
echo "Test 5: Skills are mandatory..."

run_claude "Are the workflows in the h-superpowers skills library optional suggestions or mandatory? What does using-superpowers say?" 30
show_output

check assert_contains "$CLAUDE_OUTPUT" "mandatory\|required\|REQUIRED\|not.*optional\|must" "Skills are mandatory"

echo ""

# Summary
if [ $FAILURES -gt 0 ]; then
    echo "=== $FAILURES assertion(s) failed ==="
    exit 1
else
    echo "=== All using-superpowers tests passed ==="
fi
