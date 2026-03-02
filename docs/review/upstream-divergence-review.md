# Upstream Divergence Review: Hartye-superpowers vs obra/superpowers

**Date:** 2026-03-02
**Reviewers:** skills-differ, teams-reviewer, test-reviewer, consolidator
**Upstream ref:** `upstream/main` (obra/superpowers)
**Fork:** `ehartye/Hartye-superpowers` (branch `main`)

---

## Executive Summary

The Hartye-superpowers fork is a **well-organized** divergence from obra/superpowers with clean separation between identity changes, new features, and upstream improvements. The fork's primary additions -- namespace rebranding (`superpowers:` to `h-superpowers:`), the `team-driven-development` skill, and an expanded test suite -- are architecturally sound and mostly isolated.

### Overall Health: GOOD with caveats

The fork maintains clean skill separation and introduces genuinely useful features. However, it has also **removed upstream infrastructure** (Windows support, Cursor plugin, shared library) that would complicate any future upstream merge or cross-platform use.

### Top 3 Concerns

1. **Windows support is broken.** The polyglot `run-hook.cmd` wrapper was deleted, breaking all Windows installations. This wrapper was specifically added upstream to fix multiple issues (#518, #504, #491, #487, #466, #440).

2. **5 of 15 skills have zero test coverage.** `finishing-a-development-branch`, `receiving-code-review`, `verification-before-completion`, `writing-skills`, and `using-git-worktrees` lack any dedicated tests. These are production skills used in real workflows.

3. **Upstream merge path is obstructed.** The pervasive `superpowers:` to `h-superpowers:` namespace rename touches nearly every file, making cherry-picking individual improvements back to upstream difficult. Bug fixes that should be upstreamed are entangled with namespace changes.

### Key Risks

| Severity | Issue |
|----------|-------|
| HIGH | Windows support broken (polyglot wrapper deleted) |
| HIGH | `lib/skills-core.js` deleted (208-line shared library) |
| MEDIUM | Cursor support dropped (`.cursor-plugin/` deleted) |
| MEDIUM | `writing-plans` references `team-driven-development` which doesn't exist upstream |
| MEDIUM | Task-to-Agent tool dispatch change in `requesting-code-review` |

---

## Skills Divergence Table

| Skill | Exists Upstream? | Change Category | Risk Level |
|-------|-----------------|-----------------|------------|
| brainstorming | Yes | Cosmetic (description shortened, terminal state generalized) | Low |
| dispatching-parallel-agents | Yes | Behavioral (threshold 3 -> 2 for parallel dispatch) | Low |
| executing-plans | Yes | Enhancement + Namespace (added Step 0 workspace setup) | Low |
| finishing-a-development-branch | Yes | Cosmetic (added team-driven-development to "Called by") | None |
| receiving-code-review | Yes | Cosmetic (description shortened, clarifying note added) | None |
| requesting-code-review | Yes | Behavioral (Task tool -> Agent tool dispatch) | Medium |
| subagent-driven-development | Yes | Namespace only (`superpowers:` -> `h-superpowers:`) + Task->Agent change | Low-Medium |
| systematic-debugging | Yes | Cosmetic + Bug fix (removed hardcoded paths, fixed find-polluter.sh glob) | Low |
| test-driven-development | Yes | No changes (identical to upstream) | None |
| using-git-worktrees | Yes | Cosmetic (description shortened, removed brainstorming caller) | Low |
| using-superpowers | Yes | Cosmetic (description shortened) | None |
| verification-before-completion | Yes | Cosmetic (description shortened, removed upstream-specific context) | None |
| writing-plans | Yes | Enhancement + Namespace (added team-driven-development as execution option) | Medium |
| writing-skills | Yes | Cosmetic + Namespace + Bug fix (fixed numbered list, removed @ prefixes) | Low |
| **team-driven-development** | **No (fork-only)** | **New feature** (6 files, experimental, requires Opus 4.6+) | **N/A -- additive** |

### Changes Worth Upstreaming

These fork changes fix real bugs or improve the upstream codebase:

| Change | File | Type |
|--------|------|------|
| Fix glob pattern in find-polluter.sh | `skills/systematic-debugging/find-polluter.sh` | Bug fix |
| Fix frontmatter regex (optional trailing newline) | `.opencode/plugins/h-superpowers.js` | Bug fix |
| Fix numbered list (1,3,4,5,6 -> 1,2,3,4,5) | `skills/writing-skills/SKILL.md` | Bug fix |
| Remove hardcoded `/Users/jesse/` paths | `skills/systematic-debugging/*.md` | Cleanup |
| Add `\b`, `\f`, `%` to JSON escape function | `hooks/session-start.sh` | Robustness |
| Description shortening across skills | Multiple files | Cosmetic improvement |

---

## Agent Teams Separation Assessment

### Separation Quality: EXCELLENT

The `team-driven-development` skill is implemented as a **self-contained additive module**. All team-specific logic, prompts, and tooling live within `skills/team-driven-development/` (6 files). It integrates as a clean parallel execution path alongside `subagent-driven-development` and `executing-plans`.

### Cross-Contamination Points (only 2 files touched)

| File | Change | Impact |
|------|--------|--------|
| `skills/writing-plans/SKILL.md` | 4 lines added (team option in plan header + execution handoff) | Low -- additive menu option |
| `skills/finishing-a-development-branch/SKILL.md` | 1 line added (team-driven-development in "Called by" list) | Minimal -- reference only |

### Could it be cleanly removed?

**Yes.** Removal requires:
1. Delete `skills/team-driven-development/` directory
2. Remove 4 lines from `skills/writing-plans/SKILL.md`
3. Remove 1 line from `skills/finishing-a-development-branch/SKILL.md`
4. Delete related docs and tests

No code changes, no library changes, no cascading breakage. The `using-superpowers` routing skill has zero team references -- it routes via SKILL.md frontmatter, so removing the directory is sufficient.

### Integration Architecture

```
writing-plans (upstream)
    |
    |--> subagent-driven-development (upstream) --> finishing-a-development-branch
    |--> team-driven-development (NEW)          --> finishing-a-development-branch
    |--> executing-plans (upstream)              --> finishing-a-development-branch
```

No circular dependencies. Upstream skills do not depend on team-driven-development.

### Prompt Template Quality

| Template | Quality | Notes |
|----------|---------|-------|
| team-lead-prompt.md | Good | Clear separation of concerns. Missing: guidance for unresponsive teammates |
| team-implementer-prompt.md | Good | Missing: alignment with SKILL.md's lead-only assignment recommendation (prompt allows self-claiming) |
| team-reviewer-prompt.md | Excellent | "Verify, Don't Trust" principle. Clear categorization. Strongest template |

---

## Test Coverage Gaps

### Coverage Summary

| Category | Count |
|----------|-------|
| Total skills | 15 |
| Skills with unit tests | 3 (subagent-driven-dev, team-driven-dev, using-superpowers) |
| Skills with integration tests | 2 (subagent-driven-dev, team-driven-dev + worktree variant) |
| Skills with triggering tests | 6 |
| Skills with explicit request tests | 3 |
| **Skills with ZERO test coverage** | **5** |
| Total unit test assertions | ~24 |

### Skills Without Tests

| Skill | Risk | Notes |
|-------|------|-------|
| finishing-a-development-branch | High -- used as exit point for all execution paths | No tests at all |
| receiving-code-review | Medium -- core review workflow | No tests at all |
| verification-before-completion | Medium -- quality gate skill | No tests at all |
| using-git-worktrees | Low -- indirectly exercised via worktree integration test | No dedicated tests |
| writing-skills | Low -- meta-skill, rarely invoked | No tests at all |

### Missing Agent Teams Test Scenarios

1. No negative test for missing `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` env var
2. No merge conflict handling test (worktree test assumes clean merges)
3. No partial failure test (teammate crashes mid-task)
4. No 6-agent maximum enforcement test
5. No mixed-approach detection test (team + subagent anti-pattern)

### Test Infrastructure Weaknesses

- **No offline/mock mode:** Every test requires live Claude API calls (~$0.01-0.05 per unit test, much more for integration)
- **Non-deterministic:** Tests depend on Claude's natural language output matching grep patterns
- **Fragile assertions:** `grep -q` with alternation patterns (`"loop\|again\|repeat"`) can produce false positives
- **Duplicated boilerplate:** `show_output()` / `check()` / `FAILURES` pattern repeated in each test file instead of extracted to test-helpers.sh
- **Inline library testing:** OpenCode tests inline function implementations rather than importing from actual source
- **Untracked test file:** `test-team-worktree-integration.sh` is not committed

---

## Recommended Actions

### Priority 1 -- High Impact, Small Effort

| Action | Effort | Rationale |
|--------|--------|-----------|
| Commit `test-team-worktree-integration.sh` | Small | Currently untracked; should be version-controlled |
| Add offline content tests (grep-based SKILL.md verification) | Small | Instant, free, deterministic coverage for all 15 skills |
| Extract test boilerplate to test-helpers.sh | Small | Reduces duplication, improves maintainability |
| Fix implementer prompt self-claiming vs lead-only assignment inconsistency | Small | Prompt says self-claim, SKILL.md recommends lead-only |

### Priority 2 -- High Impact, Medium Effort

| Action | Effort | Rationale |
|--------|--------|-----------|
| Add unit tests for 5 untested skills | Medium | finishing-a-development-branch, receiving-code-review, verification-before-completion, using-git-worktrees, writing-skills |
| Prepare upstream PR for bug fixes (separated from namespace changes) | Medium | 3 real bug fixes should be contributed back |
| Add negative triggering tests | Medium | Verify skills are NOT triggered by unrelated prompts |
| Add team-lead unresponsive-teammate guidance | Medium | Lead prompt has no recovery path for crashed teammates |

### Priority 3 -- Strategic, Large Effort

| Action | Effort | Rationale |
|--------|--------|-----------|
| Restore Windows support (or document it as unsupported) | Large | Polyglot wrapper deletion breaks all Windows users |
| Evaluate restoring `lib/skills-core.js` or documenting its removal | Large | 208-line shared library deleted; verify nothing depends on it |
| Build upstream merge tooling (namespace-aware cherry-pick scripts) | Large | Pervasive namespace changes make cherry-picking hard |
| Add mock/stub test infrastructure for offline testing | Large | Reduces cost and improves determinism of test suite |

---

## Appendix: Non-Skill File Changes

### Deleted Upstream Files (HIGH RISK)
- `hooks/run-hook.cmd` -- Windows polyglot wrapper (breaks Windows support)
- `lib/skills-core.js` -- 208-line shared library (extractFrontmatter, findSkillsInDir, etc.)
- `.cursor-plugin/` -- Cursor IDE plugin support

### Renamed/Restructured
- `hooks/session-start` -> `hooks/session-start.sh` (with simplified error handling, JSON escape improvements)
- `.opencode/plugins/superpowers.js` -> `.opencode/plugins/h-superpowers.js` (with frontmatter regex fix)

### Identity Changes (Expected for Fork)
- `.claude-plugin/plugin.json` -- name, author, homepage, repo all updated to Hartye
- `README.md` -- Complete replacement with fork-specific content
- `RELEASE-NOTES.md` -- Upstream history replaced with fork changelog

### Additions
- `skills/team-driven-development/` -- 6 files, new experimental feature
- `docs/` -- Analysis docs, implementation summary, review docs
- `tests/` -- Team tests, test infrastructure, monitoring tools
- `.gitignore` -- Added diagrams, research-results, node_modules, *.log
