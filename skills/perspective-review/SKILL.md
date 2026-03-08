---
name: perspective-review
description: Use when you want diverse analytical perspectives on a project, codebase, design doc, or any artifact worth scrutinizing. Spawns perspective subagents that independently traverse the project, then cross-pollinate findings via a second round, and synthesizes results with clean separation. Use this whenever the user mentions reviewing a design, getting feedback on a plan, checking an architecture, wanting a second opinion, or auditing a project from multiple angles — even if they don't explicitly say "perspective."
---

# Perspective Review

Evaluate projects and artifacts through multiple diverse analytical perspectives.
Each perspective agent gets its own context window, independently traverses the
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

### Step 3: Choose execution approach

Present the choice:

"**Two execution approaches:**

**1. Subagent-Driven** — Parallel subagents per perspective, file-based
cross-pollination with agent resume. Fast, efficient, proven.

**2. Team-Driven** — Persistent teammate agents with direct messaging.
Richer cross-pollination through real-time dialogue. Costs 2-4x more.
Requires Opus 4.6+ and `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.

Which approach?"

Default to subagent-driven if the user doesn't have a preference.

### Step 4: Set up workspace

Create a temporary directory for round outputs:

```
<workspace>/
  round-1/
  round-2/
```

Use a reasonable location (e.g., sibling to the project being reviewed, or
a temp directory).

---

## Path A: Subagent-Driven

### Step 5a: Round 1 — Independent Analysis

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

### Step 6a: Round 2 — Cross-Pollination

**Resume** each Round 1 subagent using the Agent tool's `resume` parameter
with the agent ID captured in Step 5a. The resumed agent retains its full
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

### Step 7a: Synthesis

Read `../shared-perspectives/synthesis-agent-prompt.md` for the review
synthesis template.

Fill the template with:
- `{ROUND_1_PATHS}` — paths to all Round 1 output files, labeled by perspective
- `{ROUND_2_PATHS}` — paths to all Round 2 output files, labeled by perspective

Spawn a synthesis subagent. It reads all output files and produces the
structured report maintaining clean separation between independent and
cross-pollination findings.

Save the final report to a location the user can access.

---

## Path B: Team-Driven

### Step 5b: Set up team

Create the team:

```
TeamCreate(team_name: "perspective-review", description: "Multi-perspective review of [target]")
```

Read `../shared-perspectives/perspective-teammate-prompt.md` for the review
teammate template. For each confirmed perspective, fill the template with:
- `{TEAM_NAME}` — the team name
- `{PERSPECTIVE_NAME}` — the perspective name
- `{PERSPECTIVE_SLUG}` — kebab-case name (e.g., `adversary`, `design-principles`)
- `{PERSPECTIVE_PROCEDURE}` — the full analytical procedure from the catalogue
- `{TARGET_DESCRIPTION}` — what they're reviewing
- `{OUTPUT_PATH_ROUND_1}` — e.g., `<workspace>/round-1/adversary.md`
- `{OUTPUT_PATH_ROUND_2}` — e.g., `<workspace>/round-2/adversary.md`

Spawn one teammate per perspective using the Agent tool with `team_name`.

Read `../shared-perspectives/synthesis-teammate-prompt.md` for the review
synthesis teammate template. Spawn the synthesis teammate with `team_name`.

### Step 6b: Round 1 + Cross-Pollination

**Round 1:** Each perspective teammate independently explores the project
and messages you when done. Wait for all perspectives to report completion.

**Round 2:** Once all Round 1 outputs are saved, send each perspective
teammate the file paths of all OTHER perspectives' Round 1 outputs via
SendMessage:

"Cross-pollination round. Read these other perspectives' Round 1 findings:
- Adversary: `<workspace>/round-1/adversary.md`
- Operator: `<workspace>/round-1/operator.md`
- ...
Your Round 1 findings are LOCKED. React only."

Wait for all perspectives to report Round 2 completion.

### Step 7b: Synthesis + Shutdown

Send the synthesis teammate all file paths via SendMessage:

"All rounds complete. Produce the synthesis report.
Round 1 files: [list with perspective labels]
Round 2 files: [list with perspective labels]
Save report to: {OUTPUT_PATH}"

Wait for synthesis to complete. Then shut down:

1. Send `shutdown_request` to each teammate via SendMessage
2. `Bash("sleep 30")`
3. `TeamDelete`

---

### Step 8: Present results

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
