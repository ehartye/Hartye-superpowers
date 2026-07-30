# Phase 1: Defining the Bar

Output: a bar directory in the target project —

```
docs/superpowers/bars/YYYY-MM-DD-<goal>/
  bar.md                 # manifest (see bar-types.md)
  stack-grounding.md     # UX bars: the feasibility ground truth
  state-matrix.md        # UX bars: screens × states checklist
  mockups/               # UX bars: one artifact per matrix cell
  reference/             # exemplar bars: materialized reference
  practices-checklist.md # practices bars
  ledger.md              # created empty; filled during Phase 2
  deviations.md          # created empty; filled as disputes arise
```

Commit the bar directory at ratification. It is spec, not scratch.

## UX bars — the full procedure

**Order matters. Grounding comes before imagination.**

### 1. Stack grounding first

Inventory the real constraints and write `stack-grounding.md`:

- Framework and rendering platform (web/native/TUI) and what it can't do
- Component library and the project's actual component vocabulary
- Design tokens / existing design language (pull from real screens if the
  app exists — new screens must look like siblings of existing ones)
- Navigation and routing idioms already in use
- Accessibility baseline the project commits to
- Anything the practices component will forbid

This document is the feasibility ground truth. Mockups generated without it
are beautiful nonsense, and a diligent loop will chase pixel parity straight
into that wall.

### 2. Generate mockups under the grounding

Cheap static artifacts (self-contained HTML preferred — renderable and
screenshotable). Constraints:

- Use the project's actual component vocabulary — no components that don't
  exist and aren't being built
- No interactions the platform can't do
- Follow the existing design language
- Nothing the practices component forbids

### 3. Mini-gauntlet the mockups (cheap loop)

Spawn a harsh critic against the *static mockups* judging two things at once:

- **Polish** against a named touchstone ("Linear/Stripe-level") — this is
  where the latent prior is strong, so spend imagination tokens here where
  they're cheap
- **Feasibility** against `stack-grounding.md` — flag anything the stack
  can't honor

Two or three rounds is typical. The expensive Phase 2 loop should never be
the place mockup quality problems surface.

### 4. State-matrix completeness

Mockups naturally depict the happy path — populated dashboard, sunny day. An
app can reach parity with those and still be hollow. Fill `state-matrix.md`:

```markdown
| Screen | populated | empty | loading | error | long-content | responsive |
|--------|-----------|-------|---------|-------|--------------|------------|
| Timer  |    ✓      |   ✓   |    —    |   ✓   |      ✓       |     ✓      |
```

Every ✓ cell needs a mockup (or an explicit "same as X with Y" note). A `—`
is a *ratified* exclusion, decided by the human, not an omission. Add
domain-relevant columns (permission-denied, offline) as needed. The matrix
doubles as Phase 2's completeness checklist — "does this cell exist in the
real app and match" is exactly the completeness measurement.

### 5. Ratify and freeze

Present mockups + matrix + grounding to the human — via brainstorming's
visual companion when available, file paths otherwise. They edit, veto,
approve. This is the cheapest possible steering moment; the corollary is
that after approval the builder can never renegotiate — that's what
`deviations.md` is for.

On approval: fill `bar.md`, commit the bar directory.

## Exemplar bars

1. Collect 10–20 representative artifacts of the reference into `reference/`,
   organized by category (for a game: surface, flight, interior, HUD…).
2. Write the judging rubric in `bar.md`: the dimensions critics score, and
   the pass semantics — `parity` or `aspirational: N` (see bar-types.md).
3. Motion target? Add the thin executable component now (frame-rate floor,
   input latency).
4. Ratify: the human confirms the reference set and the threshold.

## Practices bars

1. Identify authoritative sources for this stack (framework docs, WCAG,
   OWASP, existing lint config, project conventions).
2. Write `practices-checklist.md`: independently checkable items only, source
   cited per item. "Follows best practices" is not an item; "no secrets in
   the client bundle (OWASP A02)" is.
3. Ratify: the human strikes items they don't want enforced.

## Executable bars

List exact commands and thresholds in the manifest. If a test suite is the
bar, the suite must exist (or be built first, under TDD) before Phase 2.

## Minimal worked example (a toy — this is deliberately small)

Goal: "a pomodoro timer page that feels cozy."

```
docs/superpowers/bars/2026-07-30-cozy-pomodoro/
  bar.md            # 12 lines: 1 ux-mockup component, budget 3 rounds/piece
  stack-grounding.md# 6 lines: vanilla HTML/CSS, system fonts, no build step
  state-matrix.md   # 1 screen × {idle, running, break, finished}
  mockups/          # 4 small HTML files
  ledger.md
  deviations.md
```

One ratification exchange ("here are 4 mockups and the matrix — good?").
Total Phase 1 cost: minutes. The contract is satisfied — materialized,
perceivable, ratified, frozen — at toy scale. Don't gold-plate small bars.
