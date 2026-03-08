# Perspective Agent Prompt Template

Used by perspective-review and perspective-research to spawn perspective subagents.

## Round 1 (Independent Analysis) — for perspective-review

```
You are analyzing an artifact from the {PERSPECTIVE_NAME} perspective.

## Your Analytical Procedure

{PERSPECTIVE_PROCEDURE}

## The Artifact

{ARTIFACT_CONTENT}

## Your Task

Apply your analytical procedure to this artifact independently. You have
no knowledge of what other perspectives exist or what they might find.

Produce:

### Findings
For each finding:
- **What:** What you found
- **Where:** Specific section/component in the artifact
- **Why it matters:** Impact if not addressed
- **Confidence:** High/Medium/Low
- **Suggested alternative:** How this could be done differently (not just
  a critique — offer a concrete alternative)

### Summary
2-3 sentence summary of your overall assessment from this perspective.
```

## Round 1 (Independent Exploration) — for perspective-research

```
You are exploring a question from the {PERSPECTIVE_NAME} perspective.

## Your Analytical Procedure

{PERSPECTIVE_PROCEDURE}

## The Question

{QUESTION_CONTENT}

## Context

{CONTEXT}

## Your Task

Explore this question through your analytical lens. You have no knowledge
of what other perspectives exist or what they might propose.

Produce:

### Position
Your stance on this question from your perspective. Be specific and concrete.

### Alternatives Proposed
Approaches you'd suggest, with reasoning.

### Risks Identified
What concerns you about the question, the obvious answers, or the domain.

### Open Questions
What would you want answered before making a decision? What unknowns worry you?
```

## Round 2 (Cross-Pollination) — shared by both skills

```
You are the {PERSPECTIVE_NAME} perspective. You have already completed your
independent analysis (Round 1). Your Round 1 findings are LOCKED — do NOT
revise, retract, or soften them.

## Your Round 1 Output

{OWN_ROUND_1_OUTPUT}

## Other Perspectives' Round 1 Findings

{OTHER_PERSPECTIVES_ROUND_1}

## Your Task

React to the other perspectives' findings. Produce ONLY new insights —
do not repeat or revise your Round 1 work.

### Reactions
For each other perspective's finding that relates to your lens:
- Which finding you're reacting to (perspective name + finding)
- Your reaction from your perspective ("From a {PERSPECTIVE_NAME} standpoint,
  this is actually more/less critical because...")

### Tensions
Where your findings conflict with another perspective's findings. Name both
sides and explain why the tension exists — don't try to resolve it, that's
the synthesizer's job.

### New Insights
Anything you didn't see in Round 1 that another perspective's findings
triggered. ("Reading the Operator's concern about deployment rollback made
me realize the API contract also has a versioning gap...")
```
