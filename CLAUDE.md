# CLAUDE.md

## Project

hartye-superpowers is a Claude Code plugin that provides workflow skills,
hooks, agents, and commands. Skills are loaded via the `Skill` tool which
reads `SKILL.md` files; sub-files like prompt templates are reference
material for real usage, not auto-loaded by the Skill tool.

## Design direction

This fork is becoming a **broad-spectrum sampler and melder** of dev-process
concepts from across the Claude Code ecosystem — not a faithful clone of
upstream. Divergence from obra/superpowers is acceptable and sometimes the
point (see `docs/research/claude-code-harness-landscape-2026-06-03.md`).

The spine that keeps breadth from becoming a junk drawer: **h-superpowers is
"the harness that validates"** — won't promote a lesson without a failing
baseline, won't claim done without evidence, won't let code drift from spec
without a diff, reasons from multiple perspectives before committing. Every
new skill/hook/agent should ladder to that spine.

The governing rule for *what to build* — **legibility and generality for a
stranger, minus the competition pressure.** Before adding anything, check:

- **Usable by someone who isn't the author?** A developer with different
  domains and habits must be able to pick it up without the author in the
  room. Don't bake in assumptions only this user would hold; keep
  user/project-specific content (e.g. captured "lessons") project-local,
  never hard-coded into the shipped plugin.
- **Generally useful, not niche to this user's skillset or focus areas.**
- **Concept-count is a cost.** Every added skill/hook/file is something a
  stranger must learn. Favor fewer, legible concepts; reuse existing
  surfaces (CLAUDE.md/MEMORY.md) and compose with installed sibling plugins
  rather than reinventing.
- **NOT** justified by competition: "to look current next to X", "a niche
  nobody else fills", or feature-parity for its own sake are not reasons.
  This is not a popularity contest. Utility and legibility are the tests.

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

## Remotes and PRs

This fork has two remotes that matter:

- **Our remote (push target):** `https://github.com/ehartye/Hartye-superpowers`
- **Upstream (read-only, source of design intent):** `https://github.com/obra/superpowers`

`gh pr create` defaults to targeting the fork-parent repo, not the user's
fork. From this repo, that default is `obra/superpowers` — not what we
almost always want. Always pass `--repo ehartye/Hartye-superpowers` when
creating PRs against our fork.

**Before submitting any PR to `obra/superpowers`:**

- Get explicit, in-conversation user approval. General prior authorization
  does not count — each upstream PR needs specific sign-off for that
  specific PR.
- Confirm the content actually belongs upstream (generally-useful, not
  fork-specific, matches their design philosophy, fills their PR template
  if they have one).
- Be aware that upstream is sensitive about accidental or low-quality
  agent-submitted PRs. They've publicly called them "slop" and close them
  within hours. An accidental PR to obra burns both the user's reputation
  and upstream maintainer time.

A prior session accidentally submitted a PR to `obra/superpowers` that
should have gone to our fork. Don't repeat that.

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
