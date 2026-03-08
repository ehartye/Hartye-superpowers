# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent.

```
Task tool (general-purpose):
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing Task N: [task name]

    ## Task Description

    [FULL TEXT of task from plan - paste it here, don't make subagent read file]

    ## Context

    [Scene-setting: where this fits, dependencies, architectural context]

    ## Before You Begin

    If you have questions about:
    - The requirements or acceptance criteria
    - The approach or implementation strategy
    - Dependencies or assumptions
    - Anything unclear in the task description

    **Ask them now.** Raise any concerns before starting work.

    ## Your Job

    Once you're clear on requirements, follow TDD (red-green-refactor):

    1. **RED:** Write a failing test for the next piece of behavior
    2. **Verify RED:** Run it — confirm it fails for the right reason
    3. **GREEN:** Write minimal code to pass the test
    4. **Verify GREEN:** Run it — confirm all tests pass
    5. **REFACTOR:** Clean up while keeping tests green
    6. Repeat steps 1-5 until the task is fully implemented
    7. **Commit your work NOW** — do not defer this. Create a git commit
       with a clear message before moving on. Every task must have its own
       commit so the git history reflects incremental progress.
    8. Self-review (see below)
    9. Report back

    **The Iron Law: No production code without a failing test first.**
    Wrote code before a test? Delete it. Start over from a failing test.
    No exceptions.

    Work from: [directory]

    **Tool use in worktrees:** If your working directory is a temp path or
    worktree, use absolute paths for all tool calls. If the Write tool
    silently fails (file not found after write), fall back to
    `bash cat > /absolute/path << 'EOF'`. Always `cd [directory]` before
    running shell commands. Stage specific files (`git add src/file.js`),
    never `git add .` or `git add -A`.

    **While you work:** If you encounter something unexpected or unclear, **ask questions**.
    It's always OK to pause and clarify. Don't guess or make assumptions.

    ## Before Reporting Back: Self-Review

    Review your work with fresh eyes. Ask yourself:

    **Completeness:**
    - Did I fully implement everything in the spec?
    - Did I miss any requirements?
    - Are there edge cases I didn't handle?

    **Quality:**
    - Is this my best work?
    - Are names clear and accurate (match what things do, not how they work)?
    - Is the code clean and maintainable?

    **Discipline:**
    - Did I avoid overbuilding (YAGNI)?
    - Did I only build what was requested?
    - Did I follow existing patterns in the codebase?

    **Testing (TDD):**
    - Did I write every test before its production code?
    - Did I watch each test fail before making it pass?
    - Do tests verify real behavior (not just mock behavior)?
    - Are tests comprehensive?

    If you find issues during self-review, fix them now before reporting.

    ## Report Format

    When done, report:
    - What you implemented
    - What you tested and test results
    - Files changed
    - Self-review findings (if any)
    - Any issues or concerns
```
