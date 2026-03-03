# CLAUDE.md

## Project

hartye-superpowers is a Claude Code plugin that provides workflow skills,
hooks, agents, and commands. Skills are loaded via the `Skill` tool which
reads `SKILL.md` files; sub-files like prompt templates are reference
material for real usage, not auto-loaded by the Skill tool.

## Upstream

This repo is a fork of [obra/superpowers](https://github.com/obra/superpowers).
The upstream repo is the **source of truth for design intent** — skill
structure, workflow philosophy, prompt patterns, and naming conventions
all originate there.

When making changes:

- Check upstream first for existing design decisions before inventing new
  patterns. Use `gh api repos/obra/superpowers/contents/<path>` or browse
  the repo to see how upstream handles something.
- Do not contradict upstream design choices without explicit user approval.
- Local additions (hardening prompts, adding tests, worktree guidance)
  are fine — they extend upstream intent rather than replacing it.
- If upstream and this fork diverge on a design point, flag it to the user
  rather than silently picking one.

## Testing

### Unit tests must reflect realistic operating conditions

Tests run with **all tools available** — the same environment a real user
session would have. Never artificially restrict tools (e.g.
`--allowed-tools "Skill"`) to force a test to pass. If a test fails
because Claude uses the wrong tool or spawns unnecessary subagents, the
fix belongs in the **skill content** (SKILL.md, prompt templates), not in
test constraints.

Concrete rules:

- Do not pass `allowed_tools` to `run_claude` in unit tests.
- Do not add orchestration scaffolding (retry wrappers, tool-selection
  hints) to test prompts that wouldn't exist in a real invocation.
- If a skill's SKILL.md doesn't contain enough information for Claude to
  answer a question without exploring the filesystem, **enrich SKILL.md**
  rather than restricting what tools the test can use.
- Integration tests may configure the environment as needed (worktrees,
  git setup, etc.) but should still not restrict tool availability.

### Running tests

```bash
# All unit tests
bash tests/run-all.sh

# Integration tests only
bash tests/claude-code/run-skill-tests.sh --integration

# Single test file
bash tests/claude-code/run-skill-tests.sh --test test-subagent-driven-development.sh
```
