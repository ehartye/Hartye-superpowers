---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Overview

A completion claim without verification isn't efficient — it's a guess dressed up as a fact. Your human partner depends on the difference.

**Core principle:** Evidence before claims, always.

**The spirit of this rule is the letter of this rule.** There's no way to follow it partially.

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you don't yet know whether it passes — so don't claim it.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skipping any step means the claim isn't verified yet — and a claim that isn't verified shouldn't be stated as one that is.
```

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Signals to Watch For

When you notice these in your own thinking or output, the claim is running ahead of the evidence — pause and run the verification:

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports without checking the diff
- Relying on partial verification
- "Just this once"
- Tired and wanting the work over
- **Any wording implying success without having run verification in this message**

## Common Objections, Answered

| Objection | Answer |
|--------|---------|
| "Should work now" | Run the verification — "should" is a guess, output is evidence. |
| "I'm confident" | Confidence isn't evidence. |
| "Just this once" | The cycle is short. Run it. |
| "Linter passed" | The linter doesn't run the build. Run the build. |
| "Agent said success" | Check the diff independently — agents can be wrong about their own work. |
| "I'm tired" | Verification is faster than fixing trust later. |
| "Partial check is enough" | A partial check proves part of the claim. State what you checked, not the whole claim. |
| "Different words so the rule doesn't apply" | The rule is about the claim, not the phrasing. |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## Why This Matters

These failures have been observed repeatedly in practice:
- "I don't believe you" — trust lost, costly to rebuild
- Undefined functions shipped — would have crashed in production
- Missing requirements shipped — incomplete features
- Time wasted when false completion leads to redirect and rework

Your human partner needs to know the difference between a verified claim and a guess. Honesty is the foundation everything else relies on — making this the rule we hold hardest.

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.

## Integration

**Referenced by:**
- **h-superpowers:subagent-driven-development** - Verification discipline baked into implementer self-review
- **h-superpowers:team-driven-development** - Verification discipline baked into implementer self-review
- **h-superpowers:systematic-debugging** - Referenced as related skill
- **h-superpowers:finishing-a-development-branch** - Step 1 test verification applies this discipline
