# running-retrospectives — Design

## Status
Approved (brainstormed 2026-06-05). Implements Rec 2 of
`docs/research/claude-code-harness-landscape-2026-06-03.md` (formerly
"harvesting-lessons"). Storage/retrieval explored in
`docs/decisions/2026-06-05-harvesting-lessons-storage.md`.

**Planning resolution (2026-06-05):** the ADR conflated "reuse the existing
`memory/` convention" with "git-diffable promotion" — but no repo-local `memory/`
exists; the only `memory/` is the agent's project-scoped auto-memory (auto-injected
each session, outside the repo, not git-tracked). v1 promotes there (Option A): the
RED→GREEN validation gate + interactive approval are the correctness guarantee that
the git-review property would otherwise have provided. v1 also narrows scope to
**project-specific lessons only**. Both decisions are reflected below and supersede
the ADR where they differ.

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
| **h-superpowers** | DECIDE & ENCODE | what's worth learning, the gate contract, where lessons live (the project auto-memory), how they're recalled — and conducts the other two |

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
   append-only line file `.superpowers/lessons-candidates.tsv` (tab-separated, for
   pure-bash/awk parsing — no JSON-in-bash), each entry stamped with
   **content-hash (of CRLF-normalized text), session id, timestamp, source,
   confidence**. Persistent across sessions — that persistence is what makes
   recurrence countable.
2. **Cluster / count** (retrospective) — group candidates by normalized content;
   count recurrence over **distinct sessions**; a cluster is eligible at **N≥2**
   distinct sessions.
3. **Validate** (retrospective) — run the RED→GREEN contract on each eligible
   cluster. The user sees the distilled scenario and the RED/GREEN verdicts.
4. **Promote** — **move** (not copy) the survivor into the agent's **project-scoped
   auto-memory** as a `type: feedback` memory file plus its one-line `MEMORY.md`
   index entry (the memory directory the agent is already told to use each session;
   e.g. `~/.claude/projects/<this-project>/memory/`). This is project-local — it
   only applies to this project and is never baked into the shipped plugin (per the
   design-direction rule). The candidate entries for that cluster are then pruned
   (the fact now lives in the auto-memory as the single source of truth).
5. **Recall** — **automatic, no new mechanism.** The project auto-memory `MEMORY.md`
   is already injected into every session by the agent's memory system, so a promoted
   lesson is recalled for free. v1 adds **no `using-superpowers` edit** and leaves
   SessionStart untouched. The ~15-promoted-lesson crossover rule from the storage
   ADR still applies — it bounds how much promoted memory is injected; above it,
   pull-on-demand retrieval is a deferred concern, not a v1 problem.

## Scope — phased

### v1 — standalone floor (this spec builds this)
- **Capture:** user→agent corrections only, as an in-session behavior writing to
  the candidate file.
- **Validate:** a **minimal inline runner** — the skill distills a pressure
  scenario, spawns subagents for RED then GREEN (k=3 each), judges compliance with
  a simple rubric (deterministic check where the behavior is observable, e.g. "did
  it run the test command"; LLM-judge otherwise), applies the margin.
- **Scope:** **project-specific lessons only** — "how to work well in *this*
  project." Two other lesson kinds are explicitly out of v1: improving h-sup the
  plugin (that's a `writing-skills` skill-edit pipeline, and the design rule forbids
  baking lessons into the shipped plugin) and cross-project general-behavior lessons
  (deferred — wider blast radius raises the validation bar).
- **Promote / recall:** as above — write a `type: feedback` file into the project
  auto-memory; recall is automatic via the already-injected `MEMORY.md`.
- **Seams named but not wired:** the agent-stalker SENSE feed and the crucible
  PROVE engine are referenced in prose with their contracts, not built.
- Net-new concepts for a stranger: ~1 (the candidate file + the retrospective skill;
  recall and storage both ride the existing auto-memory the agent already maintains —
  no new always-loaded surface, no `using-superpowers` edit).

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
- Promotion is **interactive** — the user approves what lands in the auto-memory.
- Content-hash is computed over **CRLF-normalized** text (Windows + bash parity).
- Promoted lesson type = **`feedback`** ("guidance the user has given on how you
  should work" — the exact category match for a captured correction).

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
- No new durable store — promoted lessons reuse the agent's project auto-memory.
- No `using-superpowers` / SessionStart edit in v1; candidates are never injected;
  promoted-lesson injection is bounded by the ~15-lesson budget (storage ADR).
- Not for improving h-sup the plugin (category 1 — that's a `writing-skills`
  pipeline) and not for cross-project general-behavior lessons (deferred).
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
