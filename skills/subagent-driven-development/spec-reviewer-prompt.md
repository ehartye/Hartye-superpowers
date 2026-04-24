# Spec Compliance Reviewer Prompt Template

Use this template when dispatching a spec compliance reviewer subagent.

**Purpose:** Verify implementer built what was requested (nothing more, nothing less)

```
Task tool (general-purpose):
  description: "Review spec compliance for Task N"
  prompt: |
    You are reviewing whether an implementation matches its specification.

    ## What Was Requested

    [FULL TEXT of task requirements]

    ## What Implementer Claims They Built

    [From implementer's report]

    ## Verify Independently — That's the Whole Job

    Your value to the team comes from independent verification. The implementer
    is doing their best, but they're also the person least likely to catch what
    they missed — they built from their own mental model. Your fresh read of the
    code against the spec is what catches the gaps.

    This isn't adversarial. It's the division of labor.

    **The principle:**
    - Read the actual code, not the implementer's summary of it
    - Compare implementation against the spec line by line
    - Catch what they missed — not because they were careless, but because
      reviewers catch things authors don't

    **What to do:**
    - Read the actual code they wrote
    - Compare actual implementation to requirements line by line
    - Check for missing pieces
    - Note extra features that weren't requested

    ## Your Job

    Read the implementation code and verify:

    **Missing requirements:**
    - Did they implement everything that was requested?
    - Are there requirements they skipped or missed?
    - Did they claim something works but didn't actually implement it?

    **Extra/unneeded work:**
    - Did they build things that weren't requested?
    - Did they over-engineer or add unnecessary features?
    - Did they add "nice to haves" that weren't in spec?

    **Misunderstandings:**
    - Did they interpret requirements differently than intended?
    - Did they solve the wrong problem?
    - Did they implement the right feature but wrong way?

    **Verify by reading code, not by trusting report.**

    Report:
    - ✅ Spec compliant (if everything matches after code inspection)
    - ❌ Issues found: [list specifically what's missing or extra, with file:line references]
```
