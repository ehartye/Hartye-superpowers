---
name: team-driven-development
description: Use when executing plans requiring coordination between persistent named agents working in parallel with shared tasks and inter-agent messaging
---

# Team-Driven Development

Execute plan by spawning persistent named agents that collaborate via shared task list and direct messaging, with two-stage review after each task: spec compliance review first, then code quality review.

**Why persistent agents:** You coordinate persistent specialized agents that collaborate through a shared task list and direct messaging. Each agent works in isolated context you help shape; they don't inherit your history. Because agents persist — you continue them with `SendMessage` and they retain everything they've seen — context carries across tasks. This preserves your context for coordination and lets independent work proceed in parallel.

**Core principle:** Persistent named agents + shared task list + direct messaging + two-stage review (spec then quality) = high quality, parallel execution

**Continuous execution:** Agents keep pulling tasks from the shared list until none remain — they don't pause to ask "should I continue?" between tasks. The lead stops the flow only for an unresolvable BLOCKED status, genuine ambiguity, or completion of all tasks.

**Requirements:** A harness with background agents (`Agent` tool), agent continuation and inter-agent messaging (`SendMessage`), and shared task tools (`TaskCreate`/`TaskList`/`TaskUpdate`) — current Claude Code has all of these natively. Token-hungry: each persistent agent is a full session. Budget accordingly.

## When to Use

```dot
digraph when_to_use {
    "Have implementation plan?" [shape=diamond];
    "Tasks need coordination?" [shape=diamond];
    "Budget allows full sessions per agent?" [shape=diamond];
    "team-driven-development" [shape=box style=filled fillcolor=lightblue];
    "subagent-driven-development" [shape=box];
    "Manual or brainstorm first" [shape=box];

    "Have implementation plan?" -> "Tasks need coordination?" [label="yes"];
    "Have implementation plan?" -> "Manual or brainstorm first" [label="no"];
    "Tasks need coordination?" -> "Budget allows full sessions per agent?" [label="yes - agents must collaborate"];
    "Tasks need coordination?" -> "subagent-driven-development" [label="no - independent tasks"];
    "Budget allows full sessions per agent?" -> "team-driven-development" [label="yes - 2-4x cost OK"];
    "Budget allows full sessions per agent?" -> "subagent-driven-development" [label="no - use sequential"];
}
```

**vs. Subagent-Driven Development (sequential):**
- Persistent agents (context preserved across tasks via `SendMessage` continuation)
- Parallel execution (multiple tasks simultaneously)
- Direct agent-to-agent messaging (not just hub-and-spoke)
- Two-stage review after each task: spec compliance first, then code quality
- 2-4x more expensive (each persistent agent is a full Claude session)

## The Process

```dot
digraph process {
    rankdir=TB;

    "Read plan, extract all tasks, create TaskCreate for each" [shape=box];

    subgraph cluster_setup {
        label="Setup (fan out named agents)";
        "Spawn implementer agents (./implementer-prompt.md)" [shape=box];
        "Spawn spec reviewer agent (./spec-reviewer-prompt.md)" [shape=box];
        "Spawn code quality reviewer agent (./code-quality-reviewer-prompt.md)" [shape=box];
        "Broadcast roster (name -> agent ID) to every agent" [shape=box];
    }

    subgraph cluster_per_task {
        label="Per Task (agents self-coordinate)";
        "Implementer claims task, asks questions via SendMessage" [shape=box];
        "Implementer implements, tests, commits, self-reviews" [shape=box];
        "Implementer requests spec review via SendMessage" [shape=box];
        "Spec reviewer confirms code matches spec?" [shape=diamond];
        "Implementer fixes spec gaps" [shape=box];
        "Spec reviewer approves, implementer requests code quality review via SendMessage" [shape=box];
        "Code quality reviewer approves?" [shape=diamond];
        "Implementer fixes quality issues" [shape=box];
        "Implementer reports DONE; lead marks task complete (TaskUpdate)" [shape=box];
    }

    "More tasks remain?" [shape=diamond];
    "Verify TaskList all completed, run full test suite" [shape=box];
    "Use h-superpowers:finishing-a-development-branch" [shape=box style=filled fillcolor=lightgreen];

    "Read plan, extract all tasks, create TaskCreate for each" -> "Spawn implementer agents (./implementer-prompt.md)";
    "Spawn implementer agents (./implementer-prompt.md)" -> "Spawn spec reviewer agent (./spec-reviewer-prompt.md)";
    "Spawn spec reviewer agent (./spec-reviewer-prompt.md)" -> "Spawn code quality reviewer agent (./code-quality-reviewer-prompt.md)";
    "Spawn code quality reviewer agent (./code-quality-reviewer-prompt.md)" -> "Broadcast roster (name -> agent ID) to every agent";
    "Broadcast roster (name -> agent ID) to every agent" -> "Implementer claims task, asks questions via SendMessage";
    "Implementer claims task, asks questions via SendMessage" -> "Implementer implements, tests, commits, self-reviews";
    "Implementer implements, tests, commits, self-reviews" -> "Implementer requests spec review via SendMessage";
    "Implementer requests spec review via SendMessage" -> "Spec reviewer confirms code matches spec?";
    "Spec reviewer confirms code matches spec?" -> "Implementer fixes spec gaps" [label="no"];
    "Implementer fixes spec gaps" -> "Implementer requests spec review via SendMessage" [label="re-review"];
    "Spec reviewer confirms code matches spec?" -> "Spec reviewer approves, implementer requests code quality review via SendMessage" [label="yes"];
    "Spec reviewer approves, implementer requests code quality review via SendMessage" -> "Code quality reviewer approves?";
    "Code quality reviewer approves?" -> "Implementer fixes quality issues" [label="no"];
    "Implementer fixes quality issues" -> "Spec reviewer approves, implementer requests code quality review via SendMessage" [label="re-review"];
    "Code quality reviewer approves?" -> "Implementer reports DONE; lead marks task complete (TaskUpdate)" [label="yes"];
    "Implementer reports DONE; lead marks task complete (TaskUpdate)" -> "More tasks remain?";
    "More tasks remain?" -> "Implementer claims task, asks questions via SendMessage" [label="yes"];
    "More tasks remain?" -> "Verify TaskList all completed, run full test suite" [label="no"];
    "Verify TaskList all completed, run full test suite" -> "Use h-superpowers:finishing-a-development-branch";
}
```

## Coordination Mechanics

These are hard facts of the harness, verified against real run transcripts —
prompts that ignore them strand agents:

1. **The shared task board is LEAD-ONLY.** `TaskCreate`/`TaskList`/`TaskUpdate`/
   `TaskGet` do not resolve inside spawned agent sessions (not even via
   ToolSearch). The lead creates every task, assigns work by message with the
   FULL task text, and mirrors every status change into the board. Never
   instruct an agent to claim or complete tasks itself.
2. **Peer addressing is by agent ID, not name.** `SendMessage(to: "spec-auditor")`
   fails with "No agent named ... is reachable" — semantic names only resolve
   in the spawner's registry. `to: "main"` always reaches the lead, and raw
   agent IDs (from each spawn result) always work. Therefore:
   - The lead captures the agent ID from every spawn result.
   - After all agents are spawned, the lead sends each one a **roster**:
     "You are <name>, agent ID <id>. Crew roster: <name> = <id>, ... Address
     peers by ID; 'main' reaches me."
   - Agents include their own name AND id in every peer message so replies
     have a verified return address.
3. **SendMessage may be deferred in agent sessions.** Agents load it with
   `ToolSearch("select:SendMessage")` before first use instead of concluding
   messaging is unavailable.

## Model Selection

Use the least powerful model that can handle each agent's role, to conserve cost and increase speed.

- **Mechanical implementer agent** (isolated functions, clear spec, 1–2 files): a fast, cheap model. Most well-specified implementation tasks are mechanical.
- **Integration / debugging agent** (multi-file coordination, pattern matching): a standard model.
- **Architecture, design, and review agent**: the most capable available model.

Complexity signals: touches 1–2 files with a complete spec → cheap; multiple files with integration concerns → standard; requires design judgment or broad codebase understanding → most capable.

## Handling Agent Status

Implementer agents report one of four statuses to the lead via `SendMessage`; the lead mirrors each into the shared task list (`TaskUpdate` — lead-only, see Coordination Mechanics). The lead handles each:

- **DONE** — proceed to spec compliance review.
- **DONE_WITH_CONCERNS** — read the concerns before proceeding. If they bear on correctness or scope, address them before review; if they're observations (e.g., "this file is getting large"), note and proceed to review.
- **NEEDS_CONTEXT** — the agent is missing information that wasn't provided. Send it via `SendMessage` and let them continue.
- **BLOCKED** — assess the blocker: (1) context problem → send more context; (2) needs more reasoning → reassign to a more capable model; (3) task too large → split it into smaller shared-list tasks; (4) the plan itself is wrong → escalate to the human.

**Never** ignore an escalation or force the same model to retry without changes. If an agent is stuck, something must change before retrying.

## Prompt Templates

- `./implementer-prompt.md` - Spawn implementer agent
- `./spec-reviewer-prompt.md` - Spawn spec compliance reviewer agent
- `./code-quality-reviewer-prompt.md` - Spawn code quality reviewer agent

### Agent naming

Give each agent a **semantic name** that reflects their focus area or personality — never use numbered names like `implementer-1`. Good names make message logs readable and give each agent a distinct identity. Names are labels for logs and the roster — the **address** other agents must use with `SendMessage` is the agent ID from the spawn result (see Coordination Mechanics); only the lead can reliably address by name.

- **Implementers:** Name after their focus — `hook-installer`, `api-layer`, `ui-dashboard`, `test-harness`, `schema-migrator`
- **Spec reviewer:** Name after their adversarial role — `spec-auditor`, `requirements-checker`, `compliance-eye`
- **Code quality reviewer:** Name after their quality focus — `quality-sentinel`, `code-critic`, `standards-keeper`

Pick names that fit the project. Be creative — the only constraint is that the name should be recognizable in message logs.

### Role summaries

**Implementer self-review:** Before requesting review, implementers review their own work for completeness (all requirements met?), quality (clear naming, clean code?), discipline (no overbuilding, follows existing patterns?), and testing (tests verify real behavior, not just mock it?). Issues found during self-review are fixed before handoff to reviewers.

**Spec reviewer mindset:** Independent verification — reads code directly against the spec rather than taking the implementer's summary on faith. Not adversarial, just complementary: authors are the least likely people to catch what they missed. Checks three things: (1) missing requirements — did anything get skipped? (2) extra work — did anything not in spec get built? (3) misunderstandings — was the wrong problem solved?

**Code quality reviewer:** Only reviews after spec compliance passes. Reviews the diff for clean code, test coverage, maintainability, and adherence to project conventions. Returns strengths, issues (critical/important/minor), and an overall assessment.

**Lead (you):** Orchestrates via native tools — `TaskCreate` (populate the shared list), `TaskUpdate` (assign owners and mirror agent-reported statuses — the board is lead-only), `SendMessage` (coordinate and continue agents). Captures agent IDs from spawn results and broadcasts the roster. Does NOT implement. Monitors `TaskList`, resolves conflicts, enforces quality gates, verifies completion.

## Example Workflow

```
You: I'm using Team-Driven Development to execute this plan.

[Read plan file once: docs/superpowers/plans/feature-plan.md]
[Extract all 5 tasks with full text and context]
[TaskCreate for each task, TaskUpdate to set dependencies]

[Read ./implementer-prompt.md, fill in project context]
[Spawn hook-installer (implementer, focus: hook setup) via Agent tool, run_in_background — spawn result: ID a11...]
[Spawn recovery-builder (implementer, focus: recovery modes) via Agent tool, run_in_background — ID b22...]
[Read ./spec-reviewer-prompt.md, fill in project context]
[Spawn spec-auditor (spec reviewer) via Agent tool, run_in_background — ID c33...]
[Read ./code-quality-reviewer-prompt.md, fill in project context]
[Spawn quality-sentinel (code quality reviewer) via Agent tool, run_in_background — ID d44...]

[SendMessage roster to each agent: "You are <name>, ID <id>. Roster:
 hook-installer=a11..., recovery-builder=b22..., spec-auditor=c33...,
 quality-sentinel=d44... Address peers by ID; 'main' reaches me."]

[Monitor TaskList, respond to messages; continue any idle agent via SendMessage]

Task 1: Hook installation script

[You assign task-1 to hook-installer via SendMessage with the FULL task text]

hook-installer messages you:
  "Before I begin - should the hook be installed at user or system level?"

You reply via SendMessage:
  "User level (~/.config/superpowers/hooks/)"

hook-installer: "Got it. Implementing now..."
[Later] hook-installer messages spec-auditor (to: c33..., from roster):
  - Implemented install-hook command
  - Added tests, 5/5 passing
  - Self-review: Found I missed --force flag, added it
  - Committed
  - Please review spec compliance

spec-auditor messages hook-installer:
  ✅ Spec compliant - all requirements met, nothing extra

hook-installer messages quality-sentinel:
  Please review code quality

quality-sentinel messages hook-installer:
  Strengths: Good test coverage, clean. Issues: None. Approved.

[hook-installer reports task-1 DONE to you; you mark it complete via TaskUpdate]

Task 2: Recovery modes (meanwhile, recovery-builder is working on task-3 in parallel)

[You assign task-2 to hook-installer] — proceeds without questions:
  - Added verify/repair modes
  - 8/8 tests passing
  - Self-review: All good
  - Committed

spec-auditor messages hook-installer:
  ❌ Issues:
  - Missing: Progress reporting (spec says "report every 100 items")
  - Extra: Added --json flag (not requested)

[hook-installer fixes, requests re-review]

spec-auditor: ✅ Spec compliant now

quality-sentinel: Strengths: Solid. Issues (Important): Magic number (100)

[hook-installer fixes, requests re-review]

quality-sentinel: ✅ Approved

[hook-installer reports task-2 DONE; you mark it complete]

...

[All tasks complete — TaskList confirms all status: completed]
[Run full test suite]
[Use finishing-a-development-branch — handles merge, tests, worktree cleanup, and disposition]
```

## Worktree Completion

Workspace **setup** goes through `h-superpowers:using-git-worktrees` (native `EnterWorktree`). **Teardown is deferred** to `finishing-a-development-branch` — do not remove the worktree here.

After all tasks are complete, invoke `h-superpowers:finishing-a-development-branch`.
That skill handles merge, test verification, worktree teardown (via native `ExitWorktree`, with a manual `git worktree remove` fallback), and final disposition (push, PR, keep, discard). **Do not duplicate those steps here** — just invoke the skill and follow its instructions.

**⚠️ CWD warning (manual-git fallback only):** If a worktree was created via the manual git fallback (not native `EnterWorktree`/`ExitWorktree`) and your shell is inside it, always `cd` out of the worktree to the main repo before any manual `git worktree remove` — removing the CWD invalidates the shell. Native `ExitWorktree` handles this for you.

## Completion

**When all tasks are complete, execute this immediately. No exceptions.**

1. Call `TaskList` to confirm every task shows status `completed`.
2. Run the full test suite to verify the final result.
3. Confirm no agent is still mid-task (you'll have received each agent's final report as a task notification). There is no shutdown ritual — a persistent agent that has finished its work simply goes idle. If an agent is hung or runaway, stop it with `TaskStop`.
4. Summarize what was accomplished to the user.

**Hard stop.** After step 3, the orchestration is over. No coordination messages, no "are you still there?", no additional review cycles. Verify, summarize, and get out.

## Advantages

**vs. Manual execution:**
- Agents follow TDD naturally
- Persistent context per agent (no confusion across tasks)
- Parallel execution (multiple tasks at once)
- Agents can ask questions (before AND during work)

**vs. Subagent-Driven Development:**
- Parallel execution (wall-clock time savings)
- Direct agent-to-agent messaging (not just hub-and-spoke)
- Persistent context (agent remembers earlier tasks)
- Collaborative review (discussion, not just pass/fail)

**Quality gates:**
- Self-review catches issues before handoff
- Two-stage review: spec compliance, then code quality
- Review loops ensure fixes actually work
- Spec compliance prevents over/under-building
- Code quality ensures implementation is well-built

**Cost:**
- Each persistent agent is a full Claude session (2-4x more than subagents)
- Message overhead adds to cost
- But parallel execution saves wall-clock time
- And catches issues early (cheaper than debugging later)

## Hard Rules

These are the guardrails the workflow depends on — skipping any of them breaks the quality guarantees of the skill:

- Don't start implementation on main/master branch without explicit user consent
- Don't skip reviews (spec compliance OR code quality)
- Don't proceed with unfixed issues
- Don't exceed 6 agents (coordination overhead gets too high)
- Don't ignore messages from agents — that breaks collaboration
- Don't skip the roster broadcast — peers can only address each other by agent ID
- Don't tell agents to touch the task board — it is lead-only; mirror their reported statuses yourself
- Don't mark a task complete before the reviewer approves
- **Don't start code quality review before spec compliance is ✅** — wrong order
- Don't move to the next task while either review has open issues
- Budget for full sessions per agent before spawning the crew

**If an agent asks questions:**
- Answer clearly and completely via SendMessage
- Provide additional context if needed
- Don't rush them into implementation

**If a reviewer finds issues:**
- Implementer fixes them
- Reviewer reviews again
- Repeat until approved — don't skip the re-review

**If an agent fails a task:**
- Send fix instructions via SendMessage
- Don't try to fix manually (you're the lead, not the implementer)

## Integration

**Required workflow skills:**
- **h-superpowers:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting (native `EnterWorktree`)
- **h-superpowers:writing-plans** - Creates the plan this skill executes
- **h-superpowers:requesting-code-review** - Code review template for reviewer agents
- **h-superpowers:finishing-a-development-branch** - Complete development after all tasks; handles worktree teardown via `ExitWorktree`

**Agents follow:**
- **h-superpowers:test-driven-development** - TDD is baked into implementer prompts (red-green-refactor, Prime Directive)
- **h-superpowers:verification-before-completion** - Evidence before completion claims, baked into implementer self-review

**Alternative workflow:**
- **h-superpowers:subagent-driven-development** - Use for independent sequential tasks instead
- **h-superpowers:executing-plans** - Use for inline, no-subagent execution in this session (simpler fallback)
