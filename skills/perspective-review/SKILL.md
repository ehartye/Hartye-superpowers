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

Read the perspective catalogue at `../shared-perspectives/catalogue.md`
(relative to this skill's directory).

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

For each confirmed perspective, look up its full analytical procedure from
the catalogue. Fill the Round 1 review template with:
- `{PERSPECTIVE_NAME}` — the perspective name
- `{PERSPECTIVE_PROCEDURE}` — the full analytical procedure from the catalogue
- `{ARTIFACT_CONTENT}` — the full artifact text

Spawn one subagent per perspective **in parallel** using the Agent tool.
Each subagent receives the filled template as its prompt. They have no
knowledge of other perspectives.

Collect all Round 1 outputs.

### Step 4: Round 2 — Cross-Pollination

Read the Round 2 template from `../shared-perspectives/perspective-agent-prompt.md`.

For each perspective, fill the Round 2 template with:
- `{PERSPECTIVE_NAME}` — their perspective name
- `{OWN_ROUND_1_OUTPUT}` — this perspective's Round 1 output
- `{OTHER_PERSPECTIVES_ROUND_1}` — all OTHER perspectives' Round 1 outputs,
  labeled by perspective name

Spawn one subagent per perspective **in parallel**. Each receives their own
Round 1 output (locked) and all others' Round 1 outputs.

Collect all Round 2 outputs.

### Step 5: Synthesis

Read `../shared-perspectives/synthesis-agent-prompt.md` for the review
synthesis template.

Fill the template with:
- `{ALL_ROUND_1_OUTPUTS}` — all Round 1 outputs, labeled by perspective
- `{ALL_ROUND_2_OUTPUTS}` — all Round 2 outputs, labeled by perspective

Spawn a synthesis subagent with the filled template. The synthesis agent
maintains clean structural separation between Round 1 and Round 2 findings.

### Step 6: Present results

Present the synthesis report to the user. The report maintains the
Round 1 / Round 2 separation so the user can trust independent findings
as uncontaminated and treat cross-pollination as enrichment.

If the review surfaces significant concerns, offer next steps:
- "Want me to revise the design based on these findings?" → brainstorming
- "Ready to proceed to implementation?" → writing-plans

## Integration

**Invoked after:**
- `h-superpowers:brainstorming` — review the design doc it produced
- User directly — on any existing artifact

**Hands off to:**
- `h-superpowers:writing-plans` — if review is clean, proceed to planning
- `h-superpowers:brainstorming` — if review reveals the design needs rework

**Does NOT replace:**
- Task-level spec/code-quality review in `team-driven-development`
- `requesting-code-review` for implementation-level review
