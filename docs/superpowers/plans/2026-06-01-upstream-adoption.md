# Upstream Adoption Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use h-superpowers:subagent-driven-development, h-superpowers:team-driven-development, or h-superpowers:executing-plans to implement this plan (ask user which approach).

**Goal:** Adopt the agreed subset of upstream (obra/superpowers) skill-content improvements into the fork while preserving deliberate fork divergences, per `docs/superpowers/specs/2026-06-01-upstream-adoption-design.md`.

**Architecture:** Pure Markdown/skill-content edits across ~10 skill files plus two agent/prompt files. No application code. Verification is structural (grep for required content + absence of stale content) per task; the behavioral/integration test suite is a final manual gate because those tests invoke real Claude sessions and are slow/billed.

**Tech Stack:** Markdown (SKILL.md, prompt templates, agent definitions); bash + grep for verification; the fork's existing test harness under `tests/`.

**Conventions for this plan:**
- "Steps use checkbox (`- [ ]`) syntax for tracking" (adopting item 3b in this very plan).
- Each content step shows the exact text to insert and the exact anchor it goes near.
- Verification steps use `rg` (ripgrep) content assertions. Expected output is stated.
- Commit after each task. Stage only the files named in the task (never `git add .`).

**Scope Check:** This is a single coherent adoption pass over the skills subsystem. The tasks are independent edits to distinct files (a few share a file — noted), so it remains one plan rather than per-subsystem plans. Each task produces a self-contained, committable change.

**File map (what each task touches):**
- Task 1 → `skills/subagent-driven-development/SKILL.md`, `skills/requesting-code-review/SKILL.md`, `skills/team-driven-development/SKILL.md`
- Task 2 → `agents/code-reviewer.md`
- Task 3 → `skills/writing-plans/SKILL.md`
- Task 4 → `skills/brainstorming/SKILL.md`
- Task 5 → `skills/executing-plans/SKILL.md`, `skills/writing-plans/SKILL.md`
- Task 6 → `skills/subagent-driven-development/SKILL.md`, `skills/subagent-driven-development/implementer-prompt.md`, drifted reviewer prompts
- Task 7 → `skills/team-driven-development/SKILL.md`, `skills/team-driven-development/implementer-prompt.md`
- Task 8 → `skills/using-git-worktrees/SKILL.md`
- Task 9 → `skills/finishing-a-development-branch/SKILL.md` + worktree-ref cascade in the three execution skills
- Task 10 → final verification

---

### Task 1: Doc path consistency cleanup (Item 1)

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md:108`
- Modify: `skills/requesting-code-review/SKILL.md:61`
- Modify: `skills/team-driven-development/SKILL.md:127`

- [ ] **Step 1: Edit the three stale references**

In `skills/subagent-driven-development/SKILL.md`, replace:
```
[Read plan file once: docs/plans/feature-plan.md]
```
with:
```
[Read plan file once: docs/superpowers/plans/feature-plan.md]
```

In `skills/team-driven-development/SKILL.md`, replace:
```
[Read plan file once: docs/plans/feature-plan.md]
```
with:
```
[Read plan file once: docs/superpowers/plans/feature-plan.md]
```

In `skills/requesting-code-review/SKILL.md`, replace:
```
  PLAN_OR_REQUIREMENTS: Task 2 from docs/plans/deployment-plan.md
```
with:
```
  PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
```

- [ ] **Step 2: Verify no stale `docs/plans/` references remain in skills**

Run:
```bash
rg -n "docs/plans/" skills/ ; echo "exit:$?"
```
Expected: no matches; `exit:1` (ripgrep exits 1 when nothing matches).

- [ ] **Step 3: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md skills/requesting-code-review/SKILL.md skills/team-driven-development/SKILL.md
git commit -m "docs: align stale docs/plans refs with docs/superpowers convention"
```

---

### Task 2: requesting-code-review — add praise-first rationale (Item 2)

**Files:**
- Modify: `agents/code-reviewer.md:45`

Decision: keep the custom agent and template; add only the *rationale* for praise-first. No other change to this skill.

- [ ] **Step 1: Edit the agent's communication protocol**

In `agents/code-reviewer.md`, replace the line:
```
   - Always acknowledge what was done well before highlighting issues
```
with:
```
   - Always acknowledge what was done well before highlighting issues — accurate praise helps the implementer trust the rest of the feedback
```

- [ ] **Step 2: Verify**

Run:
```bash
rg -n "accurate praise helps the implementer trust" agents/code-reviewer.md ; echo "exit:$?"
```
Expected: one match; `exit:0`.

- [ ] **Step 3: Commit**

```bash
git add agents/code-reviewer.md
git commit -m "docs(code-reviewer): add rationale for praise-first feedback"
```

---

### Task 3: writing-plans — File Structure + checkbox steps + Scope Check (Item 3)

**Files:**
- Modify: `skills/writing-plans/SKILL.md`

- [ ] **Step 1: Add the Scope Check section**

Insert immediately AFTER the `**Save plans to:** ...` line (currently `skills/writing-plans/SKILL.md:18`) and BEFORE `## Bite-Sized Task Granularity`:

```markdown

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure — but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.
```

(Note: this adds BOTH the Scope Check and File Structure sections in one block, placed together before the granularity section.)

- [ ] **Step 2: Add the checkbox header note in the Plan Document Header block**

In the `## Plan Document Header` code block, update the `> **For Claude:** ...` line to append a tracking note. Replace:
```
> **For Claude:** REQUIRED SUB-SKILL: Use h-superpowers:subagent-driven-development, h-superpowers:team-driven-development, or h-superpowers:executing-plans to implement this plan (ask user which approach).
```
with:
```
> **For Claude:** REQUIRED SUB-SKILL: Use h-superpowers:subagent-driven-development, h-superpowers:team-driven-development, or h-superpowers:executing-plans to implement this plan (ask user which approach). Steps use checkbox (`- [ ]`) syntax for tracking.
```

- [ ] **Step 3: Convert the Task Structure template steps to checkbox syntax**

In the `## Task Structure` fenced example, change each step heading from `**Step N: ...**` to `- [ ] **Step N: ...**`. Specifically:
- `**Step 1: Write the failing test**` → `- [ ] **Step 1: Write the failing test**`
- `**Step 2: Run test to verify it fails**` → `- [ ] **Step 2: Run test to verify it fails**`
- `**Step 3: Write minimal implementation**` → `- [ ] **Step 3: Write minimal implementation**`
- `**Step 4: Run test to verify it passes**` → `- [ ] **Step 4: Run test to verify it passes**`
- `**Step 5: Commit**` → `- [ ] **Step 5: Commit**`

- [ ] **Step 4: Verify all three additions are present**

Run:
```bash
rg -n "## Scope Check|## File Structure|Steps use checkbox|- \[ \] \*\*Step 1: Write the failing test" skills/writing-plans/SKILL.md ; echo "exit:$?"
```
Expected: four matches; `exit:0`.

- [ ] **Step 5: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "feat(writing-plans): add Scope Check, File Structure, and checkbox step syntax"
```

---

### Task 4: brainstorming — decomposition + isolation guidance (Item 5)

**Files:**
- Modify: `skills/brainstorming/SKILL.md`

- [ ] **Step 1: Add scope/decomposition bullets to "Understanding the idea"**

In `## The Process` → `**Understanding the idea:**`, insert these two bullets immediately after the `- Check out the current project state first ...` bullet and before `- Ask questions one at a time ...`:

```markdown
- Before asking detailed questions, assess scope: if the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately. Don't spend questions refining details of a project that needs to be decomposed first.
- If the project is too large for a single spec, help the user decompose into sub-projects: what are the independent pieces, how do they relate, what order should they be built? Then brainstorm the first sub-project through the normal design flow. Each sub-project gets its own spec → plan → implementation cycle.
```

- [ ] **Step 2: Add the "Design for isolation and clarity" section**

Insert a new subsection in `## The Process`, immediately AFTER the `**Presenting the design:**` block and BEFORE `## After the Design`:

```markdown
**Design for isolation and clarity:**

- Break the system into smaller units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently.
- For each unit, you should be able to answer: what does it do, how do you use it, and what does it depend on?
- Can someone understand what a unit does without reading its internals? Can you change the internals without breaking consumers? If not, the boundaries need work.
- Smaller, well-bounded units are also easier for you to work with — you reason better about code you can hold in context at once, and your edits are more reliable when files are focused. When a file grows large, that's often a signal that it's doing too much.

**Working in existing codebases:**

- Explore the current structure before proposing changes. Follow existing patterns.
- Where existing code has problems that affect the work (e.g., a file that's grown too large, unclear boundaries, tangled responsibilities), include targeted improvements as part of the design — the way a good developer improves code they're working in.
- Don't propose unrelated refactoring. Stay focused on what serves the current goal.
```

- [ ] **Step 3: Verify**

Run:
```bash
rg -n "assess scope:|Design for isolation and clarity|Working in existing codebases" skills/brainstorming/SKILL.md ; echo "exit:$?"
```
Expected: three matches; `exit:0`.

- [ ] **Step 4: Commit**

```bash
git add skills/brainstorming/SKILL.md
git commit -m "feat(brainstorming): add scope decomposition and design-for-isolation guidance"
```

---

### Task 5: executing-plans inline reframe + writing-plans handoff rename (Item 8)

**Files:**
- Modify: `skills/executing-plans/SKILL.md`
- Modify: `skills/writing-plans/SKILL.md`

- [ ] **Step 1: Update the executing-plans frontmatter description**

In `skills/executing-plans/SKILL.md`, replace the description line:
```
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
```
with:
```
description: Use when you have a written implementation plan to execute inline in the current session as the no-subagent fallback
```

- [ ] **Step 2: Rewrite the Overview**

Replace:
```
Load plan, review critically, execute tasks in batches, report for review between batches.

**Core principle:** Batch execution with checkpoints for architect review.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."
```
with:
```
Load plan, review critically, execute all tasks, report when complete.

**Core principle:** Inline execution — run the whole plan, then report.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Note:** This skill works much better with access to subagents. If subagents are available, prefer h-superpowers:subagent-driven-development (fresh subagent + two-stage review per task) instead of this skill.
```

- [ ] **Step 3: Replace the batch process (Steps 2–4) with single execute-all step**

Replace the block from `### Step 2: Execute Batch` through the end of `### Step 4: Continue` with:
```markdown
### Step 2: Execute All Tasks

For each task, in order:
1. Mark as in_progress in TodoWrite
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

Do not pause for human checkpoints between tasks. Execute the full plan, then report. Stop only when blocked (see below).
```

(Keep the existing `### Step 5: Complete Development` section but renumber it to `### Step 3: Complete Development`.)

- [ ] **Step 4: Fix the "When to Stop" and "Remember" wording that referenced batches**

In `## When to Stop and Ask for Help`, replace `- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)` with `- Hit a blocker (missing dependency, test fails, instruction unclear)`.

In `## Remember`, remove the line `- Between batches: just report and wait`.

- [ ] **Step 5: Rename writing-plans execution option 3**

In `skills/writing-plans/SKILL.md` `## Execution Handoff`, replace:
```
**3. Parallel Session (separate)** - Open new session with executing-plans, batch execution with human checkpoints
```
with:
```
**3. Inline Execution (this session)** - Execute tasks in this session using executing-plans (no subagents); the fallback when subagent/team execution isn't desired
```

And replace the `**If Parallel Session chosen:**` block:
```
**If Parallel Session chosen:**
- Guide them to open new session in worktree
- **REQUIRED SUB-SKILL:** New session uses h-superpowers:executing-plans
```
with:
```
**If Inline Execution chosen:**
- Stay in this session
- **REQUIRED SUB-SKILL:** Use h-superpowers:executing-plans
- Execute all tasks, then report
```

- [ ] **Step 6: Verify**

Run:
```bash
rg -n "execute all tasks|Execute All Tasks|Inline Execution" skills/executing-plans/SKILL.md skills/writing-plans/SKILL.md ; echo "---"; rg -n "Execute Batch|Parallel Session|mid-batch|Between batches" skills/executing-plans/SKILL.md skills/writing-plans/SKILL.md ; echo "exit:$?"
```
Expected: first `rg` shows the new inline phrasing; second `rg` shows no matches (`exit:1`).

- [ ] **Step 7: Commit**

```bash
git add skills/executing-plans/SKILL.md skills/writing-plans/SKILL.md
git commit -m "feat(executing-plans): inline reframe, drop separate-session/batch flow"
```

---

### Task 6: subagent-driven-development — four upstream additions (Item 4)

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`
- Modify: `skills/subagent-driven-development/implementer-prompt.md`
- Modify (cherry-pick wording): `skills/subagent-driven-development/spec-reviewer-prompt.md`, `skills/subagent-driven-development/code-quality-reviewer-prompt.md`

- [ ] **Step 1: Add the why-subagents framing (4A) and continuous-execution note**

In `skills/subagent-driven-development/SKILL.md`, immediately after the opening paragraph (`Execute plan by dispatching fresh subagent per task ...`) and before `**Core principle:** ...`, insert:

```markdown
**Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed. They never inherit your session's history — you construct exactly what they need. This also preserves your own context for coordination work.
```

Then immediately after the `**Core principle:** ...` line, insert:

```markdown
**Continuous execution:** Do not pause to check in with your human partner between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are: a BLOCKED status you cannot resolve, ambiguity that genuinely prevents progress, or all tasks complete. "Should I continue?" prompts and progress summaries between tasks waste the user's time — they asked you to execute the plan, so execute it.
```

- [ ] **Step 2: Add the Model Selection section (4C)**

Insert a new section immediately before `## Prompt Templates`:

```markdown
## Model Selection

Use the least powerful model that can handle each role, to conserve cost and increase speed.

- **Mechanical implementation** (isolated functions, clear spec, 1–2 files): a fast, cheap model. Most well-specified implementation tasks are mechanical.
- **Integration and judgment** (multi-file coordination, pattern matching, debugging): a standard model.
- **Architecture, design, and review**: the most capable available model.

Complexity signals: touches 1–2 files with a complete spec → cheap; multiple files with integration concerns → standard; requires design judgment or broad codebase understanding → most capable.
```

- [ ] **Step 3: Add the Handling Implementer Status section (4D, SKILL side)**

Insert a new section immediately before `## Prompt Templates` (after Model Selection):

```markdown
## Handling Implementer Status

Implementer subagents report one of four statuses. Handle each:

- **DONE** — proceed to spec compliance review.
- **DONE_WITH_CONCERNS** — read the concerns before proceeding. If they bear on correctness or scope, address them before review; if they're observations (e.g., "this file is getting large"), note and proceed to review.
- **NEEDS_CONTEXT** — the implementer is missing information that wasn't provided. Provide it and re-dispatch.
- **BLOCKED** — assess the blocker: (1) context problem → provide more context, re-dispatch with the same model; (2) needs more reasoning → re-dispatch with a more capable model; (3) task too large → break it into smaller pieces; (4) the plan itself is wrong → escalate to the human.

**Never** ignore an escalation or force the same model to retry without changes. If the implementer is stuck, something must change before retrying.
```

- [ ] **Step 4: Make implementer-prompt emit a status (4D, prompt side)**

In `skills/subagent-driven-development/implementer-prompt.md`, replace the `## Report Format` block:
```
    ## Report Format

    When done, report:
    - What you implemented
    - What you tested and test results
    - Files changed
    - Self-review findings (if any)
    - Any issues or concerns
```
with:
```
    ## Report Format

    Begin your report with exactly one status line:
    - `STATUS: DONE` — task complete, all tests pass, ready for review
    - `STATUS: DONE_WITH_CONCERNS` — complete, but you have doubts worth flagging (state them)
    - `STATUS: NEEDS_CONTEXT` — you cannot proceed without information that wasn't provided (state exactly what you need)
    - `STATUS: BLOCKED` — you cannot complete the task (state the blocker and what you tried)

    Then report:
    - What you implemented
    - What you tested and test results
    - Files changed
    - Self-review findings (if any)
    - Any remaining issues or concerns
```

- [ ] **Step 5: Cherry-pick non-conflicting wording from upstream's drifted reviewer prompts**

Compare each prompt against upstream and pull only clarity improvements that don't conflict with the fork's two-stage model:
```bash
git diff main:skills/subagent-driven-development/spec-reviewer-prompt.md upstream/main:skills/subagent-driven-development/spec-reviewer-prompt.md
git diff main:skills/subagent-driven-development/code-quality-reviewer-prompt.md upstream/main:skills/subagent-driven-development/code-quality-reviewer-prompt.md
```
Apply only wording upgrades (e.g., crisper checklist phrasing). Do NOT adopt upstream's single-review structure or its `general-purpose` reviewer-agent switch (fork keeps its custom `code-reviewer` agent and two-stage flow). If a diff hunk only reflects the structural divergence, skip it. Record in the commit message which hunks were taken.

- [ ] **Step 6: Verify**

Run:
```bash
rg -n "Why subagents:|Continuous execution:|## Model Selection|## Handling Implementer Status" skills/subagent-driven-development/SKILL.md ; echo "---"; rg -n "STATUS: DONE|STATUS: BLOCKED|STATUS: NEEDS_CONTEXT|STATUS: DONE_WITH_CONCERNS" skills/subagent-driven-development/implementer-prompt.md ; echo "exit:$?"
```
Expected: four SKILL.md matches and four implementer-prompt matches; `exit:0`.

- [ ] **Step 7: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md skills/subagent-driven-development/implementer-prompt.md skills/subagent-driven-development/spec-reviewer-prompt.md skills/subagent-driven-development/code-quality-reviewer-prompt.md
git commit -m "feat(subagent-driven): add why-subagents, continuous-exec, model selection, four-status protocol"
```

---

### Task 7: team-driven-development — mirror item 4 (adapted)

**Files:**
- Modify: `skills/team-driven-development/SKILL.md`
- Modify: `skills/team-driven-development/implementer-prompt.md`

Mirror Task 6's four additions, adapted to the persistent-teammate / shared-task-list / messaging model.

- [ ] **Step 1: Add why-teammates framing + continuous-execution (adapted)**

In `skills/team-driven-development/SKILL.md`, after the opening paragraph, insert:
```markdown
**Why teammates:** You coordinate persistent specialized agents that collaborate through a shared task list and direct messaging. Each teammate works in isolated context you help shape; they don't inherit your history. This preserves your context for coordination and lets independent work proceed in parallel.
```
After the `**Core principle:** ...` line, insert:
```markdown
**Continuous execution:** Teammates keep pulling tasks from the shared list until none remain — they don't pause to ask "should I continue?" between tasks. The lead stops the flow only for an unresolvable BLOCKED status, genuine ambiguity, or completion of all tasks.
```

- [ ] **Step 2: Add Model Selection (adapted to per-teammate-role)**

Insert before the team-driven `## Prompt Templates` (or equivalent prompt-listing section) a `## Model Selection` section identical in guidance to Task 6 Step 2, but framed per teammate role: mechanical implementer teammate → cheap model; integration/debugging teammate → standard; architecture/review teammate → most capable.

- [ ] **Step 3: Add Handling Implementer Status (adapted to messaging)**

Insert a `## Handling Teammate Status` section mirroring Task 6 Step 3, but specifying that teammates report status via `SendMessage` to the lead and reflect it in shared task-list updates (TaskUpdate), rather than as a function return value. Same four statuses and same handling rules (provide context / escalate model / split / escalate to human; never force same-model retry without changes).

- [ ] **Step 4: Make team implementer-prompt emit a status**

In `skills/team-driven-development/implementer-prompt.md`, apply the same `## Report Format` status-line change as Task 6 Step 4, adapted so the status is sent to the lead via `SendMessage` (the prompt should instruct: "Send your status line to the lead via SendMessage, then update your task in the shared list").

- [ ] **Step 5: Verify**

Run:
```bash
rg -n "Why teammates:|Continuous execution:|## Model Selection|## Handling Teammate Status" skills/team-driven-development/SKILL.md ; echo "---"; rg -n "STATUS: DONE|STATUS: BLOCKED|STATUS: NEEDS_CONTEXT|STATUS: DONE_WITH_CONCERNS" skills/team-driven-development/implementer-prompt.md ; echo "exit:$?"
```
Expected: four SKILL.md matches and four implementer-prompt matches; `exit:0`.

- [ ] **Step 6: Commit**

```bash
git add skills/team-driven-development/SKILL.md skills/team-driven-development/implementer-prompt.md
git commit -m "feat(team-driven): mirror why-teammates, continuous-exec, model selection, four-status protocol"
```

---

### Task 8: using-git-worktrees — native-first rewrite (Item 7)

**Files:**
- Modify: `skills/using-git-worktrees/SKILL.md`

Rewrite around `EnterWorktree`; keep Step 0 isolation detection, submodule guard, and a manual-git fallback; retire directory-selection/gitignore/sibling machinery.

- [ ] **Step 1: Replace Overview core principle**

Replace:
```
**Core principle:** Systematic directory selection + safety verification = reliable isolation.
```
with:
```
**Core principle:** Detect existing isolation first; then use the native worktree tool; fall back to manual git only when native is unavailable.
```

- [ ] **Step 2: Replace "Directory Selection Process" + "Safety Verification" + "Creation Steps (1 & 2)" with Step 0 / native / fallback**

Replace the entire span from `## Directory Selection Process` through the end of `### 2. Create Worktree` (i.e., up to but not including `### 3. Run Project Setup`) with:

```markdown
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
```

- [ ] **Step 3: Update Quick Reference, Common Mistakes, Hard Rules, and frontmatter description**

- Frontmatter description: replace `creates isolated git worktrees with smart directory selection and safety verification` with `ensures an isolated workspace via the native worktree tool, with a manual git fallback`.
- In `## Quick Reference`, replace the directory-selection rows with rows reflecting: "Already in a worktree → use it (skip creation)"; "Native tool available → EnterWorktree"; "No native tool → manual git worktree under .worktrees/ (verify ignored)"; keep the test-baseline rows.
- In `## Common Mistakes`, remove "Assuming directory location" and "Skipping ignore verification" entries' project-local-selection framing; replace with "Creating a nested worktree (didn't run Step 0 detection)" and keep the failing-tests and hardcoding-setup entries.
- In `## Hard Rules`, replace the directory-priority and CLAUDE.md-check rules with: "Run Step 0 detection before creating — never nest worktrees"; "Prefer the native tool; manual git only as fallback"; "For the manual fallback, verify `.worktrees/` is ignored"; keep the baseline-test rules.

- [ ] **Step 4: Verify**

Run:
```bash
rg -n "EnterWorktree|Step 0: Detect Existing Isolation|Manual git fallback|Submodule guard|Sandbox fallback" skills/using-git-worktrees/SKILL.md ; echo "---"; rg -n "Directory Selection Process|Check CLAUDE.md|If both exist" skills/using-git-worktrees/SKILL.md ; echo "exit:$?"
```
Expected: first `rg` shows the native-first content; second `rg` shows no matches (`exit:1`).

- [ ] **Step 5: Commit**

```bash
git add skills/using-git-worktrees/SKILL.md
git commit -m "feat(using-git-worktrees): native-first (EnterWorktree) with detect-isolation and manual fallback"
```

---

### Task 9: finishing-a-development-branch native teardown + execution-skill cascade (Item 6)

**Files:**
- Modify: `skills/finishing-a-development-branch/SKILL.md`
- Modify: `skills/subagent-driven-development/SKILL.md` (worktree-ref/CWD-warning cascade)
- Modify: `skills/team-driven-development/SKILL.md` (worktree-ref/CWD-warning cascade)
- Modify: `skills/executing-plans/SKILL.md` (worktree-ref cascade)

- [ ] **Step 1: Add native teardown as the primary path in Step 5 (Cleanup)**

In `skills/finishing-a-development-branch/SKILL.md` `### Step 5: Cleanup Worktree`, insert a native-first block BEFORE the existing manual `git worktree list`/`git worktree remove` content:

```markdown
**Native teardown (preferred).** If the worktree was created with `EnterWorktree` this session, use `ExitWorktree` — it returns the session to the original directory and removes or keeps the worktree safely (it only ever touches worktrees this session created):

- Option 1 (merge locally): after merge + verify in the main repo, `ExitWorktree(action: "remove")`.
- Option 4 (discard): after typed confirmation, `ExitWorktree(action: "remove", discard_changes: true)`.
- Options 2 (PR) and 3 (keep): `ExitWorktree(action: "keep")` (or leave in place) — branch stays active.

If `ExitWorktree` reports no active worktree session (e.g., the worktree was created manually or in a different session), fall back to the manual cleanup below.

**Manual fallback (non-native worktrees):**
```

(The existing CWD-safe `git worktree remove` block becomes the fallback that follows this heading.)

- [ ] **Step 2: Add detached-HEAD reduced menu (manual/non-native path)**

In `### Step 3: Present Options` (currently presents 4 options), add an environment note and an alternative 3-option menu:

```markdown
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
Otherwise present the standard 4 options.
```

- [ ] **Step 3: Apply the merge-before-cleanup ordering fix (manual fallback, Option 1)**

In `#### Option 1: Merge Locally`, change the procedure so it operates in the main repo and deletes the branch only AFTER worktree removal:
```bash
# Operate in the MAIN repo, not inside the feature worktree
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git checkout <base-branch>
git pull
git merge <feature-branch>
<test command>     # verify tests on merged result BEFORE removing anything
# Then: native ExitWorktree(remove) OR manual worktree remove (Step 5)
# Only after the worktree is gone:
git branch -d <feature-branch>
```
Update the Quick Reference and Common Mistakes to reflect: branch deletion happens after worktree removal.

- [ ] **Step 4: Remove obsolete provenance/sibling references**

Ensure no path-based provenance allowlist or sibling-`<repo>-worktrees/` logic is introduced (it was considered then dropped). The cleanup decision is: native → ExitWorktree; otherwise → CWD-safe manual remove. Confirm via grep in Step 6.

- [ ] **Step 5: Cascade — update worktree references in the execution skills**

- `skills/subagent-driven-development/SKILL.md`: in the "Worktree Completion" / "⚠️ CWD warning" area and the Integration "using-git-worktrees - REQUIRED: Set up isolated workspace" line, update wording so setup means "create via using-git-worktrees (native EnterWorktree)" and teardown is deferred to finishing-a-development-branch (which uses ExitWorktree). Keep the CWD warning but mark it as applying to the manual-git fallback only.
- `skills/team-driven-development/SKILL.md`: same cascade wording.
- `skills/executing-plans/SKILL.md`: `### Step 0: Set Up Workspace` and the Integration line — wording so workspace setup uses the native worktree tool via using-git-worktrees.

- [ ] **Step 6: Verify**

Run:
```bash
rg -n "Native teardown \(preferred\)|ExitWorktree|detached HEAD|MAIN_ROOT" skills/finishing-a-development-branch/SKILL.md ; echo "---"; rg -ni "sibling|provenance|<reponame>-worktrees|reponame-worktrees" skills/finishing-a-development-branch/SKILL.md ; echo "exit:$?"
```
Expected: first `rg` shows native teardown content; second `rg` shows no matches (`exit:1`).

- [ ] **Step 7: Commit**

```bash
git add skills/finishing-a-development-branch/SKILL.md skills/subagent-driven-development/SKILL.md skills/team-driven-development/SKILL.md skills/executing-plans/SKILL.md
git commit -m "feat(finishing): native ExitWorktree teardown, detached-HEAD menu, ordering fix; cascade worktree refs"
```

---

### Task 10: Final verification

**Files:** none (verification only)

- [ ] **Step 1: Structural sweep — confirm no stale patterns survived anywhere in skills/**

Run:
```bash
rg -n "docs/plans/|Parallel Session|Execute Batch|mid-batch|Directory Selection Process" skills/ ; echo "exit:$?"
```
Expected: no matches; `exit:1`.

- [ ] **Step 2: Confirm all new anchors exist**

Run:
```bash
rg -l "## Scope Check" skills/writing-plans/SKILL.md && \
rg -l "Design for isolation and clarity" skills/brainstorming/SKILL.md && \
rg -l "## Handling Implementer Status" skills/subagent-driven-development/SKILL.md && \
rg -l "## Handling Teammate Status" skills/team-driven-development/SKILL.md && \
rg -l "EnterWorktree" skills/using-git-worktrees/SKILL.md skills/finishing-a-development-branch/SKILL.md && \
echo "ALL ANCHORS PRESENT"
```
Expected: prints `ALL ANCHORS PRESENT`.

- [ ] **Step 3: Run the fast unit test suite**

Run:
```bash
bash tests/run-all.sh
```
Expected: suite passes. Per project rules, do NOT restrict tool availability to make a test pass — if a behavioral test fails because the new skill wording leads Claude to the wrong tool, fix the SKILL.md wording, not the test.

- [ ] **Step 4: Note the expensive integration gate (manual, optional)**

The worktree/team integration tests invoke real Claude sessions (35–60 min, billed) and must be run from a standalone terminal:
```bash
bash tests/claude-code/run-skill-tests.sh --integration -t test-team-worktree-integration.sh
```
This is a manual acceptance gate, not part of routine CI for this change. The test already accepts `EnterWorktree` as worktree-creation evidence, so native-first should pass; if its prompt wording (`git worktree add`) needs softening to `EnterWorktree`, update the test prompt (not the assertion).

- [ ] **Step 5: Final commit (if any verification-driven fixes were made)**

```bash
git add -A
git commit -m "test: verification fixes for upstream adoption"
```

---

## Notes for the executor

- **Resolved (spec item 7e):** `EnterWorktree`'s "explicit instruction" gate is satisfied by the Step 0 consent prompt (or a user/CLAUDE.md-declared worktree preference) — the user agreeing to the worktree is the instruction. No repo CLAUDE.md line is needed (and a plugin's own CLAUDE.md isn't loaded inside an end-user's project anyway). The `using-git-worktrees` Native-tool section attributes the gate to consent, not to the skill "announcing."
- **team-driven-development is fork-only** — there is no upstream counterpart to diff against. Tasks 7 and the Task 9 cascade are pure fork maintenance.
- Do not adopt upstream's `general-purpose` code-reviewer restructure or single-review structure (explicitly rejected in the spec).
