# Superpowers for Codex

Guide for using Superpowers with OpenAI Codex via native skill discovery.

## Quick Install

Tell Codex:

```
Fetch and follow instructions from https://raw.githubusercontent.com/ehartye/Hartye-superpowers/refs/heads/main/.codex/INSTALL.md
```

## Manual Installation

### Prerequisites

- OpenAI Codex CLI
- Git

### Steps

1. Clone the repo:
   ```bash
   git clone https://github.com/ehartye/Hartye-superpowers.git ~/.codex/superpowers
   ```

2. Create the skills symlink:
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/superpowers/skills ~/.agents/skills/superpowers
   ```

3. Restart Codex.

### Windows

Use a junction instead of a symlink (works without Developer Mode):

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\superpowers" "$env:USERPROFILE\.codex\superpowers\skills"
```

## How It Works

Codex has native skill discovery — it scans `~/.agents/skills/` at startup, parses SKILL.md frontmatter, and loads skills on demand. Superpowers skills are made visible through a single symlink:

```
~/.agents/skills/superpowers/ → ~/.codex/superpowers/skills/
```

Discovery makes `using-superpowers` available; it does not guarantee its full
body runs at every session start. Explicitly select it or use
`$using-superpowers` to start a workflow. Its adjacent `codex.md` explains skill
loading and host tool boundaries. This skills-directory installation does not
register Claude hooks, commands, or agent definitions.

## Usage

Skills are discovered automatically. Codex activates them when:
- You mention a skill by name (e.g., "use brainstorming")
- The task matches a skill's description
- The `using-superpowers` skill directs Codex to use one

For a predictable entry point:

```text
Use using-superpowers. Read its Codex guidance and explain how you load a named skill here.
```

For worktree setup, `$using-git-worktrees` also works directly: its own Codex
reference covers PowerShell, existing app worktrees, and manual Git. No global
`AGENTS.md` modification is required.

### Supported scope

The first Codex compatibility slice covers entry guidance, explicit skill
loading, and worktree setup. Shared workflow text remains available, but
persistent teams, shared task boards, delegated review, and branch-finishing
automation have not been validated for Codex. Do not infer full plugin parity
from successful skill discovery.

Keep only one installation of this library active (skills link or plugin) to
avoid duplicate skill names.

### Verification

From the repository, with Node.js, Git, and an authenticated Codex CLI:

```bash
node tests/codex/run-smoke-tests.mjs
node tests/codex/run-smoke-tests.mjs --baseline
```

These are live model tests and consume tokens. They copy the two entry skills
into a temporary workspace's native `.agents/skills/` directory and run Codex
with its normal tools and a writable sandbox scoped to the temporary workspace.
The baseline omits those fixture skills. Both create a worktree from a dirty
checkout, run a dependency-free test, and then reuse the
existing worktree. Assertions check source preservation, no incidental commits,
a clean destination, and no nested worktree. Transcripts and fixtures are
retained at the printed temporary path; your global installation is unchanged.

The reuse check invokes the worktree skill directly in a fresh session, without
invoking the startup skill. The runs otherwise inherit your Codex configuration.
Use an environment without another installed copy of this library for a valid
with/without comparison. Windows
uses the active CLI shell; the shared references also support Bash. Passing
these checks establishes only the scope above, not the rest of the library.

### Personal Skills

Create your own skills in `~/.agents/skills/`:

```bash
mkdir -p ~/.agents/skills/my-skill
```

Create `~/.agents/skills/my-skill/SKILL.md`:

```markdown
---
name: my-skill
description: Use when [condition] - [what it does]
---

# My Skill

[Your skill content here]
```

The `description` field is how Codex decides when to activate a skill automatically — write it as a clear trigger condition.

## Updating

```bash
cd ~/.codex/superpowers && git pull
```

Skills update instantly through the symlink.

## Uninstalling

```bash
rm ~/.agents/skills/superpowers
```

**Windows (PowerShell):**
```powershell
Remove-Item "$env:USERPROFILE\.agents\skills\superpowers"
```

Optionally delete the clone: `rm -rf ~/.codex/superpowers` (Windows: `Remove-Item -Recurse -Force "$env:USERPROFILE\.codex\superpowers"`).

## Troubleshooting

### Skills not showing up

1. Verify the symlink: `ls -la ~/.agents/skills/superpowers`
2. Check skills exist: `ls ~/.codex/superpowers/skills`
3. Restart Codex — skills are discovered at startup

### Windows junction issues

Junctions normally work without special permissions. If creation fails, try running PowerShell as administrator.

## Getting Help

- Report issues: https://github.com/ehartye/Hartye-superpowers/issues
- Main documentation: https://github.com/ehartye/Hartye-superpowers
