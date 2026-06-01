---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass** (applying `verification-before-completion` discipline — evidence, not assumption):

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Determine Base Branch

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 3: Present Options

**Environment note:** Determine workspace state first:
```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```
If `GIT_DIR != GIT_COMMON` and HEAD is detached (externally-managed workspace), present the reduced 3-option menu (no local merge):

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)
3. Discard this work

Which option?
```
Otherwise present the standard 4 options below.

Present exactly these 4 options:

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Don't add explanation** - keep options concise.

### Step 4: Execute Choice

#### Option 1: Merge Locally

```bash
# Operate in the MAIN repo, not inside the feature worktree
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git checkout <base-branch>
git pull
git merge <feature-branch>
<test command>     # verify tests on merged result BEFORE removing anything
# Then tear down the worktree (Step 5): native ExitWorktree(remove), or manual worktree remove
# Only AFTER the worktree is gone:
git branch -d <feature-branch>
```

Then: Cleanup worktree (Step 5), then delete the branch as shown above.

#### Option 2: Push and Create PR

**Note:** Keep the worktree after creating the PR (the branch is still active).

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

Then: Keep worktree (branch is still active for PR updates).

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.**

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed, switch to the base branch, tear down the worktree FIRST, then force-delete the branch:
```bash
git checkout <base-branch>
# Tear down the worktree (Step 5): native ExitWorktree(remove, discard_changes), or manual worktree remove
# Only AFTER the worktree is gone:
git branch -D <feature-branch>
```

Then: Cleanup worktree (Step 5) before the `git branch -D` above.

### Step 5: Cleanup Worktree

**Native teardown (preferred).** If the worktree was created with `EnterWorktree` this session, use `ExitWorktree` — it returns the session to the original directory and removes or keeps the worktree safely (it only ever touches worktrees this session created):

- Option 1 (merge locally): after merge + verify in the main repo, `ExitWorktree(action: "remove")`.
- Option 4 (discard): after typed confirmation, `ExitWorktree(action: "remove", discard_changes: true)`.
- Options 2 (PR) and 3 (keep): `ExitWorktree(action: "keep")` (or leave in place) — branch stays active.

If `ExitWorktree` reports no active worktree session (e.g., the worktree was created manually or in a different session), fall back to the manual cleanup below.

**Manual fallback (non-native worktrees):**

**For Options 1 and 4:**

Check if in worktree:
```bash
git worktree list | grep $(git branch --show-current)
```

If yes — **change directory to the main repo BEFORE removing the worktree:**
```bash
# CRITICAL: cd to main repo first. If your shell CWD is inside the worktree,
# removing it destroys the CWD and every subsequent Bash call will fail.
cd "$(git worktree list | head -1 | awk '{print $1}')"

# Now safe to remove
git worktree remove <worktree-path>
```

**For Option 3:** Keep worktree.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | ✓ | - | - | ✓ |
| 2. Create PR | - | ✓ | ✓ | - |
| 3. Keep as-is | - | - | ✓ | - |
| 4. Discard | - | - | - | ✓ (force) |

For Options 1 and 4, remove the worktree **before** deleting the branch (a branch backing an active worktree can't be cleanly deleted).

## Common Mistakes

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Open-ended questions**
- **Problem:** "What should I do next?" → ambiguous
- **Fix:** Present exactly 4 structured options

**Removing worktree while CWD is inside it**
- **Problem:** Shell CWD becomes invalid; every subsequent Bash call fails
- **Fix:** Always `cd` to main repo root BEFORE `git worktree remove`

**Automatic worktree cleanup**
- **Problem:** Remove worktree when might need it (Option 2, 3)
- **Fix:** Only cleanup for Options 1 and 4

**No confirmation for discard**
- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation

## Hard Rules

These guardrails exist because the stakes — someone else's code, history, or work — don't forgive mistakes:

- Don't proceed with failing tests
- Don't merge without re-verifying tests on the merged result
- Don't delete work without typed confirmation
- Don't force-push without an explicit request

**Always:**
- Verify tests before offering options
- Present exactly 4 options
- Get typed confirmation for Option 4
- Clean up worktree only for Options 1 & 4

## Integration

**Called by:**
- **subagent-driven-development** (Step 7) - After all tasks complete
- **team-driven-development** (Step 6) - After lead consolidates team results
- **executing-plans** (Step 5) - After all batches complete

**Pairs with:**
- **using-git-worktrees** - Cleans up worktree created by that skill
