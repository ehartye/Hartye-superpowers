---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace via the native worktree tool, with a manual git fallback
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches simultaneously without switching.

**Core principle:** Detect existing isolation first; then use the native worktree tool; fall back to manual git only when native is unavailable.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Step 0: Detect Existing Isolation

Before creating anything, check whether you are already in an isolated workspace.

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside a git submodule. If `git rev-parse --show-superproject-working-tree` returns a path, you're in a submodule, not a worktree — treat it as a normal repo.

- **If `GIT_DIR != GIT_COMMON` (and not a submodule):** you're already in a linked worktree (including a native `.claude/worktrees/` one). Do NOT create another. Skip to "Run Project Setup".
- **If `GIT_DIR == GIT_COMMON`:** you're in a normal checkout. Proceed to create a worktree (with consent — see below).

If no worktree preference is already declared by the user or CLAUDE.md, ask for consent before creating one:
> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

## Create the Worktree

### Native tool (preferred)

Use the harness's native worktree tool, `EnterWorktree`. It creates the worktree under `.claude/worktrees/` on a new branch and switches the session into it — directory placement, branch creation, and cleanup are handled for you.

```
EnterWorktree(name: "<feature-name>")
```

Base ref is governed by the `worktree.baseRef` setting: `fresh` (default) branches from `origin/<default-branch>`; `head` branches from the current local HEAD. Mention this to the user if they need a specific base.

Native creation requires worktree use to be explicitly requested (by the user or CLAUDE.md/memory). The execution skills that call this skill satisfy that by announcing the worktree step.

### Manual git fallback (only if no native tool)

If `EnterWorktree` is unavailable, create one manually:

```bash
project=$(basename "$(git rev-parse --show-toplevel)")
git worktree add ".worktrees/$BRANCH_NAME" -b "$BRANCH_NAME"
cd ".worktrees/$BRANCH_NAME"
```

Verify `.worktrees/` is git-ignored before creating (`git check-ignore -q .worktrees` — if not ignored, add it to `.gitignore` and commit first).

**Sandbox fallback:** if `git worktree add` fails with a permission/sandbox denial, tell the user the sandbox blocked worktree creation and work in the current directory instead; then run setup and baseline tests in place.

### Run Project Setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

### Verify Clean Baseline

Run tests to ensure worktree starts clean:

```bash
# Examples - use project-appropriate command
npm test
cargo test
pytest
go test ./...
```

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### Report Location

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| Already in a worktree | Use it (skip creation) |
| Native tool available | `EnterWorktree` |
| No native tool | Manual `git worktree` under `.worktrees/` (verify ignored) |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |

## Common Mistakes

### Creating a nested worktree

- **Problem:** Didn't run Step 0 detection, so you create a worktree while already inside one — worktree-in-worktree
- **Fix:** Always run Step 0 detection first; if already in a linked worktree, skip creation

### Skipping ignore verification (manual fallback)

- **Problem:** Worktree contents get tracked, pollute git status
- **Fix:** For the manual fallback, always run `git check-ignore` before creating

### Proceeding with failing tests

- **Problem:** Can't distinguish new bugs from pre-existing issues
- **Fix:** Report failures, get explicit permission to proceed

### Hardcoding setup commands

- **Problem:** Breaks on projects using different tools
- **Fix:** Auto-detect from project files (package.json, etc.)

## Example Workflow

```
You: I'm using the using-git-worktrees skill to set up an isolated workspace.

[Step 0: git-dir == git-common-dir → normal checkout, not nested]
[Native tool available → EnterWorktree(name: "auth")]
[Session switched into .claude/worktrees/auth]
[Run npm install]
[Run npm test - 47 passing]

Worktree ready at .claude/worktrees/auth
Tests passing (47 tests, 0 failures)
Ready to implement auth feature
```

## Hard Rules

These guardrails prevent subtle contamination of the repo or hidden baseline failures:

- Run Step 0 detection before creating — never nest worktrees
- Prefer the native tool; use manual git only as a fallback
- For the manual fallback, verify `.worktrees/` is ignored before creating
- Don't skip baseline test verification
- Don't proceed with failing tests without asking

**Always:**
- Run Step 0 detection first; prefer native tool
- Auto-detect and run project setup
- Verify a clean test baseline before handing off

## Integration

**Called by:**
- **subagent-driven-development** - REQUIRED before executing any tasks
- **team-driven-development** - REQUIRED before executing any tasks
- **executing-plans** - REQUIRED before executing any tasks
- Any skill needing isolated workspace

**Pairs with:**
- **finishing-a-development-branch** - REQUIRED for cleanup after work complete
