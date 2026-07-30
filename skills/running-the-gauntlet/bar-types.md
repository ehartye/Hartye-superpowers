# Bar Types — Taxonomy, Manifest, Pass Semantics

A bar is composed of one or more typed **components**. Composite bars are the
expected case — a real UX bar is typically mockups + a practices checklist +
a thin executable floor.

## The manifest: `bar.md`

Every bar directory starts with this manifest:

```markdown
# Bar: <goal, one sentence>

**Created:** YYYY-MM-DD
**Ratified-by:** <name> on YYYY-MM-DD   # or: assumed (headless)
**Budget:** <max rounds per piece / total agent budget>

## Components

| # | Type | Artifacts | Pass condition |
|---|------|-----------|----------------|
| 1 | ux-mockup | mockups/ (see state-matrix.md) | intent parity per matrix cell |
| 2 | practices | practices-checklist.md | every item checked or deviation filed |
| 3 | executable | perf-floor.md | all thresholds met |

## Judging rubric

<how critics compare — intent parity, not pixel diffing; what counts as a
gap; scoring anchors for aspirational components>
```

Plus, as the loop runs: `ledger.md` (evidence per piece) and `deviations.md`
(filed bar disputes).

## Component types

### 1. Executable

Test suites, measurable thresholds: latency budgets, frame-rate floors,
coverage minimums, benchmark scores, a11y scanner output.

- **Artifacts:** the tests/thresholds themselves (file or doc listing exact
  commands and numbers).
- **Critic verifies by:** running them. Output goes in the ledger verbatim.
- **Pass:** binary — thresholds met or not.

### 2. Exemplar

An external reference the work is measured against: a competitor's product,
a named touchstone, real screenshots of the thing you're chasing.

- **Artifacts:** materialize the reference — 10–20 screenshots / samples into
  `reference/`, organized by scene or category. Ten minutes of collection
  buys a stable bar that isn't re-imagined every critic invocation.
- **Critic verifies by:** blind side-by-side — a screenshot of the actual
  running work next to the reference artifact, same category.
- **Pass semantics — choose one per component, in the manifest:**
  - **`parity`** — the work wins or ties the blind comparison. For bars you
    genuinely intend to reach (a competitor's settings page, a sibling
    team's dashboard).
  - **`aspirational: N`** — the critic scores each dimension on an anchored
    rubric where the reference = 10; pass at ≥ N (e.g., "ship at 6/10 across
    all dimensions, none below 5"). Use when the reference is above the
    achievable ceiling (AAA game in a browser). This converts non-convergence
    from a failure mode into the designed outcome: the loop ratchets, hits
    your ratified threshold or stalls, and either way you get scored
    side-by-sides instead of an agent looping forever on "not wowed yet."
- **Latent fallback:** naming a touchstone with no materialized artifacts
  ("Linear-level polish") is permitted only where the model's prior is dense,
  and MUST be marked `grounding: latent` in the manifest — it is the weakest
  grounding: the critic compares against memory, which drifts per invocation.
  Prefer ten screenshots.

**Stills judge stills.** Screenshot comparison judges look, composition, and
completeness — it judges motion, feel, and physics weakly. Motion targets
(games, animation-heavy UI) MUST pair an exemplar component with a thin
executable component (frame-rate floor, input-latency check) and accept that
"feel" is judged by the human at checkpoints.

### 3. UX mockup

Generated mockups of the intended UI, produced under stack grounding
(see `./bar-definition.md`), covering a **state matrix**, ratified, frozen.

- **Artifacts:** `mockups/` (one HTML/image per screen × state cell),
  `state-matrix.md` (the cell checklist), `stack-grounding.md`.
- **Critic verifies by:** launching the real app, driving it to each state,
  screenshotting, comparing against the corresponding mockup.
- **Pass:** **intent parity per cell** — layout, hierarchy, states present,
  component vocabulary, polish level. NOT pixel equality: legitimate
  rendering differences (font metrics, real data widths vs. placeholder
  text) are not gaps. A missing cell (no error state built) IS a gap — the
  matrix is the completeness measure.

### 4. Practices

Best-practices adherence for *this* stack, compiled from authoritative
sources: framework idioms, WCAG level, OWASP relevant items, lint/formatter
configs, project conventions.

- **Artifacts:** `practices-checklist.md` — every item independently
  checkable ("all interactive elements keyboard-reachable", "no secrets in
  client bundle"), with source cited per item.
- **Critic verifies by:** auditing the code/running app against each item.
- **Pass:** every item checked, or a deviation filed and human-accepted.
- Optional — leave it out deliberately for casual targets. "Janky and fun"
  is a legitimate ratified bar; omitting the practices component is the
  mechanism.

## Scaling

The contract is size-invariant; the ceremony is not. A toy bar is five
reference screenshots and a ten-line manifest, ratified in one exchange. A
product bar is a full state matrix, a practices checklist, and thresholds.
Size the bar to the blast radius, per using-superpowers right-sizing.
