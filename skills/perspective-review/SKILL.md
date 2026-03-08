---
name: perspective-review
description: Use when you want diverse analytical perspectives on a project, codebase, design doc, or any artifact worth scrutinizing. Spawns perspective subagents that independently traverse the project, then cross-pollinate findings via a second round, and synthesizes results with clean separation. Use this whenever the user mentions reviewing a design, getting feedback on a plan, checking an architecture, wanting a second opinion, or auditing a project from multiple angles — even if they don't explicitly say "perspective."
---

# Perspective Review

Evaluate projects and artifacts through multiple diverse analytical perspectives.
Each perspective subagent gets its own context window, independently traverses the
project using tools (Read, Glob, Grep), then a cross-pollination round lets
perspectives react to each other's findings. A synthesis agent consolidates
everything with clean separation between independent and reactive insights.

**Core principle:** Independent diverse analysis (PBR-style) catches more
unique issues than multiple reviewers using the same approach. Cross-pollination
adds tradeoff tensions and interaction insights without contaminating the
independent findings.

## When to Use

- Reviewing a project or codebase from multiple angles
- Scrutinizing an architecture decision or design doc
- Getting diverse feedback on a plan
- Evaluating code against patterns, best practices, or conventions
- Reviewing a tech stack or specific technology usage
- Any project or artifact the user wants examined from multiple perspectives

**Not for:** Task-level code review (use requesting-code-review instead)

## Process

### Step 1: Understand the scope

Determine what the user wants reviewed:
- **Entire project** — get the project root path
- **Specific files/directories** — get the paths
- **Design doc or plan** — get the file path

Gather enough context to recommend perspectives (read key files, check structure).

### Step 2: Recommend perspectives

Read the perspective catalogue at `../shared-perspectives/catalogue.md`.

The catalogue has two families of perspectives:
- **Role-based** (Adversary, Operator, Maintainer, etc.) — who is looking
- **Discipline-based** (Design Principles, Testing Strategy, etc.) — what lens

Mix them based on the review target. Code reviews often benefit from combining
a role perspective (e.g., Adversary) with a discipline perspective (e.g.,
Testing Strategy). Pattern/standards reviews lean toward discipline-based.
Architecture reviews lean toward role-based. See the catalogue's selection
guidance for details.

If the user requests a lens not in the catalogue, create a custom perspective
with a specific analytical procedure (see catalogue's "Custom Perspectives"
section).

Recommend 3-4 perspectives with reasoning. Present to the user:

"I'd recommend these perspectives for reviewing [target]:
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

Use a reasonable location (e.g., sibling to the project being reviewed, or
a temp directory).

### Step 4: Round 1 — Independent Analysis

Read `../shared-perspectives/perspective-subagent-prompt.md` for the Round 1
review template.

For each confirmed perspective, look up its full analytical procedure from
the catalogue. Fill the Round 1 review template with:
- `{PERSPECTIVE_NAME}` — the perspective name
- `{PERSPECTIVE_PROCEDURE}` — the full analytical procedure from the catalogue
- `{TARGET_DESCRIPTION}` — what they're reviewing (project path, file paths)
- `{OUTPUT_PATH}` — where to save findings (e.g., `<workspace>/round-1/adversary.md`)

Spawn one subagent per perspective **in parallel** using the Agent tool.
Each subagent independently explores the project using Read, Glob, Grep and
saves findings to its output file. They have no knowledge of other perspectives.

**Capture each subagent's agent ID** from the return value — you will resume
these agents in Round 2.

**Wait for all Round 1 subagents to complete.**

### Step 5: Round 2 — Cross-Pollination

**Resume** each Round 1 subagent using the Agent tool's `resume` parameter
with the agent ID captured in Step 4. The resumed agent retains its full
Round 1 context — every file it read, every pattern it traced — so it can
make deeply informed reactions to other perspectives' findings.

Read the Round 2 template from `../shared-perspectives/perspective-subagent-prompt.md`.

Send each resumed agent:
- Paths to all OTHER perspectives' Round 1 output files, labeled by name
- `{OUTPUT_PATH}` — where to save cross-pollination response
  (e.g., `<workspace>/round-2/adversary.md`)
- Instruction that its Round 1 findings are LOCKED — react only, do not revise

Resume all perspectives **in parallel**.

**Wait for all Round 2 subagents to complete.**

### Step 6: Synthesis

Read `../shared-perspectives/synthesis-agent-prompt.md` for the review
synthesis template.

Fill the template with:
- `{ROUND_1_PATHS}` — paths to all Round 1 output files, labeled by perspective
- `{ROUND_2_PATHS}` — paths to all Round 2 output files, labeled by perspective

Spawn a synthesis subagent. It reads all output files and produces the
structured report maintaining clean separation between independent and
cross-pollination findings.

Save the final report to a location the user can access.

### Step 7: Present results

Present the synthesis report to the user. Offer next steps:
- "Want me to revise the design based on these findings?" -> brainstorming
- "Ready to proceed to implementation?" -> writing-plans

## Integration

**Invoked after:**
- `h-superpowers:brainstorming` — review the design it produced
- User directly — on any existing project or artifact

**Hands off to:**
- `h-superpowers:writing-plans` — if review is clean
- `h-superpowers:brainstorming` — if review reveals rework needed

**Does NOT replace:**
- Task-level spec/code-quality review in `team-driven-development`
- `requesting-code-review` for implementation-level review
