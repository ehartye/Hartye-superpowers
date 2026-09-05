# Using Superpowers in Codex

This is the Codex entry guidance for `using-superpowers`. Apply its shared workflow discipline with these host-specific loading rules.

## Load skills explicitly

Use the skill names and locations advertised by the current Codex session. When a skill applies or the user names one, load its full `SKILL.md` before following its workflow. Use a provided skill loader when available; otherwise read the advertised file with the filesystem tools. A description alone is not the skill.

In this library, instructions to invoke the `Skill` tool mean this loading procedure in Codex. Do not call an unavailable `Skill` tool. Claude's prohibition on reading skill files applies to Claude Code only.

Resolve reference files relative to the skill file you actually loaded, not the current working directory or a guessed clone location. For example, this file is beside `using-superpowers/SKILL.md`. A reference such as `h-superpowers:using-git-worktrees` means the library's `using-git-worktrees` skill; use its advertised Codex name, which can vary with installation method. If a required skill is missing, report that instead of inventing its content.

Users can explicitly start with `$using-superpowers` for a skills-directory installation, or select the advertised skill in Codex. Discovery makes a skill available; it does not guarantee its full body runs at every session start. Direct invocation of another skill must also work without this entry skill having run first.

## Tool and instruction boundaries

- Follow the user's instructions and the current host's permissions. The shared workflow does not grant additional authorization.
- `CLAUDE.md` references mean applicable project guidance in Codex, normally `AGENTS.md`. Do not create or overwrite global instructions to activate this plugin.
- For a `TodoWrite` checklist, use an available planning tool or maintain a concise checklist yourself. This is not an implementation of Claude's shared task board.
- For worktree setup, load `using-git-worktrees` and its Codex reference. Shell examples must match the current shell; do not paste Bash variable syntax into PowerShell.

This first compatibility slice covers entry, skill loading, and worktree setup. It does not establish Codex support for persistent teams, shared task tools, or the rest of the library's agent orchestration. Check the tools those workflows require before choosing them; do not mechanically translate their tool names or silently claim equivalent behavior.
