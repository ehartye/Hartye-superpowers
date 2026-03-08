---
name: perspective-research
description: Use when exploring open questions, architecture decisions, technology choices, or any decision that benefits from diverse perspectives BEFORE committing to an approach. Spawns perspective subagents that independently explore the question and codebase, then cross-pollinate to build hybrid approaches via a second round. Produces a recommendation with confidence level and ADR. Use this whenever the user asks "should we use X or Y?", "what's the best way to handle Z?", "what are the risks of...", or any open-ended exploration question.
---

# Perspective Research

Explore open questions through diverse perspectives. Each perspective subagent
gets its own context window, independently explores the codebase and question,
then a cross-pollination round lets perspectives build on each other to produce
hybrid approaches no single lens would generate alone.

**Core principle:** Generative exploration benefits from dialogue between
perspectives. Pre-mortem research shows prospective hindsight improves outcome
prediction by 30%, but only when participants build on each other's scenarios.

## When to Use

- "Should we use X or Y approach?"
- "What's the best way to handle Z?"
- "What are the risks of this architecture?"
- "What tech stack should we use for this?"
- "Are we following best practices for X?"
- Any open question where diverse perspectives would help before deciding

**Not for:** Evaluating an existing artifact (use perspective-review instead)

## Process

### Step 1: Understand the question

Read the user's question or topic. Gather relevant context from the codebase
(existing implementations, constraints, prior decisions) using Read, Glob, Grep.

If the question is vague, ask one clarifying question.

### Step 2: Recommend perspectives

Read the perspective catalogue at `../shared-perspectives/catalogue.md`.

The catalogue has two families of perspectives:
- **Role-based** (Adversary, Operator, Maintainer, etc.) — who is looking
- **Discipline-based** (Design Principles, Testing Strategy, etc.) — what lens

Mix them based on the question. Tech stack evaluations benefit from role-based
perspectives (Business/Strategy, Operator, Integrator). Best practices
questions lean toward discipline-based (Design Principles, Conventions & Idioms).
Many questions benefit from a mix. See the catalogue's selection guidance.

If the user requests a lens not in the catalogue, create a custom perspective
with a specific analytical procedure (see catalogue's "Custom Perspectives"
section).

Recommend 3-4 perspectives with reasoning. Present to the user:

"I'd recommend these perspectives for exploring [question]:
- **[Perspective]** *(role/discipline/custom)*: [why it's relevant here]
- ...

Want to adjust — add, remove, or swap any?"

Wait for confirmation.

### Step 3: Set up workspace

Create a temporary directory for round outputs:

```
<workspace>/
  round-1/
  round-2/
```

### Step 4: Round 1 — Independent Exploration

Read `../shared-perspectives/perspective-subagent-prompt.md` for the Round 1
research template.

For each confirmed perspective, look up its full analytical procedure from
the catalogue. Fill the Round 1 research template with:
- `{PERSPECTIVE_NAME}` — the perspective name
- `{PERSPECTIVE_PROCEDURE}` — the full analytical procedure from the catalogue
- `{QUESTION_CONTENT}` — the user's question
- `{CONTEXT}` — any relevant context gathered in Step 1
- `{OUTPUT_PATH}` — where to save position (e.g., `<workspace>/round-1/adversary.md`)

Spawn one subagent per perspective **in parallel** using the Agent tool.
Each subagent independently explores the codebase and saves its position
to the output file.

**Capture each subagent's agent ID** from the return value — you will resume
these agents in Round 2.

**Wait for all Round 1 subagents to complete.**

### Step 5: Round 2 — Cross-Pollination (Primary Mechanism)

**Resume** each Round 1 subagent using the Agent tool's `resume` parameter
with the agent ID captured in Step 4. The resumed agent retains its full
Round 1 context — every file it read, every constraint it found — so it can
propose deeply informed hybrid approaches.

Read the Round 2 template from `../shared-perspectives/perspective-subagent-prompt.md`.

Send each resumed agent:
- Paths to all OTHER perspectives' Round 1 output files, labeled by name
- `{OUTPUT_PATH}` — where to save cross-pollination response
- Instruction that its Round 1 position is LOCKED — react only, do not revise

Resume all perspectives **in parallel**.

This round is where the primary value emerges — perspectives build on each
other to generate ideas no single perspective would produce alone.

**Wait for all Round 2 subagents to complete.**

### Step 6: Synthesis

Read `../shared-perspectives/synthesis-agent-prompt.md` for the research
synthesis template.

Fill the template with:
- `{ROUND_1_PATHS}` — paths to all Round 1 output files, labeled by perspective
- `{ROUND_2_PATHS}` — paths to all Round 2 output files, labeled by perspective
- `{QUESTION_CONTENT}` — the original question

Spawn a synthesis subagent. It reads all output files and produces the
recommendation with confidence level and ADR template.

Save the final report.

### Step 7: Present results

Present the synthesis report to the user. Highlight:
- The recommended approach with confidence level
- Key tradeoffs they must accept
- The pre-formatted ADR template

Offer: "Want me to save the decision record to `docs/decisions/`?"

If the user wants to proceed:
- "Want to design a solution based on this?" -> brainstorming
- "Ready to plan implementation?" -> writing-plans

## Integration

**Invoked before:**
- `h-superpowers:brainstorming` — research informs the design
- `h-superpowers:writing-plans` — if decision is clear, plan directly

**Hands off to:**
- `h-superpowers:brainstorming` — to design based on findings
- `h-superpowers:writing-plans` — if answer is clear enough to plan

**Does NOT replace:**
- `h-superpowers:brainstorming` — research explores the question space,
  brainstorming designs the solution
