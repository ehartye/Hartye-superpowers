#!/usr/bin/env bash
# Integration Test: per-agent worktree workflow
# Two agents work in separate worktrees on modules that both modify a shared
# barrel file (src/index.js), then the lead merges branches and cleans up.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

# Timestamped progress output
progress() {
    echo "[$(date '+%H:%M:%S')] $*"
}

echo "========================================"
echo " Integration Test: per-agent worktrees"
echo "========================================"
echo ""
echo "This test exercises the worktree-based team workflow and verifies:"
echo "  1. TeamCreate is used to initialize a team"
echo "  2. Multiple agents are spawned as teammates"
echo "  3. Per-agent worktrees are created (git worktree add)"
echo "  4. Math module: src/math.js + tests"
echo "  5. Text module: src/text.js + tests"
echo "  6. Barrel file: src/index.js re-exports both modules"
echo "  7. npm test passes after merge"
echo "  8. Merge commits or both modules present on main"
echo "  9. Worktree cleanup (remove/prune)"
echo " 10. Proper shutdown of team members"
echo ""
echo "WARNING: This test may take 35-60 minutes to complete."
echo "WARNING: Each spawned agent runs as a full Claude session (sequential)."
echo "WARNING: This test costs 2-4x more than the subagent integration test."
echo "WARNING: Run from a STANDALONE TERMINAL (not from within Claude Code)."
echo "  Running inside a Claude Code session causes SIGTERM to kill this test"
echo "  when you switch conversations. Use a separate terminal window instead."
echo ""

# Detect if running inside a Claude Code session and warn loudly
if [ -n "${CLAUDECODE:-}" ]; then
    echo "DANGER: CLAUDECODE env var is set — you appear to be running inside"
    echo "  a Claude Code session. This test WILL be killed when the session ends."
    echo "  Open a separate terminal and run this test from there."
    echo ""
fi

# Trap SIGTERM to give a clear message instead of silent death
sigterm_handler() {
    echo ""
    echo "=========================================="
    echo " KILLED BY SIGTERM"
    echo "=========================================="
    echo ""
    echo "The test was terminated by SIGTERM. Common causes:"
    echo "  1. Test runner timeout expired (runner uses 60 min limit)"
    echo "  2. Parent process (e.g. a Claude Code session) exited"
    echo ""
    echo "If this was a timeout, the team agents took longer than 60 minutes."
    echo "If killed by a session exit, run from a standalone terminal instead:"
    echo "  bash tests/claude-code/run-skill-tests.sh --integration -t test-team-worktree-integration.sh"
    echo ""
    exit 1
}
trap sigterm_handler SIGTERM

# Agent teams require these env vars
if [ "${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:-}" != "1" ]; then
    echo "NOTE: Setting CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 for this test"
    export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
fi

if [ "${CLAUDE_CODE_ENABLE_TASKS:-}" != "true" ]; then
    echo "NOTE: Setting CLAUDE_CODE_ENABLE_TASKS=true for this test"
    export CLAUDE_CODE_ENABLE_TASKS=true
fi

# Kill any stale claude integration test processes from previous runs.
STALE=$(pgrep -f "claude -p.*Hartye-superpowers" 2>/dev/null || true)
if [ -n "$STALE" ]; then
    echo "Cleaning up $(echo "$STALE" | wc -w | tr -d ' ') stale claude process(es) from previous runs..."
    kill $STALE 2>/dev/null || true
    sleep 3
fi

progress "Phase 1/4: Creating test project..."
TEST_PROJECT=$(create_test_project)
echo "Test project: $TEST_PROJECT"

# Trap to cleanup
cleanup() {
    cleanup_test_project "$TEST_PROJECT"
    # Clean up any team artifacts created during the test
    rm -rf "$HOME/.claude/teams/test-worktree-integration" 2>/dev/null || true
    rm -rf "$HOME/.claude/tasks/test-worktree-integration" 2>/dev/null || true
}
trap cleanup EXIT

# Set up minimal Node.js project
cd "$TEST_PROJECT"

cat > package.json <<'EOF'
{
  "name": "worktree-test-project",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "test": "node --test"
  }
}
EOF

mkdir -p src test docs/plans

# Create barrel file with placeholder so agents modify (not create) it
cat > src/index.js <<'EOF'
// Barrel file — re-export all modules here
EOF

# Create implementation plan with workspace strategy specifying per-agent worktrees
cat > docs/plans/implementation-plan.md <<'PLAN_EOF'
# Utility Library Implementation Plan

This plan has two independent tasks that both modify a shared barrel file
(src/index.js). Per-agent worktrees are appropriate because the tasks are
independent and each modifies src/index.js, creating a contention point.

## Workspace Strategy

**Mode:** Per-agent worktrees
**Justification:** Both tasks modify src/index.js (the barrel file). Per-agent
worktrees let each implementer work in isolation without merge conflicts during
development. The lead merges branches after tasks complete.

**Feasibility check:** No ports, no shared state, pure library code — worktrees
are safe.

## Task 1: Create Math Utility Module (implementer-1)

Create basic math utility functions.

**File:** `src/math.js`

**Requirements:**
- Function `add(a, b)` — returns a + b
- Function `subtract(a, b)` — returns a - b
- Function `multiply(a, b)` — returns a * b
- Export all functions

**Barrel file update:** Add `export * from './math.js';` to `src/index.js`

**Tests:** Create `test/math.test.js` with tests for:
- `add(2, 3)` returns `5`
- `add(-1, 1)` returns `0`
- `subtract(5, 3)` returns `2`
- `multiply(4, 3)` returns `12`
- `multiply(0, 5)` returns `0`

**Verification:** `npm test`

## Task 2: Create Text Utility Module (implementer-2)

Create basic text utility functions.

**File:** `src/text.js`

**Requirements:**
- Function `capitalize(str)` — capitalizes the first letter, lowercases the rest
- Function `lowercase(str)` — converts entire string to lowercase
- Function `trim(str)` — removes leading and trailing whitespace
- Export all functions
- Handle edge cases: empty string (return empty string)

**Barrel file update:** Add `export * from './text.js';` to `src/index.js`

**Tests:** Create `test/text.test.js` with tests for:
- `capitalize("hello")` returns `"Hello"`
- `capitalize("")` returns `""`
- `lowercase("HELLO")` returns `"hello"`
- `trim("  hello  ")` returns `"hello"`
- `trim("")` returns `""`

**Verification:** `npm test`
PLAN_EOF

# Initialize git repo
git init --quiet
git config user.email "test@test.com"
git config user.name "Test User"
git add .
git commit -m "Initial commit" --quiet

echo ""
progress "Phase 1/4: Complete. Project at $TEST_PROJECT"
echo ""
progress "Phase 2/4: Starting team execution (this takes 15-30 min)..."
echo ""

# Run Claude with team-driven-development
OUTPUT_FILE="$TEST_PROJECT/claude-output.txt"

# IMPORTANT: Run from superpowers directory so local dev skills are available
# (see upstream commit 0aba33b — skills are discovered from the working directory)
PROMPT="Change to directory $TEST_PROJECT and then execute the implementation plan at docs/plans/implementation-plan.md using the team-driven-development skill.

Use team name 'test-worktree-integration'.

IMPORTANT: The plan specifies per-agent worktrees. Follow the team-driven-development skill exactly. I will be verifying that you:
1. Create a team using TeamCreate
2. Create worktrees for each implementer (git worktree add)
3. Spawn at least 2 implementer teammates, each working in their own worktree
4. Each implementer creates their module, tests, and updates the barrel file
5. After tasks complete, merge branches into main and run npm test
6. Clean up worktrees and shut down team members

Begin now. Execute the plan with a team using per-agent worktrees."

progress "Running Claude with team-driven-development skill (worktree mode)..."
echo "  Output: $OUTPUT_FILE"
echo "================================================================================"
cd "$SCRIPT_DIR/../.." && timeout 3500 env -u CLAUDECODE claude -p "$PROMPT" \
    --allowed-tools=all \
    --add-dir "$TEST_PROJECT" \
    --permission-mode bypassPermissions \
    2>&1 | tee "$OUTPUT_FILE" || {
    echo ""
    echo "================================================================================"
    echo "EXECUTION FAILED (exit code: $?)"
}
echo "================================================================================"
progress "Phase 2/4: Claude execution complete."
echo ""
progress "Phase 3/4: Analyzing session transcript..."
echo ""

# Find the session transcript
# We run from $SCRIPT_DIR/../.. (the plugin repo root), so derive from that.
PLUGIN_DIR_RESOLVED=$(cd "$SCRIPT_DIR/../.." && pwd -P)
WORKING_DIR_ESCAPED=$(echo "$PLUGIN_DIR_RESOLVED" | sed 's/[\/.]/-/g')
SESSION_DIR="$HOME/.claude/projects/$WORKING_DIR_ESCAPED"

# Find the most recent session file (created during this test run).
# The { ... || true; } prevents pipefail from aborting if SESSION_DIR doesn't exist.
SESSION_FILE=$({ find "$SESSION_DIR" -maxdepth 1 -name "*.jsonl" -type f -mmin -60 2>/dev/null || true; } | sort -r | head -1)

# Also collect subagent session files (background agents write here)
SUBAGENT_FILES=$({ find "$SESSION_DIR" -path "*/subagents/*.jsonl" -type f -mmin -60 2>/dev/null || true; } | sort)
if [ -n "$SUBAGENT_FILES" ]; then
    SUBAGENT_COUNT=$(echo "$SUBAGENT_FILES" | wc -l | tr -d ' ')
    echo "Found $SUBAGENT_COUNT subagent session file(s)"
fi

if [ -z "$SESSION_FILE" ]; then
    echo "WARNING: Could not find session transcript file"
    echo "Looked in: $SESSION_DIR"
    echo "Will verify based on output and file artifacts only."
    SESSION_FILE=""
fi

if [ -n "$SESSION_FILE" ]; then
    echo "Analyzing session transcript: $(basename "$SESSION_FILE")"
fi
echo ""

# Combine all session files for searching
ALL_SESSION_FILES="$SESSION_FILE"
if [ -n "$SUBAGENT_FILES" ]; then
    ALL_SESSION_FILES="$SESSION_FILE $SUBAGENT_FILES"
fi

# Verification tests
FAILED=0
WARNED=0

progress "Phase 4/4: Running verification tests..."
echo ""
echo "=== Verification Tests ==="
echo ""

# Test 1: Team was created
echo "Test 1: Team creation..."
if [ -n "$SESSION_FILE" ] && grep -q '"name":"TeamCreate"' "$SESSION_FILE" 2>/dev/null; then
    echo "  [PASS] TeamCreate tool was called"
elif grep -qi "TeamCreate\|team.*creat\|creat.*team" "$OUTPUT_FILE" 2>/dev/null; then
    echo "  [PASS] Team creation referenced in output"
else
    echo "  [FAIL] No evidence of team creation"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 2: Multiple agents were spawned
echo "Test 2: Agent spawning..."
if [ -n "$SESSION_FILE" ]; then
    agent_count=$(grep -c '"name":"Agent"' "$SESSION_FILE" 2>/dev/null) || agent_count=0
    subagent_file_count=$(echo "$SUBAGENT_FILES" | grep -c . 2>/dev/null) || subagent_file_count=0
    if [ "$subagent_file_count" -ge 2 ]; then
        echo "  [PASS] $subagent_file_count subagent session files created"
    elif [ "$agent_count" -ge 2 ]; then
        echo "  [PASS] $agent_count Agent tool calls in lead session"
    else
        echo "  [FAIL] Only $agent_count agent(s) spawned, $subagent_file_count subagent files (expected >= 2)"
        FAILED=$((FAILED + 1))
    fi
else
    if grep -qi "spawn\|teammate\|implementer" "$OUTPUT_FILE" 2>/dev/null; then
        echo "  [PASS] Agent spawning referenced in output"
    else
        echo "  [FAIL] No evidence of agent spawning"
        FAILED=$((FAILED + 1))
    fi
fi
echo ""

# Test 3: Worktree creation
echo "Test 3: Worktree creation..."
if [ -n "$SESSION_FILE" ]; then
    # Check for git worktree add in transcripts
    wt_count=$(cat $ALL_SESSION_FILES 2>/dev/null | grep -c 'git worktree add\|EnterWorktree\|worktree.*add') || wt_count=0
    if [ "$wt_count" -ge 2 ]; then
        echo "  [PASS] Worktree creation found $wt_count time(s) in transcripts"
    elif [ "$wt_count" -ge 1 ]; then
        echo "  [WARN] Only $wt_count worktree creation found (expected >= 2)"
        WARNED=$((WARNED + 1))
    else
        # Fallback: check output file
        wt_output=$(grep -c 'worktree\|work.tree' "$OUTPUT_FILE" 2>/dev/null) || wt_output=0
        if [ "$wt_output" -ge 1 ]; then
            echo "  [WARN] Worktree mentioned in output but no git worktree add found in transcripts"
            WARNED=$((WARNED + 1))
        else
            echo "  [FAIL] No evidence of worktree creation"
            FAILED=$((FAILED + 1))
        fi
    fi
else
    if grep -qi "worktree" "$OUTPUT_FILE" 2>/dev/null; then
        echo "  [WARN] Worktree mentioned in output but no transcript to verify"
        WARNED=$((WARNED + 1))
    else
        echo "  [FAIL] No evidence of worktree creation"
        FAILED=$((FAILED + 1))
    fi
fi
echo ""

# Test 4: Math module
echo "Test 4: Math module..."
if [ -f "$TEST_PROJECT/src/math.js" ]; then
    echo "  [PASS] src/math.js created"

    if grep -q "export.*function.*add\|export.*add" "$TEST_PROJECT/src/math.js"; then
        echo "  [PASS] add function exists"
    else
        echo "  [FAIL] add function missing"
        FAILED=$((FAILED + 1))
    fi

    if grep -q "export.*function.*subtract\|export.*subtract" "$TEST_PROJECT/src/math.js"; then
        echo "  [PASS] subtract function exists"
    else
        echo "  [FAIL] subtract function missing"
        FAILED=$((FAILED + 1))
    fi

    if grep -q "export.*function.*multiply\|export.*multiply" "$TEST_PROJECT/src/math.js"; then
        echo "  [PASS] multiply function exists"
    else
        echo "  [FAIL] multiply function missing"
        FAILED=$((FAILED + 1))
    fi

    if [ -f "$TEST_PROJECT/test/math.test.js" ]; then
        echo "  [PASS] test/math.test.js created"
    else
        echo "  [FAIL] test/math.test.js not created"
        FAILED=$((FAILED + 1))
    fi
else
    echo "  [FAIL] src/math.js not created"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 5: Text module
echo "Test 5: Text module..."
if [ -f "$TEST_PROJECT/src/text.js" ]; then
    echo "  [PASS] src/text.js created"

    if grep -q "export.*function.*capitalize\|export.*capitalize" "$TEST_PROJECT/src/text.js"; then
        echo "  [PASS] capitalize function exists"
    else
        echo "  [FAIL] capitalize function missing"
        FAILED=$((FAILED + 1))
    fi

    if grep -q "export.*function.*lowercase\|export.*lowercase" "$TEST_PROJECT/src/text.js"; then
        echo "  [PASS] lowercase function exists"
    else
        echo "  [FAIL] lowercase function missing"
        FAILED=$((FAILED + 1))
    fi

    if grep -q "export.*function.*trim\|export.*trim" "$TEST_PROJECT/src/text.js"; then
        echo "  [PASS] trim function exists"
    else
        echo "  [FAIL] trim function missing"
        FAILED=$((FAILED + 1))
    fi

    if [ -f "$TEST_PROJECT/test/text.test.js" ]; then
        echo "  [PASS] test/text.test.js created"
    else
        echo "  [FAIL] test/text.test.js not created"
        FAILED=$((FAILED + 1))
    fi
else
    echo "  [FAIL] src/text.js not created"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 6: Barrel file re-exports
echo "Test 6: Barrel file (src/index.js)..."
if [ -f "$TEST_PROJECT/src/index.js" ]; then
    has_math=false
    has_text=false

    if grep -q "from.*['\"].*math\|require.*math\|export.*math" "$TEST_PROJECT/src/index.js"; then
        echo "  [PASS] index.js re-exports math module"
        has_math=true
    else
        echo "  [WARN] index.js does not re-export math module"
    fi

    if grep -q "from.*['\"].*text\|require.*text\|export.*text" "$TEST_PROJECT/src/index.js"; then
        echo "  [PASS] index.js re-exports text module"
        has_text=true
    else
        echo "  [WARN] index.js does not re-export text module"
    fi

    if [ "$has_math" = false ] && [ "$has_text" = false ]; then
        echo "  [FAIL] index.js re-exports neither module"
        FAILED=$((FAILED + 1))
    elif [ "$has_math" = false ] || [ "$has_text" = false ]; then
        echo "  [WARN] index.js only re-exports one module (expected both)"
        WARNED=$((WARNED + 1))
    fi
else
    echo "  [FAIL] src/index.js not found"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 7: Tests pass
echo "Test 7: npm test passes..."
if cd "$TEST_PROJECT" && npm test > test-output.txt 2>&1; then
    echo "  [PASS] All tests pass"
else
    echo "  [FAIL] Tests failed"
    cat test-output.txt | sed 's/^/    /'
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 8: Merge evidence
echo "Test 8: Merge evidence..."
merge_found=false
if git -C "$TEST_PROJECT" log --oneline | grep -qi "merge"; then
    echo "  [PASS] Merge commits found in git log"
    git -C "$TEST_PROJECT" log --oneline | head -5 | sed 's/^/    /'
    merge_found=true
fi

# Fallback: even without merge commits, if both modules are on main, the merge happened
if [ "$merge_found" = false ]; then
    if [ -f "$TEST_PROJECT/src/math.js" ] && [ -f "$TEST_PROJECT/src/text.js" ]; then
        echo "  [PASS] Both modules present on main (merge achieved even without --no-ff commits)"
        merge_found=true
    else
        echo "  [FAIL] No merge evidence — neither merge commits nor both modules on main"
        FAILED=$((FAILED + 1))
    fi
fi
echo ""

# Test 9: Worktree cleanup
echo "Test 9: Worktree cleanup..."
if [ -n "$SESSION_FILE" ]; then
    cleanup_evidence=$(cat $ALL_SESSION_FILES 2>/dev/null | grep -c 'git worktree remove\|git worktree prune\|worktree.*remove\|worktree.*prune') || cleanup_evidence=0
    if [ "$cleanup_evidence" -ge 1 ]; then
        echo "  [PASS] Worktree cleanup commands found in transcripts"
    else
        echo "  [WARN] No worktree cleanup commands found in transcripts"
        WARNED=$((WARNED + 1))
    fi
fi

# Check remaining worktrees (main is always listed, so expect <= 1)
remaining_wt=$(git -C "$TEST_PROJECT" worktree list 2>/dev/null | wc -l | tr -d ' ')
if [ "$remaining_wt" -le 1 ]; then
    echo "  [PASS] $remaining_wt worktree(s) remaining (clean)"
else
    echo "  [WARN] $remaining_wt worktree(s) remaining (expected <= 1)"
    git -C "$TEST_PROJECT" worktree list 2>/dev/null | sed 's/^/    /'
    WARNED=$((WARNED + 1))
fi
echo ""

# Test 10: Shutdown
echo "Test 10: Team shutdown..."
if [ -n "$SESSION_FILE" ]; then
    if cat $ALL_SESSION_FILES 2>/dev/null | grep -q '"type":"shutdown_request"\|"type":"shutdown_response"'; then
        echo "  [PASS] Graceful shutdown protocol used"
    elif cat $ALL_SESSION_FILES 2>/dev/null | grep -q '"name":"TeamDelete"'; then
        echo "  [PASS] TeamDelete called for cleanup"
    else
        echo "  [WARN] No explicit shutdown protocol found (agents may have exited naturally)"
        WARNED=$((WARNED + 1))
    fi
else
    if grep -qi "shutdown\|TeamDelete\|shut.*down" "$OUTPUT_FILE" 2>/dev/null; then
        echo "  [PASS] Shutdown referenced in output"
    else
        echo "  [WARN] No explicit shutdown evidence (agents may have exited naturally)"
        WARNED=$((WARNED + 1))
    fi
fi
echo ""

# Token Usage Analysis (if script exists)
if [ -f "$SCRIPT_DIR/analyze-token-usage.py" ] && [ -n "$SESSION_FILE" ]; then
    echo "========================================="
    echo " Token Usage Analysis"
    echo "========================================="
    echo ""
    echo "Lead session:"
    python3 "$SCRIPT_DIR/analyze-token-usage.py" "$SESSION_FILE" 2>/dev/null || echo "  (analysis script not available)"
    if [ -n "$SUBAGENT_FILES" ]; then
        echo ""
        echo "Subagent sessions:"
        for sf in $SUBAGENT_FILES; do
            echo "  --- $(basename "$sf") ---"
            python3 "$SCRIPT_DIR/analyze-token-usage.py" "$sf" 2>/dev/null || echo "  (analysis failed)"
        done
    fi
    echo ""
fi

# Summary
echo "========================================"
echo " Test Summary"
echo "========================================"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "STATUS: PASSED"
    if [ $WARNED -gt 0 ]; then
        echo "All critical tests passed ($WARNED warning(s))"
    else
        echo "All verification tests passed!"
    fi
    echo ""
    echo "The per-agent worktree workflow correctly:"
    echo "  - Created a team with TeamCreate"
    echo "  - Spawned multiple agent teammates"
    echo "  - Used per-agent worktrees for isolation"
    echo "  - Created math module (add, subtract, multiply)"
    echo "  - Created text module (capitalize, lowercase, trim)"
    echo "  - Merged branches into main"
    echo "  - All tests pass"
    exit 0
else
    echo "STATUS: FAILED"
    echo "Failed $FAILED verification test(s), $WARNED warning(s)"
    echo ""
    echo "Output saved to: $OUTPUT_FILE"
    echo ""
    echo "Review the output to see what went wrong."
    exit 1
fi
