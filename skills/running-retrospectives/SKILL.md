---
name: running-retrospectives
description: Use when the same correction keeps recurring across multiple work sessions, or at the end of a session to harvest recurring project-specific user feedback into durable memory. Not for one-off corrections — a correction seen in only one session is not yet eligible.
---

# Running Retrospectives

## Overview

Turn recurring corrections into **validated** durable lessons. The spine: **no
lesson is promoted without a failing baseline** — you must watch an agent do the
wrong thing without the lesson, then comply with it. Recurrence is the entry
ticket, not the proof.

This skill **conducts**; it does not re-implement sensing or proving. The
mechanical pieces live in a deterministic bash CLI invoked as
`bash scripts/lessons <subcommand>` (relative to this skill's directory). Scope is
**project-specific lessons only**, promoted into the agent's existing project
memory. Validation runs on the best available engine: the inline floor, or
crucible when installed (see step 3).

## The RED->GREEN contract (rigid — do not soften)

A clustered candidate may be promoted ONLY IF, for a reproducible scenario
distilled from its corrections:

- **RED:** an agent WITHOUT the lesson exhibits the bad behavior, AND
- **GREEN:** an agent WITH the lesson injected does not,
- across **k=3 trials each**, with the **majority margin** (decided by
  `bash scripts/lessons decide` (floor) or `bash scripts/lessons crucible-decide`
  (crucible tier — same margin rule, shared implementation)), AND
- a GREEN failure means **reword or reject** (<=2 rewrite attempts), never promote.

If the failure will not reproduce at baseline (no RED), there is nothing to
validate — **do not promote.** "It recurred" and "it aligns with our docs" are
not substitutes for watching the failure happen.

## Procedure

1. **Capture** (run during/after a session, once per generalizable correction the
   user gave you):
   `bash scripts/lessons capture "<the correction, imperative form>"`
   The script stamps a CRLF-normalized content hash + the current session id
   (`$CLAUDE_CODE_SESSION_ID`) + timestamp, and dedups within a session. (Source
   defaults to `user`; pass `--source` only for non-user corrections, which
   Phase 2 introduces.) If this is the first time you have seen this
   correction, capturing is all you do — it is not eligible for the retrospective
   until it recurs in another session.
2. **Cluster:** `bash scripts/lessons cluster` → eligible clusters (recurred across
   **>=2 distinct sessions**) as `hash <tab> distinct_sessions <tab> total <tab> text`.
   A correction seen in only one session is **not eligible** — leave it as a
   candidate, however obviously-right it seems. The recurrence gate is not
   overridable by your judgment.
3. **For each eligible cluster, select the validation engine and run the
   RED->GREEN contract.** Run `bash scripts/lessons detect-engine`:
   - prints `crucible` -> use **3-CRUCIBLE** (statistical tier),
   - prints `floor` -> use **3-FLOOR** (the inline runner; v1 behavior).
   The contract (RED, GREEN, k=3, majority margin, <=2 rewords, no-RED-no-promote)
   is identical across tiers — only who runs the trials changes. If crucible is
   absent, or a crucible command fails MECHANICALLY (nonzero exit from
   validate/run, unparseable query output), fall back to 3-FLOOR and resume at
   its step (b) with the same user-approved scenario; never skip the gate. A
   `reject` from crucible-decide is a VERDICT, not a failure — it follows the
   reword/drop rules and never triggers a tier switch.

   **3-FLOOR — inline runner:**
   a. **Distill a scenario** — a concrete task that recreates the situation where
      the agent erred. **Show it to the user** before running trials.
   b. **RED:** dispatch 3 fresh subagents on the scenario WITHOUT the lesson. Judge
      each: did it exhibit the bad behavior? Count failures = `RF`.
   c. **GREEN:** dispatch 3 fresh subagents on the same scenario WITH the lesson
      text injected into their instructions. Judge each: did it comply?
      Count passes = `GP`.
   d. **Decide:** `bash scripts/lessons decide --k 3 --red-fail RF --green-pass GP`
      → `promote` (exit 0) or `reject` (exit 1).
   e. If rejected because GREEN failed: reword the lesson and retry from (b), up to
      twice, then drop it.

   **3-CRUCIBLE — crucible as the PROVE engine:**
   a. **Distill a scenario** — a concrete task recreating where the agent erred.
      **Show it to the user** before spending tokens (same as 3-FLOOR; cheap
      sanity check before any artifacts are built).
   b. **Build the variant pair in a fresh workspace** — `TMP="$(mktemp -d)"`; every
      attempt, including each reword retry, starts with its own fresh `TMP`:
      `bash scripts/lessons scratch-harness "$TMP/harness" "<the lesson, imperative form>"`
      (a throwaway git repo: `baseline` ref without the lesson, `green` ref with it).
   c. **Generate the experiment** with a deterministic gate (the highest-fidelity
      signal — prefer it):
      `bash scripts/lessons gen-spec --harness "$TMP/harness" --task "<scenario>" --gate-command "<observable check>" > "$TMP/exp.toml"`
      When `--gate-command` is supplied, gen-spec emits a `[gate] command`. If the
      behavior is only checkable via output assertions or an LLM judge, hand-add a
      `[gate]` table with `assertions = [...]` or a `[judge.rubric]` followed-lesson
      dimension to `$TMP/exp.toml` before validating — crucible supports both.
   d. **Free pre-check (no tokens):** `crucible validate "$TMP/exp.toml"`. Fix any
      editable-surface error before the paid run.
   e. **User approves** the scenario and the spec before the paid run (the
      paid-run gate — last stop before tokens are spent).
   f. **Run the trials:** `crucible run "$TMP/exp.toml" --db "$TMP/results.db"`
      (a fresh per-run DB, so the trials table holds exactly this experiment).
   g. **Decide (RR owns the margin; crucible's own verdict is ignored):**
      `crucible query "SELECT approach || ':' || SUM(gate_passed) || '/' || COUNT(*) AS r FROM trials GROUP BY approach" --db "$TMP/results.db" | bash scripts/lessons crucible-decide --k 3`
      -> `promote` (exit 0) or `reject` (exit 1). Keep `--k` equal to the
      `--trials` value used in gen-spec (both default 3). A baseline that passes
      the majority means **no RED reproduced — not promotable** (crucible-decide
      enforces this).
   h. If rejected because GREEN failed: reword the lesson and retry from (b) **in a
      fresh workspace** (`TMP="$(mktemp -d)"` again — never reuse a harness dir; its
      refs are stale), up to twice, then drop it.
4. **Promote (interactive)** — only on a `promote` verdict, and only after the user
   approves the wording:
   - Write the lesson as a **`type: feedback`** memory file in **your project
     memory directory** — the directory where your project `MEMORY.md` lives; your
     memory instructions name its exact path each session — with a one-line pointer
     added to that `MEMORY.md`. Include the **why** and **how to apply it**.
   - This is **project-local** — it only applies to this project. NEVER write the
     lesson into this plugin's shipped files (`skills/`, `CLAUDE.md`). Improving
     the plugin itself is a different pipeline (h-superpowers:writing-skills).
   - Prune the promoted cluster from candidates:
     `bash scripts/lessons prune <hash>`.
5. **Recall is automatic** — your project `MEMORY.md` is already injected each
   session, so a promoted lesson is recalled for free. Do **not** add a SessionStart
   or using-superpowers hook. Keep promoted lessons few; retire superseded ones
   (pruning memory is budget reclamation — it bounds per-session injection).

## Scope (v1)

- **Project-specific lessons only** — "how to work well in *this* project."
- Out of scope: improving h-sup the plugin (use h-superpowers:writing-skills);
  cross-project general-behavior lessons (deferred — wider blast radius raises the
  validation bar).

## Composing with siblings (crucible built in Phase 3; agent-stalker not yet)

- **agent-stalker = SENSE (Phase 2):** if installed, widen capture to agent-to-agent
  corrections from its recorded message log; source sets entry confidence. Same gate.
- **crucible = PROVE (Phase 3, BUILT):** when `detect-engine` finds crucible at
  or above the minimum version, validation runs as a crucible A/B experiment
  (baseline ref vs. green ref) for statistical rigor — see 3-CRUCIBLE. RR
  generates the experiment and owns the margin decision; crucible's
  savings-oriented verdict is not used. An absent or too-old crucible falls back
  to the inline floor.

Both are detected, never required. The agent-stalker integration is NOT built —
do not attempt to invoke it until that sibling skill is installed and loaded.
The RED->GREEN contract is identical across tiers.

## Common rationalizations, answered

| Thought | Reality |
|---------|---------|
| "It recurred twice, just promote it." | Recurrence is the entry ticket, not the proof. No RED->GREEN, no promotion. |
| "It aligns with CLAUDE.md / is obviously right — promote it." | Plausibility is not validation. You still have to watch an agent fail without it. |
| "This correction is clearly correct even though it's only one session." | One session is not eligible. The N>=2 gate is not overridable by judgment. |
| "The failure won't reproduce, but the lesson is right." | No reproducible RED = nothing to validate. Don't promote. |
| "One baseline run failed — good enough." | One run is noise. k=3 with a majority margin. |
| "I'll just add it to CLAUDE.md / a skill." | That bakes a project lesson into the shipped plugin. Project lessons go in project memory. |
| "crucible isn't installed — skip the validation this once." | No. Fall back to the inline floor (3-FLOOR). The gate is never skipped. |
| "crucible says keep_baseline, so reject." | crucible's verdict is savings-tuned and irrelevant here. RR reads raw gate-pass counts via crucible-decide; that — not crucible's verdict — is the RED->GREEN decision. |

## Notes for implementers

- Invoke the CLI as `bash scripts/lessons ...` (the script is not marked
  executable, matching the `drift` precedent).
- An **empty** candidate file means the same as an absent one — `cluster` yields
  no eligible clusters; that is the normal "nothing to harvest yet" state.
