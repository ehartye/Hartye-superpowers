#!/usr/bin/env bash
# Integration Test: team-driven-development workflow
# Actually spawns a crew of persistent named agents and verifies coordination mechanics
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

# Timestamped progress output
progress() {
    echo "[$(date '+%H:%M:%S')] $*"
}

echo "========================================"
echo " Integration Test: team-driven-development"
echo "========================================"
echo ""
echo "This test executes a real plan using persistent named agents and verifies:"
echo "  1. Shared task list is initialized by the lead (TaskCreate)"
echo "  2. Multiple named background agents are spawned via the Agent tool"
echo "  3. Shared task tools are used for coordination"
echo "  4. Agents communicate via SendMessage"
echo "  5. No retired team tools (TeamCreate/TeamDelete/shutdown ritual) are attempted"
echo "  6. Implementation is correct and tests pass"
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
    echo "  bash tests/claude-code/run-skill-tests.sh --integration -t test-team-driven-development-integration.sh"
    echo ""
    exit 1
}
trap sigterm_handler SIGTERM

# Shared task tools must be enabled for headless coordination
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
}
trap cleanup EXIT

# Set up minimal Node.js project
cd "$TEST_PROJECT"

cat > package.json <<'EOF'
{
  "name": "team-test-project",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "test": "node --test"
  }
}
EOF

mkdir -p src test docs/plans

# Create an implementation plan with tasks that benefit from team coordination.
# Task 2 depends on Task 1 (uses the string utilities), which tests that
# teams respect dependencies and coordinate via messaging.
cat > docs/plans/implementation-plan.md <<'EOF'
# String Utilities Implementation Plan

This plan has tasks with a dependency: Task 2 depends on Task 1.
A team approach is useful because agents can coordinate on the shared interface.

## Task 1: Create String Utility Functions

Create basic string utility functions.

**File:** `src/strings.js`

**Requirements:**
- Function `capitalize(str)` - capitalizes the first letter of a string
- Function `reverse(str)` - reverses a string
- Function `truncate(str, maxLen)` - truncates string to maxLen, adds "..." if truncated
- Export all functions
- Handle edge cases: empty string, null/undefined input (return empty string)

**Tests:** Create `test/strings.test.js` with tests for:
- `capitalize("hello")` returns `"Hello"`
- `capitalize("")` returns `""`
- `reverse("hello")` returns `"olleh"`
- `reverse("")` returns `""`
- `truncate("hello world", 5)` returns `"he..."`
- `truncate("hi", 10)` returns `"hi"`

**Verification:** `npm test`

## Task 2: Create Text Formatter (depends on Task 1)

Create a text formatter that uses the string utilities from Task 1.

**File:** `src/formatter.js`

**Requirements:**
- Import `capitalize` and `truncate` from `./strings.js`
- Function `formatTitle(str)` - capitalizes and truncates to 50 chars
- Function `formatPreview(str)` - truncates to 100 chars
- Export all functions
- DO NOT add extra features (no HTML formatting, no markdown, etc.)

**Tests:** Add `test/formatter.test.js` with tests for:
- `formatTitle("hello world")` returns `"Hello world"`
- `formatTitle("a".repeat(60))` returns a 50-char truncated string ending with "..."
- `formatPreview("short")` returns `"short"`
- `formatPreview("a".repeat(120))` returns a 100-char truncated string ending with "..."

**Verification:** `npm test`
EOF

# Initialize git repo
git init --quiet
git config user.email "test@test.com"
git config user.name "Test User"
git add .
git commit -m "Initial commit" --quiet

echo ""
progress "Phase 1/4: Complete. Project at $TEST_PROJECT"
echo ""
echo "  To monitor in real time, run in another terminal:"
echo "    python3 $SCRIPT_DIR/monitor-session.py $TEST_PROJECT"
echo ""
RUN_START_MARKER="$TEST_PROJECT/.run-start"
touch "$RUN_START_MARKER"
progress "Phase 2/4: Starting team execution (this takes 15-30 min)..."
echo ""

# Run Claude with team-driven-development
OUTPUT_FILE="$TEST_PROJECT/claude-output.txt"

# Run from the test project so Claude's project context is correct.
# Use --plugin-dir so skills are discovered from the plugin repo.
PROMPT="Execute the implementation plan at docs/plans/implementation-plan.md using the team-driven-development skill.

IMPORTANT: Follow the team-driven-development skill exactly. I will be verifying that you:
1. Create a shared task entry for each plan task (TaskCreate)
2. Spawn at least 2 named background agents via the Agent tool
3. Use the shared task list for coordination (agents claim tasks via TaskUpdate)
4. Agents communicate via SendMessage
5. Tasks are claimed and completed by different agents
6. When all tasks are complete: verify TaskList, run tests, summarize, and stop

The plan has 2 tasks where Task 2 depends on Task 1.
This tests that your agents coordinate properly.

HEADLESS MODE: After spawning agents, you must poll for completion:
  1. Bash(\"sleep 15\", run_in_background=true) and wait for its notification to stay alive
  2. TaskList to check statuses
  3. If all tasks completed: run tests, then summarize and stop. There is no shutdown ritual — finished agents simply go idle.
  4. Otherwise repeat from step 1

Begin now. Execute the plan with your agent crew."

progress "Running Claude with team-driven-development skill..."
echo "  Output: $OUTPUT_FILE"
echo "================================================================================"
cd "$TEST_PROJECT" && timeout 3500 env -u CLAUDECODE claude -p "$PROMPT" \
    --plugin-dir "$PLUGIN_DIR" \
    --allowed-tools=all \
    --permission-mode bypassPermissions \
    < /dev/null 2>&1 | tee "$OUTPUT_FILE" || {
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
# We run from $TEST_PROJECT, so derive from that.
# Claude Code keys the projects dir by the OS-native path. On Windows
# (Git Bash) translate the POSIX temp path to its Windows form first.
if command -v cygpath >/dev/null 2>&1; then
    NATIVE_PATH=$(cygpath -w "$TEST_PROJECT")
else
    NATIVE_PATH="$TEST_PROJECT"
fi
WORKING_DIR_ESCAPED=$(echo "$NATIVE_PATH" | sed 's/[:\\/.]/-/g')
SESSION_DIR="$HOME/.claude/projects/$WORKING_DIR_ESCAPED"

# Find the most recent session file (created during this test run).
# The { ... || true; } prevents pipefail from aborting if SESSION_DIR doesn't exist.
SESSION_FILE=$({ find "$SESSION_DIR" -maxdepth 1 -name "*.jsonl" -type f -newer "$RUN_START_MARKER" 2>/dev/null || true; } | sort -r | head -1)

# Also collect subagent session files (background agents write here)
SUBAGENT_FILES=$({ find "$SESSION_DIR" -path "*/subagents/*.jsonl" -type f -newer "$RUN_START_MARKER" 2>/dev/null || true; } | sort)
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

progress "Phase 4/4: Running verification tests..."
echo ""
echo "=== Verification Tests ==="
echo ""

# Test 1: Shared task list initialized by the lead
echo "Test 1: Task list initialization..."
if [ -n "$SESSION_FILE" ]; then
    taskcreate_count=$(grep -c '"name":"TaskCreate"' "$SESSION_FILE" 2>/dev/null) || taskcreate_count=0
    if [ "$taskcreate_count" -ge 2 ]; then
        echo "  [PASS] Lead created $taskcreate_count shared task(s) via TaskCreate"
    else
        echo "  [FAIL] Lead created only $taskcreate_count shared task(s) (expected >= 2)"
        FAILED=$((FAILED + 1))
    fi
elif grep -qi "TaskCreate\|shared task\|task list" "$OUTPUT_FILE" 2>/dev/null; then
    echo "  [PASS] Task list initialization referenced in output"
else
    echo "  [FAIL] No evidence of task list initialization"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 2: Multiple agents were spawned
echo "Test 2: Agent spawning..."
if [ -n "$SESSION_FILE" ]; then
    # Check for Agent tool calls in lead session
    agent_count=$(grep -c '"name":"Agent"' "$SESSION_FILE" 2>/dev/null) || agent_count=0
    # Also count actual subagent session files (definitive proof agents ran)
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
    # Fall back to output analysis
    if grep -qi "spawn\|background agent\|implementer\|reviewer" "$OUTPUT_FILE" 2>/dev/null; then
        echo "  [PASS] Agent spawning referenced in output"
    else
        echo "  [FAIL] No evidence of agent spawning"
        FAILED=$((FAILED + 1))
    fi
fi
echo ""

# Test 3: Shared task list was used
echo "Test 3: Shared task list..."
if [ -n "$SESSION_FILE" ]; then
    # Count task tool usage across lead AND all subagent sessions
    task_tool_count=$(cat $ALL_SESSION_FILES 2>/dev/null | grep -c '"name":"TaskCreate"\|"name":"TaskList"\|"name":"TaskUpdate"\|"name":"TaskGet"') || task_tool_count=0
    if [ "$task_tool_count" -ge 2 ]; then
        echo "  [PASS] Task tools used $task_tool_count time(s) across all sessions"
    else
        echo "  [FAIL] Task tools used only $task_tool_count time(s) (expected >= 2)"
        FAILED=$((FAILED + 1))
    fi
else
    if grep -qi "TaskCreate\|TaskList\|TaskUpdate\|shared.*task\|task.*list" "$OUTPUT_FILE" 2>/dev/null; then
        echo "  [PASS] Shared task list referenced in output"
    else
        echo "  [FAIL] No evidence of shared task list usage"
        FAILED=$((FAILED + 1))
    fi
fi
echo ""

# Test 4: Inter-agent communication
echo "Test 4: Inter-agent communication..."
if [ -n "$SESSION_FILE" ]; then
    msg_count=$(cat $ALL_SESSION_FILES 2>/dev/null | grep -c '"name":"SendMessage"') || msg_count=0
    if [ "$msg_count" -ge 1 ]; then
        echo "  [PASS] SendMessage used $msg_count time(s) across all sessions"
    else
        echo "  [FAIL] No SendMessage calls found"
        FAILED=$((FAILED + 1))
    fi
else
    if grep -qi "SendMessage\|send.*message\|messag.*team" "$OUTPUT_FILE" 2>/dev/null; then
        echo "  [PASS] Inter-agent messaging referenced in output"
    else
        echo "  [FAIL] No evidence of inter-agent communication"
        FAILED=$((FAILED + 1))
    fi
fi
echo ""

# Test 5: No retired team tools attempted
# TeamCreate/TeamDelete/shutdown_request no longer exist; any attempt means
# the skill is still teaching the retired flow.
echo "Test 5: No retired team tools attempted..."
if [ -n "$SESSION_FILE" ]; then
    if cat $ALL_SESSION_FILES 2>/dev/null | grep -q '"name":"TeamCreate"\|"name":"TeamDelete"\|shutdown_request'; then
        echo "  [FAIL] Retired team tools/protocol attempted (TeamCreate/TeamDelete/shutdown_request)"
        FAILED=$((FAILED + 1))
    else
        echo "  [PASS] No retired team tools attempted"
    fi
else
    echo "  [WARN] No transcript available to verify"
fi
echo ""

# Test 6: Implementation actually works
echo "Test 6: Implementation verification..."
if [ -f "$TEST_PROJECT/src/strings.js" ]; then
    echo "  [PASS] src/strings.js created"

    if grep -q "export.*function.*capitalize\|export.*capitalize" "$TEST_PROJECT/src/strings.js"; then
        echo "  [PASS] capitalize function exists"
    else
        echo "  [FAIL] capitalize function missing"
        FAILED=$((FAILED + 1))
    fi

    if grep -q "export.*function.*reverse\|export.*reverse" "$TEST_PROJECT/src/strings.js"; then
        echo "  [PASS] reverse function exists"
    else
        echo "  [FAIL] reverse function missing"
        FAILED=$((FAILED + 1))
    fi

    if grep -q "export.*function.*truncate\|export.*truncate" "$TEST_PROJECT/src/strings.js"; then
        echo "  [PASS] truncate function exists"
    else
        echo "  [FAIL] truncate function missing"
        FAILED=$((FAILED + 1))
    fi
else
    echo "  [FAIL] src/strings.js not created"
    FAILED=$((FAILED + 1))
fi

if [ -f "$TEST_PROJECT/src/formatter.js" ]; then
    echo "  [PASS] src/formatter.js created"

    if grep -q "export.*function.*formatTitle\|export.*formatTitle" "$TEST_PROJECT/src/formatter.js"; then
        echo "  [PASS] formatTitle function exists"
    else
        echo "  [FAIL] formatTitle function missing"
        FAILED=$((FAILED + 1))
    fi

    if grep -q "export.*function.*formatPreview\|export.*formatPreview" "$TEST_PROJECT/src/formatter.js"; then
        echo "  [PASS] formatPreview function exists"
    else
        echo "  [FAIL] formatPreview function missing"
        FAILED=$((FAILED + 1))
    fi

    # Verify Task 2 imports from Task 1 (dependency coordination)
    if grep -q "from.*['\"].*strings" "$TEST_PROJECT/src/formatter.js"; then
        echo "  [PASS] formatter.js imports from strings.js (dependency respected)"
    else
        echo "  [WARN] formatter.js does not import from strings.js"
    fi
else
    echo "  [FAIL] src/formatter.js not created"
    FAILED=$((FAILED + 1))
fi

if [ -f "$TEST_PROJECT/test/strings.test.js" ]; then
    echo "  [PASS] test/strings.test.js created"
else
    echo "  [FAIL] test/strings.test.js not created"
    FAILED=$((FAILED + 1))
fi

if [ -f "$TEST_PROJECT/test/formatter.test.js" ]; then
    echo "  [PASS] test/formatter.test.js created"
else
    echo "  [FAIL] test/formatter.test.js not created"
    FAILED=$((FAILED + 1))
fi

# Try running tests
if cd "$TEST_PROJECT" && npm test > test-output.txt 2>&1; then
    echo "  [PASS] All tests pass"
else
    echo "  [FAIL] Tests failed"
    cat test-output.txt | sed 's/^/    /'
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 7: Git commits show work was done
echo "Test 7: Git commit history..."
commit_count=$(git -C "$TEST_PROJECT" log --oneline | wc -l | tr -d ' ')
if [ "$commit_count" -gt 1 ]; then
    echo "  [PASS] Multiple commits created ($commit_count total)"
    git -C "$TEST_PROJECT" log --oneline | sed 's/^/    /'
else
    # Agents may not commit in headless mode — this is OK as long as files exist
    echo "  [WARN] Only $commit_count commit(s) — agents did not git commit (acceptable in headless mode)"
fi
echo ""

# Test 8: No extra features (spec compliance)
echo "Test 8: No extra features added (spec compliance)..."
if grep -q "export.*function.*formatHtml\|export.*function.*formatMarkdown\|export.*function.*formatJson" "$TEST_PROJECT/src/formatter.js" 2>/dev/null; then
    echo "  [WARN] Extra features found in formatter.js (reviewer should have caught this)"
else
    echo "  [PASS] No extra features added"
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
    echo "All verification tests passed!"
    echo ""
    echo "The team-driven-development skill correctly:"
    echo "  - Initialized the shared task list (TaskCreate)"
    echo "  - Spawned multiple named background agents"
    echo "  - Used shared task list for coordination"
    echo "  - Agents communicated via SendMessage"
    echo "  - Respected task dependencies"
    echo "  - Produced working implementation"
    exit 0
else
    echo "STATUS: FAILED"
    echo "Failed $FAILED verification test(s)"
    echo ""
    echo "Output saved to: $OUTPUT_FILE"
    echo ""
    echo "Review the output to see what went wrong."
    exit 1
fi
