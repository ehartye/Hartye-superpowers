# Installing Superpowers for Codex

Enable superpowers skills in Codex via native skill discovery. Just clone and symlink.

## Prerequisites

- Git

## Installation

1. **Clone the superpowers repository:**
   ```bash
   git clone https://github.com/ehartye/Hartye-superpowers.git ~/.codex/superpowers
   ```

2. **Create the skills symlink:**
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/superpowers/skills ~/.agents/skills/superpowers
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\superpowers" "$env:USERPROFILE\.codex\superpowers\skills"
   ```

3. **Restart Codex** (quit and relaunch the CLI) to discover the skills.

4. **Start explicitly:** select `using-superpowers` in Codex, or type
   `$using-superpowers` followed by your task. The skill loads its Codex entry
   guidance. You can also invoke `$using-git-worktrees` directly.

This installation exposes skills only; it does not install Claude's session
hook, commands, or agent definitions. Do not install a second plugin copy
alongside this skills link: duplicate skills make selection ambiguous.

## Migrating from old bootstrap

If you installed superpowers before native skill discovery, you need to:

1. **Update the repo:**
   ```bash
   cd ~/.codex/superpowers && git pull
   ```

2. **Create the skills symlink** (step 2 above) — this is the new discovery mechanism.

3. **Remove the old bootstrap block** from `~/.codex/AGENTS.md` — any block referencing `superpowers-codex bootstrap` is no longer needed.

4. **Restart Codex.**

## Verify

```bash
ls -la ~/.agents/skills/superpowers
```

You should see a symlink (or junction on Windows) pointing to your superpowers skills directory.

Then start a fresh Codex session and ask:

```text
Use using-superpowers. Read its Codex guidance and explain how you load a named skill here.
```

Verify that Codex reads `skills/using-superpowers/SKILL.md` and its adjacent
`codex.md`, using the installed location. Directory discovery alone does not
prove a skill was loaded. See `docs/README.codex.md` for supported scope and tests.

## Updating

```bash
cd ~/.codex/superpowers && git pull
```

Skills update instantly through the symlink.

## Uninstalling

```bash
rm ~/.agents/skills/superpowers
```

Optionally delete the clone: `rm -rf ~/.codex/superpowers`.
