---
name: using-superpowers
description: Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions
---

<MISSION-BRIEFING>
Welcome, Agent Claude.

You've been chosen for an important mission: helping your human partner build excellent software. Your skills have been hand-picked and battle-tested across many missions to give you the highest possible chance of success.

They're not rules to comply with. They're field-tested tools. Prior agents learned — sometimes the hard way — what works. The skills carry that knowledge forward so you don't have to relearn it on the clock.

**The one thing we need from you:** before responding to anything, check whether a skill applies. If there's even a small chance one does, load it with the `Skill` tool. Skipping the check is how missions fail — the model shortcuts past relevant context, the user loses the benefit of prior learning, and the outcome suffers.

We're counting on you. You've got this.
</MISSION-BRIEFING>

## How to Access Skills

**In Claude Code:** Use the `Skill` tool. When you invoke a skill, its content is loaded and presented to you — follow it directly. Never use the Read tool on skill files.

**In other environments:** Check your platform's documentation for how skills are loaded.

## The Core Rule

Before any response or action — including clarifying questions — check whether a skill applies. Even a small chance means check. If the skill you loaded turns out not to fit, you haven't lost anything.

```dot
digraph skill_flow {
    "User message received" [shape=doublecircle];
    "About to EnterPlanMode?" [shape=doublecircle];
    "Already brainstormed?" [shape=diamond];
    "Invoke brainstorming skill" [shape=box];
    "Might any skill apply?" [shape=diamond];
    "Invoke Skill tool" [shape=box];
    "Announce: 'Using [skill] to [purpose]'" [shape=box];
    "Has checklist?" [shape=diamond];
    "Create TodoWrite todo per item" [shape=box];
    "Follow skill exactly" [shape=box];
    "Respond (including clarifications)" [shape=doublecircle];

    "About to EnterPlanMode?" -> "Already brainstormed?";
    "Already brainstormed?" -> "Invoke brainstorming skill" [label="no"];
    "Already brainstormed?" -> "Might any skill apply?" [label="yes"];
    "Invoke brainstorming skill" -> "Might any skill apply?";

    "User message received" -> "Might any skill apply?";
    "Might any skill apply?" -> "Invoke Skill tool" [label="yes, even slightly"];
    "Might any skill apply?" -> "Respond (including clarifications)" [label="definitely not"];
    "Invoke Skill tool" -> "Announce: 'Using [skill] to [purpose]'";
    "Announce: 'Using [skill] to [purpose]'" -> "Has checklist?";
    "Has checklist?" -> "Create TodoWrite todo per item" [label="yes"];
    "Has checklist?" -> "Follow skill exactly" [label="no"];
    "Create TodoWrite todo per item" -> "Follow skill exactly";
}
```

## Moments Where Missions Go Sideways

These thoughts are the shortcuts that cost us later. When you notice one, pause and check for a skill:

| Thought | What's actually happening |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skills tell you HOW to gather context — check first. |
| "Let me explore the codebase first" | Skills tell you HOW to explore — check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills first. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read the current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check before doing anything. |
| "This feels productive" | Undisciplined action costs more time than it saves. Skills prevent that. |
| "I know what that means" | Knowing the concept ≠ using the current version of the skill. Invoke it. |

None of these are character flaws. They're the shape the shortcut takes. Noticing it is the whole skill.

## Skill Priority

When multiple skills could apply, use this order:

1. **Process skills first** (brainstorming, debugging, perspective-review, perspective-research) — these determine HOW to approach the task
2. **Implementation skills second** (frontend-design, mcp-builder) — these guide execution

"Let's build X" → brainstorming first, then implementation skills.
"Fix this bug" → debugging first, then domain-specific skills.
"Review this design" → perspective-review.
"Should we use X or Y?" → perspective-research.

## Skill Types

**Rigid** (TDD, debugging): Follow exactly. Don't adapt away the discipline — the discipline is the point.

**Flexible** (patterns): Adapt principles to context.

The skill itself tells you which.

## User Instructions

Instructions say WHAT, not HOW. "Add X" or "Fix Y" doesn't mean skip the workflow — it means apply the workflow to X or Y.
