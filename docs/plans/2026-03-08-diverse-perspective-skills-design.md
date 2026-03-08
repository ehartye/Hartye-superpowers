# Diverse Perspective Skills Design

**Date:** 2026-03-08
**Status:** Approved

## Problem

The existing review infrastructure (spec-reviewer, code-quality-reviewer) operates
at the task level during implementation. There is no mechanism for bringing diverse
analytical perspectives to bear on upstream artifacts — design docs, architecture
decisions, plans, and research questions — where the cost of catching issues is
lowest and the value of alternative ideas is highest.

## Research Foundation

This design draws from empirically validated review methodologies:

- **Perspective-Based Reading (Basili, 1996):** Assigning reviewers genuinely
  different analytical procedures (not just labels) increases unique defect
  detection by ~41%. Independence during analysis is critical.
- **Pre-Mortem (Klein, HBR 2007):** Prospective hindsight improves identification
  of failure reasons by 30%. Structurally mandated adversarial roles outperform
  optional dissent.
- **ATAM (SEI/CMU):** Architecture Tradeoff Analysis Method surfaces sensitivity
  points and tradeoff tensions through multi-stakeholder scenario analysis.
- **Collective Intelligence (Woolley et al., Science):** Cognitive diversity has an
  inverted-U relationship with team performance — 3-5 perspectives is the sweet
  spot before coordination overhead degrades quality.
- **Microsoft Code Review Research:** Review value comes largely from knowledge
  transfer and generation of alternatives, not just defect detection. Agents should
  offer alternatives, not just critiques.
- **Cross-Functional Review:** Independent domain perspectives (security, ops, UX,
  business) catch fundamentally different classes of issues.

## Solution: Two Skills

### Skill 1: `perspective-review`

Evaluates existing artifacts through multiple diverse analytical perspectives.

**Invoked on:** Design docs, plans, architecture decisions, any existing artifact.

**Process:**

1. Read artifact, classify type (design doc, plan, architecture decision)
2. Recommend 3-4 perspectives from catalogue with reasoning
3. User confirms/adjusts perspective selection
4. **Round 1 — Independent Analysis (parallel, PBR-style):**
   Each perspective agent applies its unique analytical procedure in isolation.
   No knowledge of other perspectives' existence. Produces findings, confidence
   levels, and suggested alternatives.
5. **Round 2 — Cross-Pollination (parallel, ATAM-style):**
   Each perspective agent receives all Round 1 findings from other perspectives.
   Explicitly instructed: do NOT revise Round 1 findings. Produce only new
   reactions — tensions, validations, and new insights triggered by others' work.
   Round 1 analysis is locked.
6. **Synthesis agent** receives both rounds as separate labeled inputs. Produces
   structured report maintaining clean separation between independent findings
   and cross-pollination insights.

**Output structure:**

```markdown
# Perspective Review: [Artifact Name]

## Independent Findings (Round 1)
### Consensus Concerns
[Issues flagged independently by 2+ perspectives — highest confidence,
 no anchoring bias possible]

### Unique Findings
[Per perspective — things only that lens caught, from isolated analysis]

## Cross-Pollination Insights (Round 2)
### Tradeoff Tensions
[Conflicts that emerged when perspectives reacted to each other]

### Amplified Concerns
[Round 1 findings that other perspectives validated or escalated]

### New Insights
[Things that only emerged from the interaction]

## Suggested Alternatives
[Alternative approaches from both rounds]

## Blind Spots
[Areas neither round adequately covered]
```

**Key design decision:** Round 1 findings are structurally uncontaminated — they
come from physically separate agent invocations with no cross-perspective input.
The synthesis agent maintains this separation in the output so the reader can trust
Round 1 as independent analysis and treat Round 2 as enrichment.

### Skill 2: `perspective-research`

Explores open questions and generates alternatives through diverse perspectives
before decisions are made.

**Invoked on:** Architecture decisions, technology choices, risk assessments,
open-ended exploration questions.

**Process:**

1. Receive question/topic from user
2. Classify question type (architecture decision, open exploration, risk
   assessment, technology evaluation)
3. Recommend 3-4 perspectives from catalogue with reasoning
4. User confirms/adjusts perspective selection
5. **Round 1 — Independent Exploration (parallel):**
   Each perspective researches and generates their position, alternatives,
   risks, and open questions from their lens.
6. **Round 2 — Cross-Pollination (parallel, primary mechanism):**
   Each perspective receives all Round 1 positions and builds on others'
   alternatives, challenges positions with reasoning, synthesizes hybrid
   approaches, and identifies others' assumptions. Cross-pollination is the
   core value here — not optional.
7. **Synthesis agent** produces structured output with recommendation and
   pre-formatted ADR template.

**Output structure:**

```markdown
# Perspective Research: [Question/Topic]

## Question Analyzed
[Original question, classified by type]

## Perspectives Applied
- [Perspective]: [why selected]

## Positions (Round 1)
### [Perspective Name]
- Position: [stance/analysis]
- Alternatives proposed: [suggestions]
- Risks identified: [concerns]
- Open questions: [unknowns]

## Cross-Pollination (Round 2)
### Hybrid Approaches
[New approaches from perspectives building on each other]

### Challenges & Rebuttals
[Where perspectives challenged each other, with reasoning]

### Converging Themes
[Areas of alignment across perspectives]

## Recommendation
- Recommended approach (with confidence level)
- Key tradeoffs to accept
- Mitigations for top risks
- What to investigate further before deciding

## Decision Record
[Pre-formatted ADR template]
```

**Key design decision:** Cross-pollination is the primary mechanism here, not an
enrichment layer. The research skill's purpose is generative — perspectives should
build on each other. Pre-mortem and ATAM evidence shows the most valuable insights
emerge from stakeholder dialogue, not independent analysis.

### Shared: Perspective Catalogue

Located at `skills/shared-perspectives/`. A menu of analytical lenses, each with
a genuinely different procedure (per PBR research — procedural differentiation
is what drives results).

| Perspective | Analytical Procedure | What It Catches |
|---|---|---|
| **User/Consumer** | Traces user journeys and API ergonomics. Applies use-case modeling. | Usability gaps, missing edge cases, confusing interfaces |
| **Adversary** | Assumes failure/exploitation has occurred. Works backward. Pre-mortem + red team. | Security holes, failure modes, unexamined assumptions |
| **Operator** | Evaluates deployment, monitoring, scaling, incident response. | Observability gaps, deployment complexity, operational burden |
| **Maintainer** | Fast-forwards 6 months. New developer reads this. What's confusing? Fragile? | Coupling, missing docs, implicit knowledge, tech debt |
| **Business/Strategy** | Evaluates cost, goal alignment, opportunity cost of alternatives not chosen. | Over-engineering, misaligned priorities, hidden costs |
| **Performance/Scale** | Models load, data growth, resource consumption. Identifies bottlenecks. | Scaling cliffs, hot paths, resource exhaustion |
| **Integrator** | Examines interactions with existing systems, APIs, data flows. | Integration failures, contract mismatches, migration gaps |

The catalogue is extensible. Both skills include a recommendation engine that reads
the artifact, classifies it, and suggests 3-4 perspectives with reasoning. The user
confirms before agents are dispatched.

**Perspective cap:** 3-4 perspectives per invocation (Woolley's inverted-U finding),
plus a synthesis agent.

## Integration

### Workflow Position

```
perspective-research → brainstorming → perspective-review → writing-plans
       ↑                                      ↑
  Open questions,                    Design docs, plans,
  architecture decisions             architecture decisions
```

- `perspective-research` feeds into `brainstorming` or `writing-plans`
- `brainstorming` produces design docs that can be reviewed by `perspective-review`
- Neither skill replaces task-level spec/code-quality review in `team-driven-development`

### Agent Infrastructure

Both skills use the `Agent` tool with standard subagents (not persistent teammates).
Perspectives are independent — they don't need persistence or direct messaging.
Two rounds of parallel subagent dispatch, followed by a synthesis subagent.

### ADR Output

The research skill produces a pre-formatted ADR template in its output, intended
for `docs/decisions/` if the user adopts it.

## Refinement Plan

Use skill-creator workflow to iterate:

1. Create test artifacts with known weaknesses/tradeoffs
2. Run both skills against them
3. Evaluate via skill-creator's eval viewer:
   - Does Round 1 stay uncontaminated in perspective-review?
   - Does Round 2 add genuine new insights vs. noise?
   - Does synthesis maintain clean separation?
   - Are the right perspectives being recommended?
4. Quantitative assertions on structural integrity
5. Iterate until the three-layer approach holds up mechanically

## Decisions

- **Two skills, not one:** Evaluation and ideation use fundamentally different
  procedures. Combining them risks diluting both.
- **Shared perspective catalogue:** Both skills draw from the same menu, maintained
  once in `skills/shared-perspectives/`.
- **Three-layer output for review:** Independent findings, cross-pollination
  insights, and synthesis — structurally separated to preserve Round 1 integrity.
- **Cross-pollination primary in research, enrichment in review:** Matches the
  research — generative work benefits from dialogue, evaluative work benefits
  from independence.
- **3-4 perspective cap:** Based on collective intelligence research (inverted-U).
- **Subagents, not persistent teammates:** Perspectives are independent per
  invocation. No need for the cost/complexity of agent teams.
