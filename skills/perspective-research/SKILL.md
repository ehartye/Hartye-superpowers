---
name: perspective-research
description: Use when exploring open questions, architecture decisions, technology choices, or any decision that benefits from diverse perspectives BEFORE committing to an approach. Spawns 3-4 perspective agents that independently explore the question, then cross-pollinate to build hybrid approaches and challenge each other's positions. Produces a recommendation with confidence level and a pre-formatted ADR. Use this whenever the user asks "should we use X or Y?", "what's the best way to handle Z?", "what are the risks of...", or any open-ended exploration question.
---

# Perspective Research

Explore open questions and generate alternatives through diverse perspectives
before decisions are made. Cross-pollination is the primary mechanism —
perspectives build on each other to produce hybrid approaches no single
lens would generate alone.

**Core principle:** Generative exploration benefits from dialogue between
perspectives. Pre-mortem research shows prospective hindsight improves outcome
prediction by 30%, but only when participants build on each other's scenarios.

## When to Use

- "Should we use X or Y approach?"
- "What's the best way to handle Z?"
- "What are the risks of this architecture?"
- "Explore the tradeoffs of migrating to..."
- Any open question where diverse perspectives would help before deciding

**Not for:** Evaluating an existing artifact (use perspective-review instead)

## Process

### Step 1: Understand the question

Read the user's question or topic. Classify it:
- **Architecture decision** — X vs Y, structural choices
- **Open exploration** — how should we approach...
- **Risk assessment** — what could go wrong with...
- **Technology evaluation** — should we adopt...

If the question is vague, ask one clarifying question before proceeding.
Gather any relevant context (existing codebase, constraints, prior decisions).

### Step 2: Recommend perspectives

Read the perspective catalogue at `../shared-perspectives/catalogue.md`
(relative to this skill's directory).

Based on the question type and domain, recommend 3-4 perspectives with
reasoning. Follow the selection guidance in the catalogue.

Present to the user:

"I'd recommend these perspectives for exploring [question]:
- **[Perspective]**: [why it's relevant here]
- **[Perspective]**: [why it's relevant here]
- **[Perspective]**: [why it's relevant here]

Want to adjust — add, remove, or swap any?"

Wait for user confirmation before proceeding.

### Step 3: Round 1 — Independent Exploration

Read `../shared-perspectives/perspective-agent-prompt.md` for the Round 1
research template.

For each confirmed perspective, look up its full analytical procedure from
the catalogue. Fill the Round 1 research template with:
- `{PERSPECTIVE_NAME}` — the perspective name
- `{PERSPECTIVE_PROCEDURE}` — the full analytical procedure from the catalogue
- `{QUESTION_CONTENT}` — the user's question
- `{CONTEXT}` — any relevant context gathered in Step 1

Spawn one subagent per perspective **in parallel** using the Agent tool.
Each subagent receives the filled template as its prompt. They have no
knowledge of other perspectives.

Collect all Round 1 outputs.

### Step 4: Round 2 — Cross-Pollination (Primary Mechanism)

Read the Round 2 template from `../shared-perspectives/perspective-agent-prompt.md`.

For each perspective, fill the Round 2 template with:
- `{PERSPECTIVE_NAME}` — their perspective name
- `{OWN_ROUND_1_OUTPUT}` — this perspective's Round 1 output
- `{OTHER_PERSPECTIVES_ROUND_1}` — all OTHER perspectives' Round 1 outputs,
  labeled by perspective name

Spawn one subagent per perspective **in parallel**. Each receives their own
Round 1 output and all others' Round 1 outputs.

This round is where the primary value emerges. Unlike perspective-review
where cross-pollination enriches independent findings, here it IS the
mechanism — perspectives build on each other to generate hybrid approaches
and challenge positions.

Collect all Round 2 outputs.

### Step 5: Synthesis

Read `../shared-perspectives/synthesis-agent-prompt.md` for the research
synthesis template.

Fill the template with:
- `{ALL_ROUND_1_OUTPUTS}` — all Round 1 outputs, labeled by perspective
- `{ALL_ROUND_2_OUTPUTS}` — all Round 2 outputs, labeled by perspective
- `{QUESTION_CONTENT}` — the original question

Spawn a synthesis subagent with the filled template. The synthesis agent
produces a recommendation with confidence level and a pre-formatted ADR.

### Step 6: Present results

Present the synthesis report to the user. Highlight:
- The recommended approach with confidence level
- Key tradeoffs they must accept
- The pre-formatted ADR template they can adopt or edit

Offer: "Want me to save the decision record to `docs/decisions/`?"

If the user wants to proceed:
- "Want to design a solution based on this?" → brainstorming
- "Ready to plan implementation?" → writing-plans

## Integration

**Invoked before:**
- `h-superpowers:brainstorming` — research informs the design
- `h-superpowers:writing-plans` — if decision is clear, go straight to planning

**Hands off to:**
- `h-superpowers:brainstorming` — to design based on research findings
- `h-superpowers:writing-plans` — if the question was narrow and the answer
  is clear enough to plan directly

**Does NOT replace:**
- `h-superpowers:brainstorming` — research explores the question space,
  brainstorming designs the solution
