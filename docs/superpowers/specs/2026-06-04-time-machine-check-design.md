# Time-Machine Check + Spike-Checkpoint — Design

## Status
Approved (brainstormed 2026-06-04)

## Problem

Right-sizing (the altitude-router) lets the agent skip design ceremony on tasks
that look "Quick." The failure mode it introduces: a task *looked* Quick, the
agent built for momentum, and only later is it clear the task was bigger and
deserved design. Without a recovery move, sunk cost pushes the agent to keep
going on the under-designed path. We need a cheap, reliable way to (a) notice
the drift mid-flight and (b) recover gracefully — turning a mis-size from a
failure into a productive spike.

## Core idea

Two pieces, cleanly separated:

1. **`time-machine-check`** — a *reusable* reflective-checkpoint skill. Given a
   baseline SHA and an evaluation narrative, it measures drift and runs a
   prospective-hindsight reflection ("if you had a time machine, would you do it
   differently?"), returning a verdict `{on-track | diverged}` plus rationale.
   **It does not decide the response — the caller does.** Portable across
   contexts via the `narrative` parameter.
2. **Spike-checkpoint** — *one caller* of that skill, wired into right-sizing.
   When the agent explicitly chooses the no-design path it marks a baseline,
   builds, runs `time-machine-check` at natural beats, and on `diverged` runs a
   retreat: capture lessons → stash the spike (keep, not delete) → full or
   surgical rollback → reimplement under TDD.

## Components

### A. Executable: `drift` (deterministic, unit-testable)

A thin git wrapper with no judgment, cross-platform (bash + PowerShell parity,
matching the repo's existing hook/script convention — implementation to confirm
the convention; a single Python script is an acceptable alternative).

- `drift mark [label]` — record `git rev-parse HEAD` to
  `.superpowers/drift/<label|baseline>` (gitignored); warn if
  `git status --porcelain` is non-empty (baseline won't cleanly isolate later
  work); print the SHA.
- `drift measure <sha> [--files N] [--lines M]` — `git diff --shortstat <sha>`
  → parse `files_changed`, `insertions`, `deletions`;
  `crossed = files_changed >= N OR (insertions + deletions) >= M`;
  defaults `N=4`, `M=150`. Print a one-line human reading **and** a
  machine-readable form (e.g. `files=6 lines=210 crossed=true`).

### B. Skill: `time-machine-check` (reusable)

- **Inputs:** `sha` (required), `narrative` (required; default = the time-machine
  framing below), optional `files` / `lines` threshold overrides.
- **Procedure:** run `drift measure <sha>` → present the reading *together with*
  the narrative → the agent answers honestly → return verdict
  `{on-track | diverged}` + one-line rationale.
- **Boundary:** the skill returns a verdict; it never acts on it. The caller owns
  the response.
- **Default narrative:** "Is this going how we thought? If you had a time machine,
  would you go back and design it first?"

### C. Caller: spike-checkpoint (in the right-sizing content)

Lives with the altitude-routing material (using-superpowers → Right-Sizing /
brainstorming). Behavior:

1. **Explicit start:** when the agent *consciously* takes the no-design path, run
   `drift mark` to record a clean baseline. (Explicit, not automatic — decided.)
2. **Build directly**, under the non-negotiable discipline (TDD / debugging /
   verification).
3. **At natural beats** (finished a chunk · hit friction · about to claim done),
   call `time-machine-check(sha=baseline, narrative=<spike framing>)`.
4. **On `diverged` → retreat:**
   a. **Capture lessons FIRST** (before touching the tree): 3–5 bullets — what
      made it bigger, the real shape, the trigger to recognize next time.
   b. **Stash, don't delete:** `git stash push -u -m "spike: <task> @ <sha7>"`.
      The spike stays a recoverable reference.
   c. **Choose granularity** from `git diff <baseline> --stat`:
      **full** (clean tree → design → reimplement) or **surgical** (restore
      baseline, cherry-pick the genuinely-clean keepers out of the stash).
   d. **Reimplement under TDD regardless** — the guardrail that stops spike code
      from silently shipping. The stash may be referenced; the real
      implementation is test-first.
5. **On `on-track` → continue.**

## State & data

- `.superpowers/drift/baseline` — baseline SHA + label + timestamp. `.superpowers/`
  is already gitignored.
- `git stash` — the preserved spike.
- No daemon, no hook, no external DB. Pull-invoked and git-native.

## Defaults

`files = 4` (primary signal — breadth across files/subsystems is the real "it
grew" tell), `lines = 150` (backstop for the slow boil). Tunable via flags. To be
calibrated empirically later (crucible, once its testing gaps — issues #8/#9/#10
— are addressed).

## Non-goals (v1)

- **No PostToolUse/Stop hook** — pull-only, explicit start. A hook backstop is a
  possible later add *if* explicit beats get skipped in practice.
- **No auto-enforcement / auto-rollback** — the agent always decides.
- **Other callers not wired yet** — the skill is built to be reusable
  (executing-plans: "still matches the approved plan?"; systematic-debugging:
  "converging or thrashing?"), but only the spike-checkpoint caller ships in v1.

## Testing

- **`drift` script:** unit tests against a scratch git repo — `mark` records the
  SHA and warns on a dirty tree; `measure` parses `--shortstat`, applies the
  threshold logic, and reports `crossed` correctly on synthetic diffs.
  Deterministic, spends no tokens.
- **`time-machine-check` skill:** behavioral check that it invokes `measure`,
  surfaces reading + narrative, and returns a structured verdict. Per the repo's
  testing rules, enrich SKILL.md rather than constraining tools to force a pass.
- **Cross-platform parity** (bash + PowerShell) per repo convention.

## Risks / open

- **Explicit start relies on the agent marking** at the no-design decision.
  Accepted for v1 (it's the conscious moment); revisit with a nudge if skipped.
- **Threshold defaults are guesses** — calibrate later.
- **Naming** (`drift`, `time-machine-check`) and exact file locations are
  adjustable during implementation.

## Relationship to the altitude-router

This is the safety net that makes right-sizing *safe to be wrong* — the retreat
path of the v2 escalation model, made concrete and recoverable. It lowers the
stakes on the v1-vs-v2 routing-accuracy question: mis-sizing becomes recoverable,
even productive (lessons captured), rather than a failure. See
`docs/research/altitude-router-routing-eval.md` for the routing eval that
motivated it.
