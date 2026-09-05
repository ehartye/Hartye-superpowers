# Worktrees in Codex

Use this procedure in Codex. It is self-contained so explicitly invoking `using-git-worktrees` works without first loading `using-superpowers`.

## 1. Inspect the requested checkout

Run these commands in the checkout where the user wants to work. They work in both PowerShell and Bash:

```text
git rev-parse --show-toplevel
git rev-parse --path-format=absolute --git-dir
git rev-parse --path-format=absolute --git-common-dir
git rev-parse --show-superproject-working-tree
git status --short
git worktree list --porcelain
```

Compare the resolved absolute Git and common directories. Different directories mean a linked worktree, unless the superproject command returns a path: that identifies a submodule and must not be mistaken for worktree isolation. Reuse an existing linked worktree, including one provisioned by the Codex app. Do not create a nested worktree or switch its branch as part of setup.

Read applicable `AGENTS.md` guidance. Honor a worktree request or an existing user/project preference; do not ask again when creation is already authorized. Otherwise ask whether the user wants a worktree before creating one.

## 2. Create only when needed

Use an available native worktree tool according to its actual contract. `EnterWorktree` is a Claude tool name, not a Codex requirement. If no native tool is available, use Git:

```text
git worktree add -b <new-branch> "<absolute-worktree-path>" <base-ref>
```

Replace the placeholders with inspected values. Honor the requested destination, branch, and base. If no base was specified, use the source checkout's current `HEAD`; do not fetch or silently substitute a remote branch. Verify the branch and destination are unused before creation. Never overwrite an existing directory or force reuse of a branch.

For an unspecified destination, prefer a sibling directory outside the source checkout. An explicitly preferred in-repo directory must be ignored (`git check-ignore`); if it is not, explain the conflict before proceeding. Do not add or commit `.gitignore` merely to make setup work. Never stash, reset, clean, or copy uncommitted changes as an incidental setup step. Explain that a new worktree starts from committed history; existing edits stay in the source checkout.

Use the new absolute path as the working directory on every subsequent shell call. A `cd` in one tool invocation may not persist to the next. In PowerShell, quote paths and use `-LiteralPath` for filesystem inspection; the Git commands above need no Bash variables or command substitution.

If creation fails, report the actual error. Do not silently continue implementation in the source checkout or on the default branch.

## 3. Verify and hand off

Read the project's setup and test instructions. Install dependencies only when required to run the baseline, using the existing lockfile and documented package manager. A dependency-free Node fixture can run its tests without `npm install`. Inspect `git status --short` before and after setup; report any generated changes instead of claiming the worktree is clean.

Run the appropriate baseline tests inside the selected worktree. If they fail, report the failure before implementation and obtain direction unless the user already authorized working with that failing baseline. If no test command exists, say the baseline is unverified.

Report the absolute worktree path, branch, test command/result, and any existing or generated changes. Confirm the source checkout's edits were preserved. Retain the worktree for handoff; do not automatically remove app-managed or user-created worktrees, delete branches, or invoke Claude's `ExitWorktree`. Finishing and publishing are separate actions.
