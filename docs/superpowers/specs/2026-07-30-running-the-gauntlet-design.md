# Running the Gauntlet — Bar-Driven Development Design

**Date:** 2026-07-30
**Status:** Approved (designed and ratified in-session with the user)

## Problem

The existing pipeline (brainstorm → spec → plan → execute) works when "done"
is enumerable as tasks. It has no answer for goals where done is a **quality
or completeness judgment** — "as polished as X", "the UI is all there",
"adheres to our stack's best practices" — that you can only recognize by
looking, not by checking off a task list. Builders judging their own work
against a vague ideal produces "looks great, ship it."

The Gauntlet Loop technique (Shumer, July 2026) showed that a builder/blind-
critic loop against a *reference* produces honest quality ratcheting — but in
its viral form the bar lives in the critic's imagination, is renegotiated
every invocation, never converges, and has no human control point.

## Solution: materialize the bar before the loop

**One sentence:** define what done *looks like* as ratified, inspectable
artifacts before building, then loop builder/critic agents against that
frozen bar until a critic who never built the thing is satisfied — with
evidence.

This is TDD generalized to qualities tests can't express: the bar is the
failing test written first (RED); the loop runs until GREEN; the critic — not
the builder — owns the verdict. Spine fit: won't claim done without evidence
(the evidence standard is defined before work starts); won't let work drift
from the bar without a flagged deviation; reasons from independent
perspectives (blind critics with fresh context).

## The bar contract

Any bar must satisfy four invariants or the gauntlet refuses to start:

1. **Materialized** — artifacts on disk, indexed by a `bar.md` manifest in
   `docs/superpowers/bars/YYYY-MM-DD-<goal>/` (project-local, committed).
2. **Perceivable** — a critic can run it, render it, or check it. Prose
   aspirations don't qualify.
3. **Ratified** — a human approves the bar before the loop starts.
4. **Frozen** — mid-loop, the builder cannot renegotiate. "The bar is wrong"
   is a deviation filed for human resolution, never a silent redefinition.

### Bar taxonomy (variability funneled into structure)

A bar is composed of one or more typed components:

| Type | Artifact | Critic verifies by |
|---|---|---|
| Executable | test suite, thresholds | running it |
| Exemplar | materialized external reference (screenshots, samples) | blind side-by-side |
| UX mockup | screens × states matrix, stack-grounded | screenshot intent-parity vs. running app |
| Practices | stack-specific adherence checklist, each item checkable | auditing code against items |

Composite bars are the expected case. Exemplar components support two pass
semantics: **parity** (wins/ties blind A/B) and **aspirational** (scores ≥ N
on an anchored rubric where the reference = 10) — aspirational converts
non-convergence from a failure mode into a designed outcome. Exemplar allows
a latent fallback (named touchstone, no artifacts) marked `grounding: latent`
— the weakest grounding, and the manifest says so.

Judging rubric is **intent parity, not pixel diffing**. Stills judge stills:
screenshot comparison judges look/composition/completeness, not motion or
feel — motion targets pair with a thin executable component (frame-rate
floor, latency check).

## Phase 1 — bar definition

UX path (the one with teeth), in order:
1. **Stack grounding first**: inventory framework, component library, design
   tokens, platform constraints, a11y baseline, existing design language →
   `stack-grounding.md`. Prevents mockups that demand the impossible or
   violate the project's own practices.
2. **Generate mockups under the grounding** — project's component vocabulary,
   platform capabilities respected.
3. **Mini-gauntlet on the mockups** (cheap loop): harsh critic judges polish
   against a named touchstone AND feasibility against the grounding doc.
4. **State-matrix completeness**: every screen × {empty, loading, error,
   long-content, responsive, denied} — the matrix doubles as the completeness
   checklist for Phase 2.
5. **Ratification checkpoint** — human edits/vetoes, then the bar freezes.
   Present via brainstorming's visual companion when available.

Executable/Practices bars: compile + ratify. Ceremony scales down: a toy bar
is five screenshots and a ten-line manifest.

## Phase 2 — the loop

- Lead decomposes the bar into independently judgeable pieces.
- Per piece: builder agent (fresh context: goal + bar + repo) → **blind
  critic** agent (fresh context: bar + actual perceived output — runs tests,
  screenshots the running app; never sees builder narration).
- Structured verdict: `PASS` or `GAP{biggest-remaining-gap, severity,
  evidence}`; gap goes back to a builder; loop.
- **Stop conditions:** piece passes · stall rule (2 consecutive rounds
  without critic-acknowledged improvement → escalate to human with evidence)
  · budget cap from `bar.md`.
- **Deviation protocol:** infeasible bar item → `deviations.md`, human
  resolves; other pieces continue.
- **Smoothing pass:** one fresh agent checks cross-piece cohesion at the end.
- **Evidence ledger** (`ledger.md` + side-by-sides + outputs) is the input to
  verification-before-completion. No ledger, no done.
- No new orchestration machinery: dispatch uses the same Agent-tool patterns
  as subagent-driven-development.

## Pipeline integration

Brainstorming gains a fork at its terminal state (upstream divergence,
explicitly approved by the user 2026-07-30):

- **Spec path (default, unchanged):** design doc → writing-plans → execution.
- **Bar path (new):** goal + bar type → running-the-gauntlet.

Rubric: **"Can you enumerate the tasks? → plans. Can you only recognize
done? → gauntlet."** Hybrid (plan for structure + bar as exit gate) is
documented as a composition note, not built in v1.

## File layout

```
skills/running-the-gauntlet/
  SKILL.md            # when-to-use, two phases, loop rules, stop conditions
  bar-types.md        # taxonomy + required fields + pass semantics
  bar-definition.md   # Phase 1 procedure incl. UX stack-grounding + minimal example
  builder-prompt.md   # builder agent template
  critic-prompt.md    # blind critic agent template
```

Bar artifacts live in the target project (`docs/superpowers/bars/`), never in
the plugin.

## Companion workstream: multi-agent terminology refresh

Shipped separately (branch `feat/multi-agent-terminology-refresh`): retired
`TeamCreate`/`TeamDelete`/`team_name`/`shutdown_request`/
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`/Opus 4.6 gating across skills and
READMEs in favor of current primitives (Agent tool background agents,
SendMessage continuation, shared task tools); historical docs banner-marked.
The gauntlet skill is written in current vocabulary from day one.

## Rejected alternatives

- **Latent-only bars** (the viral Gauntlet Loop form): no human control
  point, bar re-imagined per invocation, only works where training data is
  dense. Kept only as the marked-weakest Exemplar fallback.
- **Two skills (defining-the-bar + running-the-gauntlet):** bar definition
  has no independent use; concept-count is a cost.
- **Hybrid exit-gate in v1:** retrofits cheaply later; validating the loop
  comes first.
