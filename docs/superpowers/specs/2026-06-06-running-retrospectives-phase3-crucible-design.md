# running-retrospectives Phase 3 — crucible as the PROVE engine

**Status:** Design approved (2026-06-06). Successor to the v1 floor
(`docs/superpowers/specs/2026-06-05-running-retrospectives-design.md`), which
named this phase as a roadmap item: *"Phase 3 — crucible as PROVE (later; may
need companion work)."*

## Problem

The running-retrospectives v1 floor validates a candidate lesson with a
**minimal inline RED→GREEN runner**: the skill spawns subagents for the RED
(no lesson) and GREEN (lesson injected) conditions, k=3 trials each, and applies
a margin rule. v1's own spec names this as the **top risk**: *"the inline floor
runner is a mini-crucible — risk of reinventing crucible."*

crucible already exists as a token-economy A/B harness that runs N trials per
variant, scores each with a deterministic gate plus an LLM judge, and stores
machine-readable results. Phase 3 retires the top risk by making crucible the
**preferred validation tier** behind the *same engine-agnostic RED→GREEN
contract* v1 defined — without deleting the inline floor, and without requiring
crucible to be installed.

## Sibling state (verified, not assumed)

crucible **v0.4.0**, as it exists today, fits the contract nearly as-is:

> **Amendment (2026-06-06, during implementation):** crucible moved to v0.6.x
> while this phase was being built (it releases fast). v0.6 made per-approach
> `model` required in the spec schema, so `gen-spec` emits it (`--model`,
> default claude-sonnet-4-6). Detection policy changed from an exact-match pin
> to a **minimum version** (`CRUCIBLE_MIN`, default 0.6): the version check is
> only a pre-filter — the real contract gate is `crucible validate`, which
> checks the actual generated artifact against the actual installed binary for
> free on every run, with mechanical failure falling back to the inline floor.
> One platform note: native-Windows crucible cannot resolve MSYS `/tmp/...`
> paths, so `gen-spec` normalizes the harness path via `cygpath -m` when
> available.

- **Headless + machine-readable.** `crucible run <spec.toml>` runs the full loop
  non-interactively and exits 0/non-zero; `crucible query "<sql>"` is a
  documented CLI over the results DB; `crucible validate <spec.toml>` checks the
  editable surface spending **zero tokens**.
- **Variants by git ref.** Each `[[approach]]` is materialized via
  `git worktree add --detach <ref>` of the harness repo; an `[editable_surface]
  allow=[...]` guardrail rejects any approach whose diff touches files outside
  the allowlist, *before* any trial runs.
- **Gate + judge.** `[gate]` runs a deterministic `command` (exit 0 = pass) plus
  declarative `assertions` (`contains` / `not_contains` / `count` / `order`) on
  agent output. `[judge]` scores each completed trial with an LLM rubric
  (default 5 dimensions, each 0/1/2, reweightable; custom dimensions allowed).
- **Per-approach gate results are stored** in the `trials` table
  (`gate_passed` per trial), reachable through `crucible query`.

The one mismatch: crucible's built-in **verdict** promotes a challenger for
being *cheaper* (token savings) without regression — the opposite shape from
RED→GREEN, which promotes a lesson for *improving gate-pass-rate by a margin*.
RR sidesteps this by consuming crucible's **raw per-approach gate results** and
owning the decision itself (see Decision). crucible's `verdict=` line is ignored.

## Architecture — crucible as a detected, preferred tier

```
running-retrospectives  validate stage
        │
        ├─ crucible installed & >= minimum version?  ──► CRUCIBLE TIER (preferred)
        │         crucible run → crucible query → RR margin rule
        │
        └─ else ─────────────────────────────────► INLINE FLOOR (v1, unchanged)
                  spawn subagents k=3 → RR margin rule
```

- Both tiers consume the **same** cluster input (distilled scenario + candidate
  lesson) and produce the **same** output (RED verdict, GREEN verdict,
  promote/reject). Only *who runs the trials* changes.
- **Detection is automatic:** RR shells out to `crucible --version` (mirroring
  crucible's own `preflight` skill) and falls back silently to the inline floor
  if crucible is absent or below the minimum version. A user can force the floor.
- **Net concept cost to a stranger: ~0.** No new always-loaded surface, no new
  file the user authors — RR generates the crucible spec internally. crucible is
  an optional accelerant, exactly as v1 promised. Siblings are **detected, never
  required.**

## The core mechanism — cluster → scratch experiment

crucible differentiates variants by **git ref of the harness repo**, but RR's
variants differ only by *whether the candidate lesson is present*. So RR builds
a throwaway scratch harness repo with two commits:

```
scratch-harness/  (git repo RR creates in a temp dir)
   commit "baseline"  → CLAUDE.md WITHOUT the candidate lesson   ← RED approach ref
   commit "green"     → CLAUDE.md WITH the candidate lesson       ← GREEN approach ref

experiment.toml (RR generates):
   [experiment]   harness=<scratch-harness>  trials=3
   [test_project] path=<repro scaffold>  task="<distilled scenario>"
   [editable_surface] allow=["CLAUDE.md"]
   [gate]         command/assertions = the RED→GREEN observable   (see Gate strategy)
   [judge]        model=<haiku>
   [[approach]]   name="baseline" ref="baseline"
   [[approach]]   name="green"    ref="green"
```

crucible then runs k=3 trials per approach in isolated worktrees, scores each
with the gate, and stores `gate_passed` per trial. RR reads it back with the
documented `crucible query "SELECT approach, gate_passed FROM trials WHERE
experiment_id=?"` and applies its own margin rule. **No crucible code is
touched** — the scratch repo and the repro scaffold are entirely RR-side
construction.

## Gate strategy — prose lesson → RED→GREEN observable

The same hard problem the v1 floor has (v1 names "scenario distillation quality"
as a risk). crucible gives two complementary scoring surfaces, used in priority
order:

1. **Deterministic gate `command`** (preferred) — when the behavior produces an
   observable artifact. E.g. lesson = "always run the test suite before claiming
   done" → gate `command` greps the agent transcript/output for the test
   invocation, or checks a sentinel file the scaffold's test script writes.
   Exit 0 = behavior exhibited.
2. **Gate `assertions`** on agent output — when the behavior is visible in
   narration, not files. E.g. `not_contains` a forbidden pattern, or `order`
   (did X before Y). Cheaper and fully deterministic.
3. **crucible `judge` with a single custom rubric dimension** (fallback) — when
   the behavior is only judgeable, not checkable. RR injects one dimension
   (*"followed-lesson: did the agent do `<lesson>`? 0/1/2"*) and disables the
   default 5 dimensions (we are testing one behavior, not overall quality). The
   judge score becomes the pass signal with a threshold.

**The hard gate stays:** a cluster whose scenario **cannot be made to fail at
baseline** (no RED) is *not promotable* — identical to v1. If the deterministic
gate can't reproduce the bad behavior at baseline across the trials, RR rejects
rather than falling through to a softer judge. **No RED, no validation.**

## Decision — RR owns the margin

After `crucible run` exits, RR pulls per-approach gate results through the
**documented** `crucible query` CLI (not by reading the DB file directly — stays
on the stable contract):

```
baseline gate-pass count, green gate-pass count   (out of k=3 each)
   ↓ RR's margin rule (identical to the inline floor — single source of truth):
   RED satisfied   := baseline fails the majority   (≥2 of 3 fail)
   GREEN satisfied := green passes the majority      (≥2 of 3 pass)
   promote ⟺ RED ∧ GREEN ; else reject
   GREEN failure after RED → bounded reword loop (≤2), then reject
```

In practice RR runs each experiment against a **fresh throwaway `--db`**, so the
`trials` table holds exactly one experiment and the per-approach query needs no
`experiment_id` filter (crucible's `run` does not print the id, and `crucible
query` takes no bind parameters). The query encodes `approach:passes/total` as a
scalar so the result is parseable regardless of the dict-repr row wrapper.

crucible's savings-oriented `verdict=` line is **ignored**; RR consumes only the
raw trial gate results. The margin logic lives in exactly one place (the
`lessons decide` primitive from v1), so both tiers share it — the crucible tier
just feeds it different inputs. This is what guarantees the two tiers agree.

## Testing

**Deterministic unit tests (no tokens)** — the mechanical pieces, same
discipline as v1:

- **Spec generation:** given a fixture cluster (scenario + lesson), assert RR
  emits a well-formed `experiment.toml` and a two-commit scratch harness whose
  diff touches only the allowed file. Assert `crucible validate` passes on the
  generated spec (editable-surface clean, no tokens spent).
- **Result parsing → margin:** feed a fixture `trials` result set (baseline
  `gate_passed=[0,0,1]`, green `[1,1,0]`) through the `crucible query` parse plus
  the shared margin rule; assert promote/reject matches the RED∧GREEN truth
  table. Reuse the exact v1 `lessons decide` assertions over a crucible-shaped
  fixture — proving both tiers agree.
- **Tier detection:** stub `crucible --version` present / absent / mismatched;
  assert RR selects crucible / falls back to floor / falls back on mismatch.

**Behavioral test (the skill itself):** a pressure scenario where crucible is
"installed" (stubbed) and the skill must drive the crucible tier rather than the
inline floor — verifying the conducting skill actually delegates. The existing
v1 floor behavioral test stays green (degradation path intact).

**Degradation is the safety net:** every crucible-tier failure mode (not
installed, version mismatch, `crucible run` non-zero exit, malformed query
result) falls back to the inline floor — never to a silent promotion. crucible
can only ever *strengthen* validation; its absence or failure never weakens the
v1 guarantee.

## Scope

- **Companion changes to crucible: zero.** Everything is RR-side — scratch-harness
  construction, spec generation, `crucible run`/`query` invocation, margin
  decision. This is the whole reason Phase 3 ships without a crucible release.
- **Phase 3 does not touch Phase 2.** agent-stalker / SENSE capture is untouched;
  this is purely the *validate* stage swapping in a stronger engine.

## Non-goals

- No change to capture / cluster / promote / recall.
- No new user-authored file; the crucible spec is generated internally.
- No `using-superpowers` / SessionStart edit.
- The inline floor is **retained**, not deleted.
- crucible's savings-verdict is **not** consumed.
- Not a first-class crucible `[decision] mode="behavior"` — deferred until a
  second consumer needs it (YAGNI).

## Risks

- **Scratch-scenario fidelity (top risk).** A generated repro that doesn't
  actually exercise the behavior makes RED→GREEN meaningless. Mitigation is the
  v1 rule, unchanged: the user reviews the distilled scenario and the generated
  spec **before** `crucible run` spends tokens, and no-RED-at-baseline = not
  promotable.
- **crucible contract drift.** RR depends on `crucible run` / `query` /
  `validate` CLI shape and the `trials.gate_passed` column. Mitigation: a
  too-old crucible falls back to the floor at detection; schema drift in a newer
  crucible is caught by the free `crucible validate` pre-check, which also falls
  back rather than consuming an unverified surface.
- **Token cost.** The crucible tier spends real tokens (k=3 × 2 approaches).
  Mitigation: deliberately invoked (never mid-work), user approves before the
  run, `crucible validate` pre-check spends none.

## Roadmap seam (not built here)

Phase 2 (agent-stalker as SENSE) remains the other deferred phase: widen capture
to agent-to-agent lanes by reading agent-stalker's DB. It needs genuine companion
work (agent-stalker v0.5.0 has no machine-readable query mode and no first-class
"correction" concept), and is intentionally sequenced *after* Phase 3 — a
statistically harder gate (crucible) makes the noisier capture aperture safe,
per v1's own logic.
