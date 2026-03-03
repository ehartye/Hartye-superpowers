# Consolidated Plugin Review — 2026-03-02

> 5-agent review team: code quality, skill definitions, test suite, documentation, architecture

## Executive Summary

**Total findings: 60** across 5 review domains.

| Domain | Critical | High | Medium | Low/Info |
|--------|----------|------|--------|----------|
| Code Quality | 0 | 2 | 2 | 10 |
| Skill Definitions | 1 | 4 | 6 | 5 |
| Test Suite | 0 | 4 | 7 | 7 (+5 coverage gaps) |
| Documentation | 0 | 3 | 4 | 4 |
| Architecture | 0 | 1 | 1 | 6 |
| **Totals** | **1** | **14** | **20** | **32** |

---

## Top Priority Items (Critical + High)

### CRITICAL

**C1. Mismatched placeholder in requesting-code-review** (skills-reviewer)
- `skills/requesting-code-review/SKILL.md:35` uses `{PLAN_OR_REQUIREMENTS}` but `code-reviewer.md:18` uses `{PLAN_REFERENCE}`. Callers following SKILL.md produce an unfilled placeholder.
- **Fix:** Align both files to use the same placeholder name.

### HIGH

**H1. stderr mixed into JSON content** (code-reviewer)
- `hooks/session-start.sh:18` — `2>&1` redirects OS errors into the content variable, corrupting JSON output.
- **Fix:** Change to `2>/dev/null`.

**H2. printf vulnerable to % in skill content** (code-reviewer)
- `hooks/session-start.sh:39` — If skill content contains `%` characters, printf will misinterpret them as format specifiers.
- **Fix:** Add `s="${s//\%/%%}"` to `escape_for_json()`, or switch to heredoc output.

**H3. Integration tests never wired into top-level runner** (test-reviewer)
- `tests/run-all.sh` has no `--integration` flag; the 3 key integration tests are invisible to CI.
- **Fix:** Add `--integration` flag forwarding to `run-skill-tests.sh`.

**H4. Orphaned test suites not invoked** (test-reviewer)
- `tests/explicit-skill-requests/run-all.sh` — `set -e` only (no `-u`/`pipefail`), never invoked from top-level runner.
- `run-multiturn-test.sh`, `run-extended-multiturn-test.sh`, `run-haiku-test.sh`, `run-claude-describes-sdd.sh` are completely orphaned.
- **Fix:** Integrate into `run-all.sh` or document as manual-only.

**H5. Deprecated `--dangerously-skip-permissions` flag** (test-reviewer)
- `tests/subagent-driven-dev/run-test.sh:76` uses the old flag while integration tests use `--permission-mode bypassPermissions`.
- **Fix:** Standardize on `--permission-mode bypassPermissions`.

**H6. Multiturn tests orphaned from run-all** (test-reviewer)
- 4 test scripts in `tests/explicit-skill-requests/` are never called by any runner.
- **Fix:** Integrate or document as manual-only.

**H7. README install commands don't match marketplace.json** (docs-reviewer)
- README says `ehartye/Hartye-superpowers` but marketplace.json has `"name": "superpowers-dev"` with local source `"./"`. Install commands are unverifiable.
- **Fix:** Clarify install path or align names.

**H8. Wrong plugin filename in OpenCode docs** (docs-reviewer)
- `docs/README.opencode.md:261,286` references `superpowers.js` but actual file is `h-superpowers.js`.
- **Fix:** Update to `h-superpowers.js`.

**H9. FUNDING.yml points to upstream author** (docs-reviewer)
- `.github/FUNDING.yml` sponsors `obra` (Jesse Vincent) not `ehartye` (Eric Hartye).
- **Fix:** Change to `github: [ehartye]` or remove.

**H10. using-superpowers description violates its own CSO rules** (skills-reviewer)
- Description summarizes what the skill does instead of when to trigger it.
- **Fix:** Rewrite to `Use at the start of any task or conversation to decide which skills to invoke before acting`.

**H11. Informal heading in systematic-debugging** (skills-reviewer)
- `skills/systematic-debugging/SKILL.md:234` — "your human partner's Signals You're Doing It Wrong" is informal for a section heading.
- **Fix:** Rephrase to `## Warning Signs From Your Human Partner`.

**H12. ~~init-team.sh path reference misleading~~ Resolved** (skills-reviewer)
- `init-team.sh` removed — team initialization now uses native `TeamCreate` tool.

**H13. Writing-skills SKILL.md numbering gap** (skills-reviewer)
- Lines 638-644 jump from step 1 to step 3.
- **Fix:** Add missing step 2 or renumber.

**H14. plugin.json has no skills registration array** (arch-reviewer)
- 15 skills exist but none are enumerated in the manifest. If Claude Code requires explicit registration, all skills are silently unregistered.
- **Fix:** Verify plugin spec; add skills array if required.

---

## Medium Severity

| # | Domain | File | Issue |
|---|--------|------|-------|
| M1 | Code | `session-start.sh:39` | printf format string vulnerable to `%` in content |
| M2 | Code | `h-superpowers.js:17` | CRLF line endings break frontmatter parsing |
| M3 | Code | `h-superpowers.js:51` | Skills dir resolution assumes fixed directory depth |
| M4 | ~~Code~~ | ~~`init-team.sh:42-46`~~ | ~~No `--force` flag for reinitializing teams~~ Resolved — file removed, using native `TeamCreate` |
| M5 | Skills | `brainstorming/SKILL.md:55` | References non-existent skills (frontend-design, mcp-builder) |
| M6 | Skills | `receiving-code-review/SKILL.md` | "your human partner" never defined |
| M7 | Skills | `verification-before-completion/SKILL.md:113` | "From 24 failure memories" unexplained jargon |
| M8 | Skills | `condition-based-waiting.md:82` | References possibly missing example file |
| M9 | Skills | `root-cause-tracing.md:106` | References `find-polluter.sh` — may not exist |
| M10 | Skills | `writing-skills/SKILL.md:316,318` | Broken refs to `graphviz-conventions.dot`, `render-graphs.js` |
| M11 | Tests | `test-helpers.sh:37` | Retry logic doesn't log exit codes |
| M12 | Tests | `test-helpers.sh:73-89` | `assert_not_contains` passes on empty output |
| M13 | Tests | `test-using-superpowers.sh` | Early-exit on first failure (no accumulation) |
| M14 | Tests | `test-team-dev-integration.sh:371` | Unquoted `$ALL_SESSION_FILES` |
| M15 | Tests | `analyze-token-usage.py:77-82` | Uses Sonnet pricing for Opus runs (5x off) |
| M16 | Tests | `test-sdd-integration.sh:204` | Claude exit code not captured |
| M17 | Tests | `skill-triggering/run-all.sh:36` | `tee` swallows test exit codes without pipefail |
| M18 | Docs | `docs/testing.md` | Missing `test-team-worktree-integration.sh` from structure tree |
| M19 | Docs | `docs/IMPLEMENTATION-SUMMARY.md:213` | Mixed pending/validated status signals |
| M20 | Docs | `docs/review/documentation-review.md` | Stale finding never marked resolved |
| M21 | ~~Docs~~ | ~~`docs/review/architecture-review.md:267`~~ | ~~init-team.sh exists now; finding partially stale~~ Resolved — Gap 3 updated, init-team.sh removed |
| M22 | Arch | `lib/skills-core.js` | Dead library — not imported anywhere in active code |

---

## Low Severity & Informational (summary)

- **Code (10):** Regex too restrictive for YAML keys, off-by-one depth check, naming inconsistency, `BASH_SOURCE` fallback unnecessary, hook matcher overly broad, no hook timeout, hardcoded Git Bash path, deprecated `run-hook.cmd` kept, `_input` param unused, `||=` operator requires Node 15+
- **Skills (5):** Emoji in team templates, TypeScript pseudocode in language-agnostic skill, missing worktree pre-step in executing-plans, verbose agent description, imperative command description
- **Tests (7+5):** README example uses wrong API, docs template uses wrong pattern, monitor prefix matching too strict, hardcoded plugin path, no automated assertions in subagent-driven-dev, narrow regex matching, misleading flag name. **Coverage gaps:** No tests for using-git-worktrees, writing-plans, negative triggering, plugin loading in Claude Code, team size enforcement.
- **Docs (4):** Analysis doc references wrong filenames, no fork-specific release notes, unreferenced polyglot docs, outdated cost estimates
- **Architecture (6):** Deprecated `run-hook.cmd` should be deleted, `research-results/` should be gitignored, `.gitignore` missing common patterns, only 3/15 skills have command shortcuts, duplicated frontmatter parsers, hook matcher semantics unclear

---

## Recommended Fix Priority

### Batch 1 — Quick wins (< 5 min each)
1. Fix `session-start.sh` stderr redirect (`2>&1` → `2>/dev/null`)
2. Fix placeholder mismatch in requesting-code-review
3. Fix `FUNDING.yml` author
4. Fix `README.opencode.md` filename references
5. Add `research-results/` and `.DS_Store` to `.gitignore`
6. Fix writing-skills numbering gap
7. Fix using-superpowers description

### Batch 2 — Targeted fixes (15-30 min each)
8. Harden `escape_for_json()` against `%` characters
9. Add CRLF handling to OpenCode frontmatter parser
10. Wire integration tests into `run-all.sh`
11. Fix `assert_not_contains` empty-output false positive
12. Add `set -euo pipefail` to orphaned test runners
13. Standardize `--permission-mode bypassPermissions` everywhere
14. Resolve or remove broken file references in skills (items M8-M10)

### Batch 3 — Larger efforts
15. Decide fate of `lib/skills-core.js` (delete or integrate)
16. Delete deprecated `run-hook.cmd`
17. Add fork-specific release notes section
18. Verify plugin.json skill registration requirements
19. Add missing test coverage (5 gaps)
20. Update stale review docs or archive them
