---
name: time-machine-check
description: Use at a natural beat during a long or no-design task to check whether the work is drifting from intent. Measures change since a baseline SHA and runs a prospective-hindsight ("time machine") reflection, returning an on-track/diverged verdict. The caller decides what to do with the verdict.
---

# Time-Machine Check

A reusable reflective checkpoint. Given a **baseline SHA** and an **evaluation
narrative**, it measures how far the work has drifted and asks the honest
question — then hands back a verdict. **It does not act on the verdict; the
caller does.**

## Inputs

- **sha** (required) — the baseline commit to measure drift from (e.g. recorded
  earlier with `drift mark`).
- **narrative** (required) — the evaluation frame for this context. Default:
  *"Is this going how we thought? If you had a time machine, would you go back
  and design it first?"* Callers pass their own (e.g. executing-plans:
  *"Does the work so far still match the approved plan?"*).
- **files / lines** (optional) — drift thresholds; defaults 4 / 150.

## Procedure

1. Run the drift reading:
   `bash skills/time-machine-check/scripts/drift measure <sha> [--files N] [--lines M]`
   It prints `files=… lines=… crossed=…`.
2. Read the `crossed` flag and the raw numbers **together with the narrative**.
   The number is a prompt to think, not a verdict — a low number with a clear
   "yes, I'd time-machine this" still means diverged; a high number on genuinely
   simple breadth can still be on-track.
3. Answer the narrative honestly.
4. Return a verdict: **on-track** or **diverged**, plus a one-line rationale.

## Boundary

This skill returns a verdict and stops. What happens on **diverged** is the
**caller's** decision — a spike-checkpoint retreats and redesigns; a plan
executor re-plans; a debugger re-forms its hypothesis. Do not bake any one
response into this skill.

## Callers

- **spike-checkpoint** (right-sizing) — see using-superpowers → Right-Sizing.
- Reusable elsewhere by passing a different `narrative`.
