# Diverse Perspective Skills Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use h-superpowers:subagent-driven-development, h-superpowers:team-driven-development, or h-superpowers:executing-plans to implement this plan (ask user which approach).

**Goal:** Create two skills (`perspective-review` and `perspective-research`) that bring diverse analytical perspectives to design docs, architecture decisions, plans, and research questions — with a shared perspective catalogue.

**Architecture:** Three directories — `skills/shared-perspectives/` (catalogue + shared prompts), `skills/perspective-review/` (evaluation skill), `skills/perspective-research/` (generative exploration skill). Each skill uses two rounds of parallel subagents plus a synthesis subagent. Perspective agents are standard subagents (not persistent teammates).

**Tech Stack:** Claude Code skills (SKILL.md + prompt templates), Agent tool with subagents

**Design doc:** `docs/plans/2026-03-08-diverse-perspective-skills-design.md`

---

### Task 1: Create Shared Perspective Catalogue

**Files:**
- Create: `skills/shared-perspectives/catalogue.md`

**Context:** This is the menu of analytical lenses both skills draw from. Each perspective must have a genuinely different analytical procedure (not just a different label) — this is the core insight from Basili's PBR research. The catalogue is reference material read by the orchestrating skill when it needs to select perspectives.

**Step 1: Write the perspective catalogue**

Create `skills/shared-perspectives/catalogue.md` with the following structure. Each perspective needs three things: a name, an analytical procedure (the specific method the agent follows — this is what makes PBR work), and what it catches.

```markdown
# Perspective Catalogue

Reference material for perspective-review and perspective-research skills.
Read this file when selecting perspectives for an artifact or question.

## Available Perspectives

### User/Consumer
**Analytical procedure:** Trace every user journey and API interaction through
the artifact. For each touchpoint, apply use-case modeling: identify the actor,
their goal, the preconditions, the main success scenario, and the extensions
(what happens when things go wrong). Ask: "If I'm a developer using this for
the first time, what confuses me? What's missing from the happy path?"

**Catches:** Usability gaps, missing edge cases, confusing interfaces, unclear
error messages, poor API ergonomics, undocumented assumptions about user behavior.

---

### Adversary
**Analytical procedure:** Assume this design has already failed catastrophically
in production — or has been exploited by a malicious actor. Work backward from
the failure: what went wrong? Apply pre-mortem analysis (Klein, 2007) by
generating specific failure scenarios. Then apply red-team thinking: identify
attack surfaces, trust boundaries crossed, data exposed, and assumptions that
an attacker would exploit. For each finding, assess: how likely is this, and
how bad is the impact?

**Catches:** Security vulnerabilities, unexamined assumptions, single points of
failure, missing threat modeling, overly optimistic assumptions about inputs,
failure modes that cascade.

---

### Operator
**Analytical procedure:** It's 3am and this system is on fire. Evaluate the
artifact through the lens of someone who must deploy, monitor, debug, and scale
this in production. For deployment: what are the steps, what can go wrong, how
do you roll back? For monitoring: what signals indicate health or degradation?
For debugging: when something fails, can you tell what happened and why? For
scaling: what happens at 10x load?

**Catches:** Observability gaps, deployment complexity, missing rollback plans,
operational burden, unclear failure signals, scaling cliffs, missing runbooks.

---

### Maintainer
**Analytical procedure:** Fast-forward 6 months. You are a new developer who
has never seen this codebase. Read the artifact as if encountering it for the
first time. For each component: can you understand what it does and why without
asking the author? Identify implicit knowledge — things the author knows but
didn't write down. Check coupling: if you change one thing, how many other
things break? Look for patterns that will accumulate tech debt over time.

**Catches:** Coupling, missing documentation, implicit knowledge dependencies,
fragile abstractions, naming that only makes sense with context, patterns that
don't scale as the codebase grows.

---

### Business/Strategy
**Analytical procedure:** Evaluate the artifact against organizational goals,
resource constraints, and opportunity cost. What does this cost to build and
maintain? Does it align with current priorities, or is it solving a problem
nobody asked for? What alternatives were not chosen, and what's the opportunity
cost? Is the complexity proportional to the business value? Would a simpler
solution deliver 80% of the value at 20% of the cost?

**Catches:** Over-engineering, misaligned priorities, hidden maintenance costs,
scope creep, solutions looking for problems, ignoring cheaper alternatives.

---

### Performance/Scale
**Analytical procedure:** Model the system under load. Identify the hot paths
— the operations that will be called most frequently. For each hot path: what's
the time complexity? What are the memory characteristics? Where are the I/O
boundaries? Project data growth: what happens when the dataset is 10x, 100x
current size? Identify resource consumption patterns and bottleneck candidates.
Look for O(n²) hiding in innocent-looking loops, unbounded caches, and
connection pool exhaustion.

**Catches:** Scaling cliffs, hot paths with poor complexity, resource exhaustion,
unbounded growth, missing pagination, N+1 queries, cache invalidation issues.

---

### Integrator
**Analytical procedure:** Map every boundary where this system touches another
system — APIs consumed, APIs exposed, data flows in and out, shared state,
event buses, file formats. For each boundary: what's the contract? What happens
when the other side changes? What happens when the other side is down? Are
versions compatible? Is there a migration path? Check for assumptions about
external systems that aren't guaranteed.

**Catches:** Integration failures, contract mismatches, missing error handling
at boundaries, version incompatibilities, migration gaps, assumptions about
external system behavior.

## Selecting Perspectives

When recommending perspectives for an artifact or question, consider:

1. **Artifact type:** Design docs benefit from Maintainer + User/Consumer.
   Architecture decisions benefit from Adversary + Performance/Scale.
   Plans benefit from Operator + Business/Strategy.
2. **Domain signals:** Security-sensitive → Adversary. User-facing → User/Consumer.
   Infrastructure → Operator. API design → Integrator + User/Consumer.
3. **Cap at 3-4:** Per collective intelligence research (Woolley et al.),
   3-4 perspectives is the sweet spot. More than 4 adds coordination overhead
   that degrades quality.
4. **Explain why:** For each recommended perspective, state why it's relevant
   to this specific artifact — not just generic reasoning.
```

**Step 2: Verify the file was created correctly**

Run: `cat skills/shared-perspectives/catalogue.md | head -20`
Expected: File header and first perspective visible

**Step 3: Commit**

```bash
git add skills/shared-perspectives/catalogue.md
git commit -m "feat: add shared perspective catalogue for diverse review skills"
```

---

### Task 2: Create Shared Prompt Templates

**Files:**
- Create: `skills/shared-perspectives/perspective-agent-prompt.md`
- Create: `skills/shared-perspectives/synthesis-agent-prompt.md`

**Context:** These are prompt templates used by both skills when spawning perspective subagents and the synthesis subagent. They contain placeholders filled in by the orchestrating skill.

**Step 1: Write the perspective agent prompt template**

Create `skills/shared-perspectives/perspective-agent-prompt.md`:

```markdown
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
  a critique — offer a concrete alternative per Microsoft research showing
  alternatives are more valuable than defect-finding)

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
```

**Step 2: Write the synthesis agent prompt template**

Create `skills/shared-perspectives/synthesis-agent-prompt.md`:

```markdown
# Synthesis Agent Prompt Template

Used by perspective-review and perspective-research to consolidate findings.

## For perspective-review

```
You are the synthesis agent. Your job is to consolidate findings from
multiple perspective agents into a structured report. You maintain a
CLEAN SEPARATION between Round 1 (independent) and Round 2
(cross-pollination) findings.

## Round 1 Findings (Independent — Uncontaminated)

{ALL_ROUND_1_OUTPUTS}

## Round 2 Findings (Cross-Pollination)

{ALL_ROUND_2_OUTPUTS}

## Your Task

Produce the following report. The structural separation between Round 1
and Round 2 is not cosmetic — it preserves the epistemic integrity of
the independent analysis. Round 1 consensus concerns carry the highest
confidence because they emerged independently with no anchoring bias.

### Independent Findings (Round 1)

#### Consensus Concerns
Issues flagged independently by 2+ perspectives. These are highest
confidence — multiple independent analytical procedures converged on
the same concern without cross-contamination. For each: which perspectives
flagged it, what they each said, and the synthesized concern.

#### Unique Findings
Findings that only one perspective caught. Organize by perspective.
These are valuable precisely because they required a specific analytical
lens to see.

### Cross-Pollination Insights (Round 2)

#### Tradeoff Tensions
Where perspectives explicitly conflict. Present both sides fairly.
These require the user's judgment — they are genuine tradeoffs, not
issues with a clear right answer.

#### Amplified Concerns
Round 1 findings that other perspectives validated or escalated in
Round 2. These are Round 1 findings with additional weight.

#### New Insights
Things that emerged ONLY from the cross-pollination — not present in
any Round 1 output. Flag these clearly as interaction-dependent insights.

### Suggested Alternatives
Concrete alternative approaches surfaced across both rounds. For each:
which perspective proposed it, what problem it solves, and what tradeoff
it introduces.

### Blind Spots
Areas the selected perspectives didn't adequately cover. Recommend which
additional perspectives (from the catalogue) might address these gaps if
the user wants deeper analysis.
```

## For perspective-research

```
You are the synthesis agent. Your job is to consolidate multiple
perspectives' exploration of a question into actionable output.

## Round 1 Positions (Independent)

{ALL_ROUND_1_OUTPUTS}

## Round 2 Cross-Pollination

{ALL_ROUND_2_OUTPUTS}

## The Original Question

{QUESTION_CONTENT}

## Your Task

### Positions Summary
For each perspective: their stance, key alternatives, and top risks.
Keep it concise — the detail is in the per-perspective sections above.

### Cross-Pollination Results

#### Hybrid Approaches
New approaches that emerged from perspectives building on each other.
These are the cross-pollination's primary value — ideas no single
perspective would have generated alone.

#### Challenges & Rebuttals
Where perspectives challenged each other. Present the exchange:
who said what, and whether the challenge was convincing.

#### Converging Themes
Where multiple perspectives independently or reactively aligned.
High confidence that these themes are important.

### Recommendation
Your synthesized recommendation:
- **Recommended approach:** (with confidence: High/Medium/Low)
- **Key tradeoffs to accept:** (be honest about costs)
- **Mitigations for top risks:** (from across all perspectives)
- **Investigate further before deciding:** (open questions that matter)

### Decision Record (ADR Template)

# [Decision Title]

## Status
Proposed

## Context
[Synthesized from all perspectives' analysis of the question]

## Decision
[The recommended approach]

## Alternatives Considered
[From all perspectives' proposals, with reasoning for/against each]

## Consequences
### Positive
[Benefits identified across perspectives]

### Negative
[Costs and tradeoffs identified across perspectives]

### Risks
[Top risks with mitigations]
```
```

**Step 3: Verify files created**

Run: `ls skills/shared-perspectives/`
Expected: `catalogue.md`, `perspective-agent-prompt.md`, `synthesis-agent-prompt.md`

**Step 4: Commit**

```bash
git add skills/shared-perspectives/perspective-agent-prompt.md skills/shared-perspectives/synthesis-agent-prompt.md
git commit -m "feat: add shared prompt templates for perspective and synthesis agents"
```

---

### Task 3: Create perspective-review SKILL.md

**Files:**
- Create: `skills/perspective-review/SKILL.md`

**Context:** This is the main skill file for the review skill. It contains the frontmatter (name + description for triggering), the orchestration process, and instructions for reading shared resources. Follow the existing skill patterns in the project — see `skills/team-driven-development/SKILL.md` for a good reference of a complex orchestration skill.

**Step 1: Write the SKILL.md**

Create `skills/perspective-review/SKILL.md`:

```markdown
---
name: perspective-review
description: Use when you want diverse analytical perspectives on an existing artifact — design docs, architecture decisions, plans, or any document worth scrutinizing. Spawns 3-4 perspective agents with genuinely different analytical procedures, runs independent analysis then cross-pollination, and synthesizes findings with clean separation between independent and reactive insights. Use this whenever the user mentions reviewing a design, getting feedback on a plan, checking an architecture, or wanting a second opinion on a document.
---

# Perspective Review

Evaluate existing artifacts through multiple diverse analytical perspectives,
using two rounds (independent analysis + cross-pollination) with clean
separation in the output.

**Core principle:** Independent diverse analysis (PBR-style) catches more
unique issues than multiple reviewers using the same approach. Cross-pollination
adds tradeoff tensions and interaction insights without contaminating the
independent findings.

## When to Use

- Reviewing a design doc before implementation
- Scrutinizing an architecture decision
- Getting diverse feedback on a plan
- Any existing artifact the user wants examined from multiple angles

**Not for:** Task-level code review (use requesting-code-review instead)

## Process

### Step 1: Read the artifact

Read the artifact the user provides (file path or inline content). Classify it:
- **Design doc** — describes what will be built and how
- **Architecture decision** — evaluates approaches or makes structural choices
- **Plan** — sequences implementation steps
- **Other** — any document worth scrutinizing

### Step 2: Recommend perspectives

Read the perspective catalogue at `../shared-perspectives/catalogue.md`.

Based on the artifact type and content, recommend 3-4 perspectives with
one sentence each explaining why that perspective is relevant to THIS
specific artifact. Follow the selection guidance in the catalogue.

Present to the user:

"I'd recommend these perspectives for reviewing [artifact]:
- **[Perspective]**: [why it's relevant here]
- **[Perspective]**: [why it's relevant here]
- **[Perspective]**: [why it's relevant here]

Want to adjust — add, remove, or swap any?"

Wait for user confirmation before proceeding.

### Step 3: Round 1 — Independent Analysis

Read `../shared-perspectives/perspective-agent-prompt.md` for the Round 1
review template.

Spawn one subagent per perspective IN PARALLEL using the Agent tool.
Each subagent receives:
- The Round 1 review template filled with their perspective's procedure
  (from the catalogue) and the full artifact content
- No knowledge of other perspectives

Collect all Round 1 outputs.

### Step 4: Round 2 — Cross-Pollination

Using the Round 2 template from `../shared-perspectives/perspective-agent-prompt.md`,
spawn one subagent per perspective IN PARALLEL.

Each subagent receives:
- Their own Round 1 output (locked, not to be revised)
- All OTHER perspectives' Round 1 outputs
- Instructions to produce only NEW reactions, tensions, and insights

Collect all Round 2 outputs.

### Step 5: Synthesis

Read `../shared-perspectives/synthesis-agent-prompt.md` for the review
synthesis template.

Spawn a synthesis subagent that receives:
- All Round 1 outputs (labeled by perspective and round)
- All Round 2 outputs (labeled by perspective and round)
- Instructions to maintain clean structural separation

### Step 6: Present results

Present the synthesis report to the user. The report maintains the
Round 1 / Round 2 separation so the user can trust independent findings
as uncontaminated and treat cross-pollination as enrichment.

## Integration

**Invoked after:**
- `h-superpowers:brainstorming` — review the design doc it produced
- User directly — on any existing artifact

**Hands off to:**
- `h-superpowers:writing-plans` — if review leads to implementation
- `h-superpowers:brainstorming` — if review reveals the design needs rework

**Does NOT replace:**
- Task-level spec/code-quality review in `team-driven-development`
- `requesting-code-review` for implementation-level review
```

**Step 2: Verify the file**

Run: `head -5 skills/perspective-review/SKILL.md`
Expected: Frontmatter with name and description

**Step 3: Commit**

```bash
git add skills/perspective-review/SKILL.md
git commit -m "feat: add perspective-review skill"
```

---

### Task 4: Create perspective-research SKILL.md

**Files:**
- Create: `skills/perspective-research/SKILL.md`

**Context:** The research skill is generative — perspectives build on each other by design. Cross-pollination is the primary mechanism, not optional enrichment. The output includes a pre-formatted ADR template.

**Step 1: Write the SKILL.md**

Create `skills/perspective-research/SKILL.md`:

```markdown
---
name: perspective-research
description: Use when exploring open questions, architecture decisions, technology choices, or any decision that benefits from diverse perspectives BEFORE committing to an approach. Spawns 3-4 perspective agents that independently explore the question, then cross-pollinate to build hybrid approaches and challenge each other's positions. Produces a recommendation with confidence level and a pre-formatted ADR. Use this whenever the user asks "should we use X or Y?", "what's the best way to handle Z?", "what are the risks of...", or any open-ended exploration question.
---

# Perspective Research

Explore open questions and generate alternatives through diverse perspectives
before decisions are made. Cross-pollination is the primary mechanism — perspectives
build on each other to produce hybrid approaches no single lens would generate alone.

**Core principle:** Generative exploration benefits from dialogue between perspectives.
Pre-mortem research shows prospective hindsight improves outcome prediction by 30%,
but only when participants build on each other's scenarios.

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

Read the perspective catalogue at `../shared-perspectives/catalogue.md`.

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

Spawn one subagent per perspective IN PARALLEL using the Agent tool.
Each subagent receives:
- The Round 1 research template filled with their perspective's procedure
  (from the catalogue), the question, and any relevant context
- No knowledge of other perspectives

Collect all Round 1 outputs.

### Step 4: Round 2 — Cross-Pollination (Primary Mechanism)

Using the Round 2 template from `../shared-perspectives/perspective-agent-prompt.md`,
spawn one subagent per perspective IN PARALLEL.

Each subagent receives:
- Their own Round 1 output
- All OTHER perspectives' Round 1 outputs
- Instructions to build on others' alternatives, challenge positions,
  synthesize hybrid approaches, and identify assumptions

This round is where the primary value emerges. Unlike perspective-review
where cross-pollination is enrichment, here it IS the mechanism.

Collect all Round 2 outputs.

### Step 5: Synthesis

Read `../shared-perspectives/synthesis-agent-prompt.md` for the research
synthesis template.

Spawn a synthesis subagent that receives:
- All Round 1 outputs (labeled)
- All Round 2 outputs (labeled)
- The original question
- Instructions to produce recommendation + ADR template

### Step 6: Present results

Present the synthesis report to the user. Highlight:
- The recommended approach with confidence level
- Key tradeoffs they must accept
- The pre-formatted ADR template they can adopt or edit

Offer: "Want me to save the decision record to `docs/decisions/`?"

## Integration

**Invoked before:**
- `h-superpowers:brainstorming` — research informs the design
- `h-superpowers:writing-plans` — if decision is made, go straight to planning

**Hands off to:**
- `h-superpowers:brainstorming` — to design based on research findings
- `h-superpowers:writing-plans` — if the question was narrow and the answer
  is clear enough to plan directly

**Does NOT replace:**
- `h-superpowers:brainstorming` — research explores the question space,
  brainstorming designs the solution
```

**Step 2: Verify the file**

Run: `head -5 skills/perspective-research/SKILL.md`
Expected: Frontmatter with name and description

**Step 3: Commit**

```bash
git add skills/perspective-research/SKILL.md
git commit -m "feat: add perspective-research skill"
```

---

### Task 5: Update using-superpowers Skill

**Files:**
- Modify: `skills/using-superpowers/SKILL.md`

**Context:** The using-superpowers skill is the entry point that lists all available skills. The two new skills need to be registered there so Claude knows they exist and when to trigger them.

**Step 1: Read the current using-superpowers SKILL.md**

Read the full file to understand the current skill listing format.

**Step 2: Add perspective-review and perspective-research**

Add entries for both new skills in the appropriate location within the skill listing, following the existing format exactly. The description should match the frontmatter description from each skill's SKILL.md.

**Step 3: Verify the entries are present**

Run: `grep -n "perspective" skills/using-superpowers/SKILL.md`
Expected: Both skill entries visible

**Step 4: Commit**

```bash
git add skills/using-superpowers/SKILL.md
git commit -m "feat: register perspective-review and perspective-research in using-superpowers"
```

---

### Task 6: Iterate with skill-creator

**Files:**
- Create: test artifacts in `skill-improvement-workspace/` (or wherever skill-creator places them)

**Context:** Use the skill-creator workflow to create test cases, run the skills against them, evaluate results, and iterate. This is NOT a code task — it's an interactive evaluation loop with the user.

**Step 1: Create test artifacts**

Create 2-3 realistic test artifacts with known weaknesses:
1. A design doc with a security gap and an over-engineered component
2. An architecture decision (X vs Y) with hidden tradeoffs
3. A plan with operational blind spots

**Step 2: Run perspective-review against test artifact 1**

Invoke the skill against the design doc. Evaluate:
- Does Round 1 stay uncontaminated?
- Does each perspective use a genuinely different analytical procedure?
- Does Round 2 add new insights vs. repeating Round 1?
- Does synthesis maintain clean Round 1 / Round 2 separation?
- Did the recommendation engine suggest appropriate perspectives?

**Step 3: Run perspective-research against test artifact 2**

Invoke the skill against the architecture decision. Evaluate:
- Do perspectives generate genuinely different positions?
- Does Round 2 produce hybrid approaches?
- Does synthesis produce a useful recommendation with honest tradeoffs?
- Is the ADR template usable as-is?

**Step 4: Iterate**

Based on evaluation results, refine the SKILL.md files and prompt templates.
Repeat until the three-layer structure holds up mechanically.
