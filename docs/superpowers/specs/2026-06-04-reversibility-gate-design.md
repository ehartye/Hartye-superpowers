# Reversibility-Centered Right-Sizing Gate — Design

## Status
Approved (brainstormed 2026-06-04). Refines the v2 escalation-trigger gate;
pairs with and depends on the spike-checkpoint / time-machine-check feature
(`docs/superpowers/specs/2026-06-04-time-machine-check-design.md`).

## Problem

The current (v2) gate escalates to design when ANY of four triggers fires —
multiple subsystems, ambiguous requirements, hard-to-reverse, or user-asks — and
treats them as equal *upfront* gates. But the spike-checkpoint now makes
**reversible** mis-sizing cheaply recoverable (act → drift reading → roll back
the spike → redesign). So gating reversible ambiguity or modest size *upfront* is
wasted prevention: you can recover from those. The decision should turn on what
the time machine **cannot** undo.

## Decision (Option A — reversibility + obvious-size)

Reframe the gate around one question: **if this goes wrong, can a `git` rollback
fully undo it?**

- **Reversible (yes) → act now.** One-line intent, implement under the discipline,
  arm the spike-checkpoint. A wrong call is recoverable. Do NOT pre-design
  reversible work just because it's unclear or has a few moving parts.
- **Irreversible / destructive (no) → design upfront, always.** The time machine
  can't save you. The operational test: *the harm escapes the git working tree.*
  Covers:
  - persisted-data changes / schema migrations
  - deleting or overwriting data, files, or history git can't restore
    (force-push, history rewrite, data drops)
  - changing a published / public contract others already depend on
    (public API, released package)
  - external side effects (payments, emails/notifications, third-party API calls)
  - security, auth, secrets, or crypto
- **Obviously large / multi-subsystem → design upfront** — not because it's
  irreversible, but because spiking a known-big effort wastes the spike (drift
  trips almost immediately, rolling back a lot). Design the elephant; don't spike it.
- **User explicitly asks to design** (e.g. invokes brainstorming directly) →
  honor it, design scaled to complexity. This is a different *entrance*, not a
  gate trigger: right-sizing decides ceremony only when the agent *detects*
  creative work.

**Key change vs v2:** "ambiguous requirements" is **demoted** — it no longer
gates reversible work upfront. Make a reasonable assumption, act, and let the
checkpoint catch a wrong one. "Obviously large" and "irreversible" remain upfront
gates.

**Discipline — unchanged, never skipped at any size:** test-driven-development,
systematic-debugging, verification-before-completion.

## Affected surface

- `skills/using-superpowers/SKILL.md` — replace the `## Right-Sizing Process`
  body with the reversibility framing above; lightly reword the existing
  `### Spike-checkpoint` subsection to say "reversible work" / "arm the checkpoint."
- `skills/brainstorming/SKILL.md` — the `<HARD-GATE>` becomes: escalate when
  irreversible/destructive OR obviously-large OR user-asks; else act + arm the
  checkpoint; never stall headless. Reword the anti-pattern section to
  "Mis-sizing the ceremony" framed on reversibility + blast radius (a three-line
  migration is not Quick — you can't un-migrate).

These three are currently in v2 form on branch `feat/time-machine-check`; this
redesign edits them in place.

## Testing

- **Deterministic structural lint** (`tests/unit/`, no tokens): assert the
  Right-Sizing section and HARD-GATE contain the load-bearing pieces — the
  reversibility question ("can a `git` rollback fully undo it"), the irreversible
  list (migrations, external side effects, security), the "obviously large"
  override, and the unchanged discipline spine. Guards against future edits
  silently dropping the irreversible gate.
- **Routing behavior** is already validated in principle by
  `docs/research/altitude-router-routing-eval.md`; optionally extend that eval
  later with reversible-vs-irreversible cases. Not required for this change
  (token-spending, deferred).

## Non-goals

- No new triggers beyond the approved list; no auto-enforcement; no change to the
  spike-checkpoint mechanism itself (already built).
- Not wiring a hook — the gate is prose the agent applies; the checkpoint is
  pull-invoked.

## Risks / open

- "Irreversible" must be unambiguous — it's the load-bearing safety the time
  machine can't replace. The operational test (harm escapes a git rollback) plus
  the example list is the mitigation; the structural lint pins the list in place.
- Demoting ambiguity means an ambiguous-but-reversible task built on a wrong
  assumption wastes effort until the checkpoint catches it. Accepted: that waste
  is bounded and recoverable, which is the whole point.
- Both "irreversible" and "obviously large" remain agent judgments; the
  reliability of the recovery net still depends on the checkpoint actually being
  run at beats (a known property of the time-machine-check feature).

## Relationship to v1-vs-v2

This supersedes the v1-vs-v2 question: we commit to a **reversibility-centered
refined v2**. v1's three-tier classify-first is dropped; the gate is now a single
reversibility test plus two overrides, backed by recovery.
