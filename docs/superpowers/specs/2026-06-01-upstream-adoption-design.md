# Upstream Adoption Design Spec

**Date:** 2026-06-01
**Author:** Eric Hartye (with Claude)
**Status:** Draft — pending user review

## Goal

Selectively adopt skill-content improvements that landed in
`obra/superpowers` between this fork's divergence point (**v4.3.0**,
2026-02-12) and **v5.1.0** (2026-05-04), while preserving deliberate
fork-specific design choices. Cross-harness portability work
(Codex/OpenCode/Copilot/Gemini/Antigravity), contributor governance
(PR/issue templates, Code of Conduct), and Discord/README changes are
explicitly **out of scope**.

## Background

The fork branched from upstream at v4.3.0. Upstream has since shipped
v5.0.0 → v5.1.0. Most of the ~163 intervening commits are cross-harness
or governance changes irrelevant to a Claude-Code-only fork. This spec
captures the subset of skill-content changes worth adopting, the
fork-only divergences worth keeping, and the decisions made walking
through each candidate one by one.

Key shared-heritage fact established during review: the **two-stage
review** (spec compliance → code quality) in `subagent-driven-development`
is **not** a fork invention — it was authored upstream by Jesse Vincent
on 2025-12-17, before the fork point. Both sides share it.

## Decisions

Each item below is a self-contained unit of work. Items are independent
except where noted (item 7 → item 6 cascade; item 4 mirrors into
team-driven).

---

### Item 1 — Doc path consistency cleanup

**Status:** Already adopted in primary skills; clean up stragglers.

The fork already uses `docs/superpowers/specs/` (brainstorming) and
`docs/superpowers/plans/` (writing-plans). Three stale `docs/plans/`
references remain and must be aligned:

- `skills/subagent-driven-development/SKILL.md:108` —
  `[Read plan file once: docs/plans/feature-plan.md]`
- `skills/requesting-code-review/SKILL.md:61` — example
  `docs/plans/deployment-plan.md`
- `skills/team-driven-development/SKILL.md:127` —
  `[Read plan file once: docs/plans/feature-plan.md]`

**Action:** Replace each with the `docs/superpowers/{plans,specs}/` form
appropriate to context (plan-reading refs → `docs/superpowers/plans/`).

---

### Item 2 — requesting-code-review: keep custom agent, add praise rationale

**Decision:** SKIP upstream's architectural restructure; ADAPT one line.

Upstream deleted its `agents/code-reviewer.md` and folded the reviewer
into an inline `general-purpose` Task prompt — a **portability-driven**
change (other harnesses lack custom agent types). The fork's registered
`code-reviewer` custom agent (`model: inherit`) is the more native
Claude Code design and already has full content parity:

- deviation flagging — `agents/code-reviewer.md:42`
- flag issues with the plan itself — `agents/code-reviewer.md:44`
- praise-first — `agents/code-reviewer.md:45`
- DO/DON'T rules + "not everything is Critical" —
  `skills/requesting-code-review/code-reviewer.md:96-108`

**Action:** Keep the custom agent and template as-is. Add upstream's
*rationale* for praise-first to `agents/code-reviewer.md` (~line 45):
e.g. "Always acknowledge what was done well before highlighting issues —
accurate praise helps the implementer trust the rest of the feedback."

---

### Item 3 — writing-plans: File Structure + checkbox steps + Scope Check

**Decision:** ADOPT three additions. (No-Placeholders and the enhanced
Self-Review are already present in the fork.)

**3a. File Structure section** (new, place before "Task Structure"):
Map which files will be created/modified and each one's responsibility
before defining tasks. Design units with clear boundaries and one
responsibility each; prefer smaller focused files; files that change
together live together (split by responsibility, not technical layer);
in existing codebases follow established patterns and don't unilaterally
restructure.

**3b. Checkbox step syntax:** Change the task template steps from
`**Step 1:**` to `- [ ] **Step 1:**` and add a header note: "Steps use
checkbox (`- [ ]`) syntax for tracking."

**3c. Scope Check section** (new): "If the spec covers multiple
independent subsystems, it should have been broken into sub-project specs
during brainstorming. If it wasn't, suggest breaking this into separate
plans — one per subsystem. Each plan should produce working, testable
software on its own." (Pairs with item 5's decomposition guidance.)

---

### Item 4 — subagent-driven-development (+ mirror into team-driven)

**Decision:** ADOPT all four additions in `subagent-driven-development`,
then mirror each — *adapted* to the teammate/messaging model — into the
fork-only `team-driven-development`.

**4A. Why-subagents framing** (near top): concise statement that you
delegate to specialized agents with isolated context; they never inherit
session history; this also preserves the controller's context.

**4B. Continuous-execution rule** (Hard Rules): don't pause to ask
"should I continue?" between tasks; only stop on unresolvable BLOCKED,
genuine ambiguity, or completion. (Matches the fork's already-continuous
flow.)

**4C. Model Selection section:** cheap model for mechanical 1–2 file
tasks with complete specs; standard model for multi-file integration;
most-capable model for architecture/design/review.

**4D. Four-status protocol:** implementer reports one of DONE /
DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED, with controller handling
for each (proceed; read concerns then proceed-or-fix; provide context and
re-dispatch; assess blocker → more context / escalate model / split task
/ escalate to human). "Never force the same model to retry without
changes." Requires edits to **both** `SKILL.md` (new "Handling
Implementer Status" section) **and** `implementer-prompt.md` (so the
subagent emits a status; replaces the current free-form "Any issues or
concerns" reporting).

**Mirroring into team-driven:** adapt 4A → "why teammates" (persistent
collaborators); 4B → "keep pulling tasks from the shared list" rather
than "don't pause between dispatches"; 4C → per-teammate-role model
choice; 4D → statuses reported via `SendMessage` + shared task-list
updates rather than return values; mirror the `implementer-prompt.md`
edit in `team-driven-development/`.

**Prompt-file drift:** while editing, cherry-pick non-conflicting wording
improvements from upstream's drifted `spec-reviewer-prompt.md`,
`code-quality-reviewer-prompt.md`, and `implementer-prompt.md`.

**Note:** team-driven-development is fork-only (no upstream counterpart),
so it must be hand-maintained in parity with subagent-driven going
forward.

---

### Item 5 — brainstorming: decomposition + isolation guidance

**Decision:** ADOPT three new sections. (Visual companion, spec
self-review — enhanced with a YAGNI check + calibration — and the user
review gate are already present in the fork.)

**5a. Scope/decomposition guidance** (in "Understanding the idea"): flag
multi-subsystem requests before spending clarifying questions; help
decompose into sub-projects, each getting its own spec → plan → impl
cycle. (Pairs with item 3c Scope Check.)

**5b. Design for isolation and clarity** (new section): break the system
into small units with one clear purpose, well-defined interfaces, and
independent testability; for each unit be able to state what it does, how
to use it, and what it depends on. (Design-level pair of item 3a File
Structure.)

**5c. Working in existing codebases** (new section): explore the current
structure first and follow existing patterns; include targeted
improvements where existing problems affect the work, but no unrelated
refactoring.

---

### Item 6 — finishing-a-development-branch (native-first teardown)

**Decision:** REVISED for native-first worktrees (see item 7). Primary
teardown via `ExitWorktree`; manual `git worktree remove` retained only
as the fallback path.

**6a. Native teardown mapping** (`ExitWorktree` is session-scoped and
only touches worktrees created by `EnterWorktree` this session, so it is
inherently safe):
- Option 1 (merge locally): merge/verify in main repo → `ExitWorktree`
  with `action: "remove"`.
- Option 2 (push + PR): `ExitWorktree` with `action: "keep"` (or leave
  in place) — branch still active.
- Option 3 (keep as-is): `ExitWorktree` with `action: "keep"`.
- Option 4 (discard): after typed confirmation, `ExitWorktree` with
  `action: "remove"`, `discard_changes: true`.

**6b. Obsolete — do NOT adopt:** upstream's path-based provenance
allowlist and the previously-considered sibling-`<repo>-worktrees/`
allowlist. `ExitWorktree`'s session-scoping makes path provenance
unnecessary; the sibling-dir requirement is dropped (see item 7).

**6c. KEEP from upstream/fork (manual-git fallback path only):**
- Detached-HEAD / externally-managed detection → reduced 3-option menu
  (no local-merge) for non-native worktrees. Environment detection via
  `GIT_DIR` vs `GIT_COMMON`.
- Merge-before-cleanup ordering fix: operate in the **main repo**
  (checkout base in main → merge → verify → remove worktree → then delete
  branch), not inside the feature worktree.
- Existing CWD safety (`cd` to main before `git worktree remove`) and
  preserve-on-PR/keep behavior — retained for the fallback path.

**6d. Cascade (folded in):** update the worktree references and manual
`git worktree remove` CWD warnings in `subagent-driven-development`,
`team-driven-development`, and `executing-plans` to defer teardown to
this skill (which now uses `ExitWorktree`).

---

### Item 7 — using-git-worktrees (native-first rewrite)

**Decision:** GO NATIVE-FIRST. Rewrite around `EnterWorktree` as the
primary mechanism; retire the manual directory-selection +
gitignore-verification machinery and the sibling-`<repo>-worktrees/`
requirement (user waived it).

**7a. Primary path:** use `EnterWorktree` (creates under
`.claude/worktrees/`, switches the session in). Mention `worktree.baseRef`
(`fresh` = branch from `origin/<default-branch>`, the default; `head` =
branch from local HEAD) so users can configure base-ref behavior.

**7b. Step 0 — detect existing isolation (KEEP):** before creating, check
`GIT_DIR` vs `GIT_COMMON`; if already in a linked worktree (including a
native `.claude/worktrees/` one), do not create another. Submodule guard
via `git rev-parse --show-superproject-working-tree` to avoid mistaking a
submodule for a worktree.

**7c. Fallback path:** manual `git worktree add` only when the native
tool is unavailable; non-git repositories are handled by `EnterWorktree`'s
hook delegation. Sandbox/permission denial → report and work in place.

**7d. Retire:** project-local vs global directory selection, the
`.worktrees/`/`worktrees/` precedence logic, gitignore verification, and
sibling-dir support — these are subsumed by the native tool.

**7e. Gating consideration:** `EnterWorktree` only fires when worktree
use is "explicitly instructed" by the user or by CLAUDE.md/memory. The
spec/implementation must ensure the fork's CLAUDE.md (or the skill's own
announced flow) makes worktree usage explicit enough to satisfy this
gate; otherwise the execution skills that require isolation won't trigger
creation.

**7f. Cascade (folded in):** see item 6d — execution skills' "set up
workspace" steps now mean `EnterWorktree`.

---

### Item 8 — executing-plans (inline reframe)

**Decision:** ADOPT upstream's inline reframe; drop the separate-session
flow.

- Rewrite the process from batch-of-3 + "Ready for feedback" checkpoints
  to **execute all tasks → report when complete** (the no-subagent
  fallback).
- Update the skill description (line 3) to remove "in a separate session
  with review checkpoints."
- In `writing-plans`, rename execution option 3 from "Parallel Session
  (separate) — Open new session" to "Inline Execution — this session
  using executing-plans."
- Add upstream's note that the workflow is significantly better with
  subagents (prefer `subagent-driven-development` when available).
- The fork retains its three-way handoff: subagent-driven (recommended),
  team-driven (experimental), inline execution.

---

## Out of Scope

- Cross-harness porting (Codex, OpenCode, Copilot CLI, Gemini,
  Antigravity), `hooks-cursor.json`, session-start rewrites.
- Contributor governance: PR/issue templates, Code of Conduct,
  Discord/README changes. (The fork already encodes equivalent
  anti-slop / upstream-PR guardrails in CLAUDE.md.)
- Upstream's inline `general-purpose` code-reviewer restructure (item 2
  rejected in favor of the custom agent).

## Testing / Verification

- Existing unit + integration tests must continue to pass:
  `bash tests/run-all.sh` and the integration suite. Per project rules,
  do not restrict tool availability in tests; if a skill change breaks a
  test because Claude picks the wrong tool, enrich the skill content
  rather than constraining the test.
- For native-worktree behavior (items 6/7), integration tests may
  configure the environment (git setup) but must not restrict tools.
- Manually validate the brainstorming → writing-plans → execution →
  finishing flow end-to-end once, exercising `EnterWorktree`/
  `ExitWorktree`.

## Resolved Questions

- **Item 7e (resolved):** `EnterWorktree`'s "explicit instruction" gate is
  satisfied by the **Step 0 consent prompt** (or a worktree preference
  already declared by the user or in CLAUDE.md/memory) — the user agreeing
  to the worktree IS the explicit instruction. This matches upstream's
  framing ("The user has asked for an isolated workspace (Step 0 consent)").
  No line in this repo's CLAUDE.md is needed — and would not help anyway,
  since a plugin's own CLAUDE.md is not loaded when the plugin runs inside
  an end-user's project (only the user's project/global CLAUDE.md is). The
  `using-git-worktrees` Native-tool section was corrected to attribute the
  gate to consent/declared-preference rather than to the skill "announcing"
  the worktree step (announcing alone does not satisfy the gate).
