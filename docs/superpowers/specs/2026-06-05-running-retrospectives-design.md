# running-retrospectives — Design

## Status
Approved (brainstormed 2026-06-05). Implements Rec 2 of
`docs/research/claude-code-harness-landscape-2026-06-03.md` (formerly
"harvesting-lessons"). Storage/retrieval settled separately in
`docs/decisions/2026-06-05-harvesting-lessons-storage.md` — this design depends
on it and does not re-litigate it.

## Problem

h-superpowers has no way to turn a recurring correction into durable, trusted
guidance. The user corrects the agent ("run the suite before claiming done",
"stop assuming I want X", "don't refactor adjacent code") and the same mistake
returns in a later session. Competing harnesses (claude-reflect, ECC) capture and
re-inject corrections, but they promote on recurrence alone — no proof the lesson
actually changes behavior. For a fork whose spine is **"the harness that
validates,"** promoting an unproven prose lesson into always-loaded memory is the
worst case: a confident wrong instruction injected every session.

The defensible move is **validated learning**: a lesson is promoted only after we
*watch an agent fail without it and comply with it* — the `writing-skills`
RED→GREEN discipline applied to behavioral corrections.

## Decision

Build **`running-retrospectives`**: a skill in h-superpowers, invoked at a
deliberate reflective moment, that mines recurring corrections, proves each
candidate lesson with a RED→GREEN check, and banks survivors in `memory/`. It
**conducts**; it does not re-implement sensing or proving.

### Architecture — three tools, one verb each

| Tool | Verb | Owns |
|------|------|------|
| **agent-stalker** | SENSE | what happened — records tool use, inter-agent messages, tasks, errors to SQLite; already clusters |
| **crucible** | PROVE | does the lesson change behavior, statistically — A/B trials, accuracy + token verdict |
| **h-superpowers** | DECIDE & ENCODE | what's worth learning, the gate contract, where lessons live (`memory/`), how they're recalled — and conducts the other two |

The siblings are **detected, never required.** `running-retrospectives` lights up
tiers based on what's installed and degrades gracefully. A stranger who installs
only h-superpowers gets a coherent feature; the siblings make it better, not
mandatory. This keeps the melder identity to clean seams rather than a tangle, and
honors the design-direction rule (compose with installed plugins; concept-count is
a cost).

### The RED-step contract (engine-agnostic — h-superpowers owns this)

A prose lesson may be promoted **only if**, for a reproducible scenario distilled
from its captured corrections:

- **RED:** an agent *without* the lesson exhibits the bad behavior, **and**
- **GREEN:** an agent *with* the lesson injected does not,
- across **k trials each** (default k=3) with a **margin** (baseline fails the
  majority, with-lesson passes the majority) — the stochastic guard; one run
  proves nothing,
- and a **GREEN failure → reword or reject** (bounded REFACTOR loop, default ≤2
  rewrite attempts), never a silent promotion.

*How* the contract is executed is the tier (inline floor vs. crucible). The
contract itself does not change between tiers.

### Funnel stages

1. **Capture** (in-session behavior) — when the user corrects the agent on
   something generalizable, the agent appends a candidate to a project-local
   `.superpowers/lessons-candidates.ndjson`, each entry stamped with
   **content-hash (of CRLF-normalized text), session id, timestamp, source,
   confidence**. Persistent across sessions — that persistence is what makes
   recurrence countable.
2. **Cluster / count** (retrospective) — group candidates by normalized content;
   count recurrence over **distinct sessions**; a cluster is eligible at **N≥2**
   distinct sessions.
3. **Validate** (retrospective) — run the RED→GREEN contract on each eligible
   cluster. The user sees the distilled scenario and the RED/GREEN verdicts.
4. **Promote** — **move** (not copy) the survivor into a `memory/` entry
   (`type: feedback`) plus a one-line `MEMORY.md` index entry. One reviewable git
   diff. The candidate entries for that cluster are pruned (the fact now lives in
   `memory/` as the single source of truth).
5. **Recall** — one additional question on the existing `using-superpowers`
   pull-gate ("does a prior lesson apply before I act?"), v1 answered by
   grep/ripgrep over `memory/`. SessionStart stays `using-superpowers`-only
   (`exit 0`); nothing is auto-injected. The ~15-promoted-lesson crossover rule
   from the storage ADR governs when always-in-context MEMORY.md gives way to the
   deferred pull-only index.

## Scope — phased

### v1 — standalone floor (this spec builds this)
- **Capture:** user→agent corrections only, as an in-session behavior writing to
  the candidate file.
- **Validate:** a **minimal inline runner** — the skill distills a pressure
  scenario, spawns subagents for RED then GREEN (k=3 each), judges compliance with
  a simple rubric (deterministic check where the behavior is observable, e.g. "did
  it run the test command"; LLM-judge otherwise), applies the margin.
- **Promote / recall:** as above — `memory/` + pull-gate grep.
- **Seams named but not wired:** the agent-stalker SENSE feed and the crucible
  PROVE engine are referenced in prose with their contracts, not built.
- Net-new concepts for a stranger: ~1–2 (the candidate file; the retrospective
  skill — recall rides the existing gate, storage rides the existing `memory/`).

### Phase 2 — agent-stalker as SENSE (later; may need companion work)
Widen capture to the agent-to-agent lane (lead→teammate, peer↔peer) by reading
agent-stalker's recorded message log; draw recurrence from its DB. Source sets
entry **confidence** (user = high, lead→teammate = medium, peer↔peer = low); the
same RED→GREEN gate applies regardless of source — that is exactly what makes a
wider, noisier aperture safe. May require companion changes in agent-stalker
(stable read surface / query) — tracked as its own spec.

### Phase 3 — crucible as PROVE (later; may need companion work)
Replace the inline runner with a crucible experiment: variant-A = `memory/`
without the lesson, variant-B = the lesson commit; the distilled scenario is the
task; N trials; promote only if B's compliance beats A by a margin. Dogfoods
crucible and gives statistical rigor + a stored experiment artifact. May require
companion changes in crucible — tracked as its own spec.

## Defaults (tunable, not magic constants)
- Recurrence unit = **distinct sessions** (resists single-session over-counting).
- Eligibility threshold **N≥2**; trials **k=3**; REFACTOR retries **≤2**.
- Capture = in-session behavior; **validate+promote = deliberately invoked** (no
  mid-work interrupts — consistent with the time-machine-check "it's just a
  check-in" ethos).
- Promotion is **interactive** — the user approves what lands in `memory/`.
- Content-hash is computed over **CRLF-normalized** text (Windows + bash parity).

## Testing
- The skill itself is built under `writing-skills` (it IS TDD for process docs):
  baseline pressure scenarios where an agent skips capture / promotes on
  recurrence alone, then verify the skill induces the funnel discipline.
- Deterministic unit tests (no tokens) for the mechanical pieces: candidate-file
  append + CRLF-normalized hashing + dedup; distinct-session recurrence counting;
  the margin decision over a fixture of RED/GREEN trial results.
- The inline RED→GREEN runner's subagent behavior is validated by the skill's own
  pressure tests, not by asserting exact LLM output (brittle).

## Non-goals
- No new durable principles file — promoted lessons reuse `memory/`.
- No SessionStart injection of candidates, ever; promoted-lesson injection only
  under the ~15-lesson budget (storage ADR).
- No hard dependency on agent-stalker or crucible; no daemon, no external DB.
- Not building Phases 2–3 here — they are documented as a roadmap with contracts.

## Risks / open
- **The inline floor runner is a mini-crucible.** Risk: reinventing crucible.
  Mitigation: keep it deliberately minimal (k=3, simple rubric) and delegate to
  real crucible in Phase 3 behind the same contract. This is the top risk.
- **Scenario distillation quality.** A bad auto-distilled scenario makes RED→GREEN
  meaningless. Mitigation: the user reviews the scenario before trials; a cluster
  whose scenario can't be made to reproduce the failure at baseline is *not*
  promotable (no RED = no validation).
- **Capture relies on the agent noticing it was corrected.** Some corrections will
  be missed in the floor (no automatic SENSE). Accepted for v1; Phase 2 (agent-
  stalker) closes it.
- **Recurrence double-counting** corrupts the N≥2 gate. Mitigation: content-hash
  dedup + per-entry session provenance; count distinct sessions.
