# Altitude-Router Routing Eval (crucible-free)

Purpose: validate the **routing decision** of the altitude-router skill change without
crucible. Crucible (headless, token/accuracy) was the wrong lens — the thing that
actually matters is whether the rule routes a task to the right amount of ceremony,
and especially whether it commits the dangerous **under-design** error (skipping design
on a task that genuinely needed it).

Method: independent fresh-context agents read ONE routing rule (v2 or v1) plus the bare
task list (no labels), and for each task decide `implement-directly` vs
`design-and-approval-first`. We score against the labels below.

Metrics:
- **Under-design rate** = clear-ESCALATE tasks routed `implement-directly` (the dangerous failure v2 risks).
- **Over-ceremony rate** = clear-IMPLEMENT tasks routed `design-and-approval-first` (the waste v2 targets; the original always-gate skill = 100% by construction).
- **Borderline consistency** = agreement across agents on judgment-call tasks (no single right answer).

## Labeled task set

### Clear IMPLEMENT (no trigger — should NOT gate)
- I1: Fix a typo in the README heading.
- I2: Rename the local variable `d` to `delay` inside one function.
- I3: Implement `clamp(n, lo, hi)` returning n bounded to [lo, hi], with unit tests. (clear spec)
- I4: Add a `--version` flag that prints the package.json version.
- I5: Change the default HTTP timeout constant from 30000 to 60000 ms.
- I6: Add a unit test covering the existing `slugify` function's empty-string case.
- I7: Add a `.gitignore` entry for `*.log`.

### Clear ESCALATE (trigger present — should gate)
- E1: Add user authentication (login/signup/sessions) to the web app. (multi-subsystem, security, ambiguous)
- E2: Migrate the database from SQLite to Postgres. (hard to reverse)
- E3: Add a billing & subscription system. (multi-subsystem, ambiguous)
- E4: Redesign the plugin's public slash-command API. (public API, hard to reverse)
- E5: Delete the legacy `sync/` module and update everything that imported it. (destructive)
- E6: Add caching to the API client. (ambiguous: TTL / size / invalidation unspecified)
- E7: Build an analytics dashboard for usage metrics. (ambiguous scope, many choices)

### Borderline (judgment; report distribution, no single right answer)
- B1: Add a config option `maxRetries` (integer, default 3) to the existing retry helper. (leans implement — clear spec)
- B2: Add input validation to the signup form. (leans escalate if rules unspecified — ambiguous)
- B3: Refactor the 500-line `UserService` into smaller modules. (leans escalate — design the decomposition; under-design risk if treated trivial)

## Results

3 independent fresh-context agents per rule (v2 escalation-trigger; v1 three-tier),
classifying all 17 tasks with neutral IDs (labels hidden from agents).

| Metric | v2 (trigger) | v1 (three-tier) | original (always-gate) |
|---|---|---|---|
| **Under-design** (clear-ESCALATE routed to implement) | **0 / 21** | **0 / 21** | 0 (gates everything) |
| **Over-ceremony** (clear-IMPLEMENT routed to gate) | **0 / 21** | **0 / 21** | **21 / 21 by construction** |
| Cross-agent consensus | 16 / 17 unanimous | 17 / 17 unanimous | n/a |

Borderline tasks:
- **T5** (refactor 500-line UserService): v2 3/3 escalate; v1 3/3 escalate. *(matches "leans escalate")*
- **T10** (`maxRetries` config, clear spec): v2 3/3 implement; v1 3/3 implement. *(matches "leans implement")*
- **T15** (signup validation, rules unspecified): v2 **2 implement / 1 escalate**; v1 3/3 implement. *(the one genuine split — one v2 agent caught the ambiguous-requirements trigger)*

### Findings

1. **v2 is safe.** On clear-cut tasks it never under-designs and never over-ceremonializes —
   it matches v1's routing quality exactly. The feared under-design regression from
   relaxing the always-gate did **not** appear.
2. **v2 ≈ v1 on routing correctness** (near-tie). v2 is nearly as consistent (16/17 vs 17/17);
   the only split was the genuinely ambiguous T15.
3. **Both decisively beat the original always-gate** on over-ceremony (0% vs 100% on
   clear-implement tasks) with zero observed under-design cost — so adopting *either*
   right-sizing variant is well-supported on correctness grounds.
4. **v2's edge over v1 is structural, not measured here.** v1's "Standard" middle tier
   forced agents into a second judgment (Standard→gate? for T1/T5/T14 yes, for T10/T15 no);
   v2 collapses that to one binary trigger decision. Cleaner, but this classification eval
   does **not** measure the cognitive/token overhead difference (the crucible hint that v1
   tiering induces deliberation remains unproven).

### Not validated by this eval

- The **efficiency** claim (v2 cheaper than v1, or either cheaper than always-gate at runtime)
  — that needs execution measurement, not classification.
- **Model-homogeneity caveat:** the classifiers are Claude and the labels were authored by
  Claude; shared intuitions inflate agreement. The borderline split (T15) is evidence the
  agents weren't merely rubber-stamping, but cross-model labels would strengthen this.

### Verdict

Right-sizing (v2) is **validated as correct and safe** on routing — a strict improvement over
the always-gate status quo with no under-design cost on clear cases — but is a **near-tie with
v1 on routing accuracy**. v2's advantage is a cleaner single-decision structure, not demonstrated
better routing. The efficiency question that motivated v2 over v1 stays open (needs runtime
measurement, which crucible isn't yet equipped to do validly).
