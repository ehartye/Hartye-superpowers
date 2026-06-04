# Time-Machine Check + Spike-Checkpoint Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use h-superpowers:subagent-driven-development, h-superpowers:team-driven-development, or h-superpowers:executing-plans to implement this plan (ask user which approach). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reusable `time-machine-check` skill (drift reading + prospective-hindsight reflection → on-track/diverged verdict) and wire its first caller, the spike-checkpoint, into the right-sizing flow.

**Architecture:** A deterministic bash script `drift` (a thin `git diff` wrapper: `mark` records a baseline SHA, `measure` reports files/lines changed since a SHA and whether a threshold was crossed). A prose skill `time-machine-check` calls `drift measure`, presents the reading with a caller-supplied narrative, and returns a verdict — it never acts on the verdict. The spike-checkpoint (added to `using-superpowers` → Right-Sizing) is one caller: explicit `drift mark` at the no-design decision, `time-machine-check` at natural beats, and a retreat (lessons → stash → full/surgical → reimplement under TDD) on `diverged`. Pull-invoked, git-native, no hook.

**Tech Stack:** bash, git, markdown skills (auto-discovered from `skills/`). Repo is bash-only (no PowerShell twins). Tests are self-contained `test-*.sh`.

---

### Task 1: `drift measure` subcommand (TDD)

**Files:**
- Create: `skills/time-machine-check/scripts/drift`
- Test: `tests/unit/test-drift.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/test-drift.sh`:

```bash
#!/usr/bin/env bash
# Unit tests for the drift script. Self-contained: builds a scratch git repo.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DRIFT="$REPO_ROOT/skills/time-machine-check/scripts/drift"
PASS=0; FAIL=0
assert_eq() { # $1=actual $2=expected $3=label
  if [ "$1" = "$2" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $3 — got '$1' want '$2'"; fi
}
field() { echo "$1" | grep -oE "$2=[^ ]+" | cut -d= -f2; } # extract key= value from a reading line

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
cd "$WORK"
git init -q; git config user.email t@t.t; git config user.name t
printf 'a\n' > a.txt; git add -A; git commit -qm base
BASE="$(git rev-parse HEAD)"

# No changes yet -> 0 files, not crossed
out="$(bash "$DRIFT" measure "$BASE")"
assert_eq "$(field "$out" files)" "0" "measure: clean tree files=0"
assert_eq "$(field "$out" crossed)" "false" "measure: clean tree not crossed"

# Small change -> below defaults (files<4, lines<150) -> not crossed
printf 'a\nb\n' > a.txt
out="$(bash "$DRIFT" measure "$BASE")"
assert_eq "$(field "$out" files)" "1" "measure: 1 file changed"
assert_eq "$(field "$out" crossed)" "false" "measure: small change not crossed"

# Breadth crosses default files threshold (>=4 files)
for f in b c d e; do printf 'x\n' > "$f.txt"; done
out="$(bash "$DRIFT" measure "$BASE")"
assert_eq "$(field "$out" crossed)" "true" "measure: 5 files crosses default files=4"

# --files override raises the bar so 5 files is within
out="$(bash "$DRIFT" measure "$BASE" --files 10 --lines 9999)"
assert_eq "$(field "$out" crossed)" "false" "measure: --files 10 not crossed"

# --lines override trips on size
printf '%s\n' $(seq 1 200) > big.txt
out="$(bash "$DRIFT" measure "$BASE" --files 999 --lines 150)"
assert_eq "$(field "$out" crossed)" "true" "measure: 200 lines crosses --lines 150"

echo "drift measure: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/unit/test-drift.sh`
Expected: FAIL — script does not exist yet (`bash: .../drift: No such file or directory`), non-zero exit.

- [ ] **Step 3: Write minimal implementation**

Create `skills/time-machine-check/scripts/drift`:

```bash
#!/usr/bin/env bash
# drift — a thin, deterministic git-diff wrapper. No judgment.
#   drift mark [label]                              record HEAD as a baseline
#   drift measure <sha> [--files N] [--lines M]     report drift since <sha>
set -uo pipefail

state_dir() { echo "$(git rev-parse --show-toplevel)/.superpowers/drift"; }

cmd_measure() {
  local sha="${1:-}"; shift || true
  [ -n "$sha" ] || { echo "usage: drift measure <sha> [--files N] [--lines M]" >&2; exit 2; }
  local files_thresh=4 lines_thresh=150
  while [ $# -gt 0 ]; do
    case "$1" in
      --files) files_thresh="$2"; shift 2;;
      --lines) lines_thresh="$2"; shift 2;;
      *) echo "unknown flag: $1" >&2; exit 2;;
    esac
  done
  local stat tfiles ins del ufiles ulines files lines crossed
  # Tracked changes (working tree vs the baseline commit).
  stat="$(git diff --shortstat "$sha" -- 2>/dev/null)"
  tfiles="$(echo "$stat" | grep -oE '[0-9]+ file' | grep -oE '^[0-9]+')"; tfiles="${tfiles:-0}"
  ins="$(echo "$stat" | grep -oE '[0-9]+ insertion' | grep -oE '^[0-9]+')"; ins="${ins:-0}"
  del="$(echo "$stat" | grep -oE '[0-9]+ deletion' | grep -oE '^[0-9]+')"; del="${del:-0}"
  # New untracked files: a spike creates files git diff won't count. Count them
  # explicitly (-r so cat is never run on empty input, which would hang).
  ufiles="$(git ls-files --others --exclude-standard | grep -c . )"; ufiles="${ufiles:-0}"
  ulines="$(git ls-files --others --exclude-standard -z | xargs -0 -r cat 2>/dev/null | wc -l | tr -d ' ')"; ulines="${ulines:-0}"
  files=$((tfiles + ufiles))
  lines=$((ins + del + ulines))
  if [ "$files" -ge "$files_thresh" ] || [ "$lines" -ge "$lines_thresh" ]; then crossed=true; else crossed=false; fi
  echo "files=$files lines=$lines crossed=$crossed (since ${sha:0:7}; thresholds files>=$files_thresh lines>=$lines_thresh)"
}

case "${1:-}" in
  measure) shift; cmd_measure "$@";;
  mark)    shift; cmd_mark "$@";;
  *) echo "usage: drift {mark|measure} ..." >&2; exit 2;;
esac
```

(`cmd_mark` is added in Task 2; `measure` is complete and testable now.)

- [ ] **Step 4: Run test to verify it passes**

Run: `chmod +x skills/time-machine-check/scripts/drift && bash tests/unit/test-drift.sh`
Expected: `drift measure: 6 passed, 0 failed`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add skills/time-machine-check/scripts/drift tests/unit/test-drift.sh
git commit -m "feat(time-machine-check): drift measure subcommand"
```

---

### Task 2: `drift mark` subcommand (TDD)

**Files:**
- Modify: `skills/time-machine-check/scripts/drift`
- Modify: `tests/unit/test-drift.sh`

- [ ] **Step 1: Add failing tests for `mark`**

Append before the final `echo "drift measure: ..."` summary line in `tests/unit/test-drift.sh`:

```bash
# mark: records current HEAD sha to .superpowers/drift/baseline and prints it
# Clean the working tree from the measure tests above (revert tracked, drop untracked).
git checkout -q -- . ; rm -f b.txt c.txt d.txt e.txt big.txt
HEAD_SHA="$(git rev-parse HEAD)"
mark_out="$(bash "$DRIFT" mark 2>/dev/null)"
assert_eq "$mark_out" "$HEAD_SHA" "mark: prints HEAD sha"
assert_eq "$(cat .superpowers/drift/baseline)" "$HEAD_SHA" "mark: writes baseline file"

# mark <label>: writes to a named baseline
bash "$DRIFT" mark spike >/dev/null
assert_eq "$(cat .superpowers/drift/spike)" "$HEAD_SHA" "mark: named label baseline"

# mark warns on a dirty tree (warning to stderr; still records)
printf 'dirty\n' >> a.txt
warn="$(bash "$DRIFT" mark 2>&1 >/dev/null)"
assert_eq "$([ -n "$warn" ] && echo yes || echo no)" "yes" "mark: warns on dirty tree"
```

- [ ] **Step 2: Run test to verify the new assertions fail**

Run: `bash tests/unit/test-drift.sh`
Expected: FAIL on the `mark:` assertions (`cmd_mark: command not found` / empty output), non-zero exit.

- [ ] **Step 3: Implement `cmd_mark`**

Insert this function into `skills/time-machine-check/scripts/drift` above the `case` block:

```bash
cmd_mark() {
  local label="${1:-baseline}"
  local dir; dir="$(state_dir)"
  mkdir -p "$dir"
  local sha; sha="$(git rev-parse HEAD)"
  if [ -n "$(git status --porcelain)" ]; then
    echo "drift: warning — working tree is dirty; baseline '$label' won't cleanly isolate the spike" >&2
  fi
  printf '%s\n' "$sha" > "$dir/$label"
  echo "$sha"
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/unit/test-drift.sh`
Expected: all assertions pass, exit 0.

- [ ] **Step 5: Commit**

```bash
git add skills/time-machine-check/scripts/drift tests/unit/test-drift.sh
git commit -m "feat(time-machine-check): drift mark subcommand"
```

---

### Task 3: `time-machine-check` skill (SKILL.md)

**Files:**
- Create: `skills/time-machine-check/SKILL.md`
- Test: `tests/unit/test-time-machine-check-skill.sh`

- [ ] **Step 1: Write the failing structural test**

Create `tests/unit/test-time-machine-check-skill.sh`:

```bash
#!/usr/bin/env bash
# Structural lint for the time-machine-check skill (deterministic, no tokens).
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
S="$REPO_ROOT/skills/time-machine-check/SKILL.md"
PASS=0; FAIL=0
has() { if grep -q "$1" "$S"; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: missing '$1'"; fi; }
[ -f "$S" ] || { echo "FAIL: SKILL.md not found"; exit 1; }
grep -qE '^name: time-machine-check' "$S" && PASS=$((PASS+1)) || { FAIL=$((FAIL+1)); echo "FAIL: frontmatter name"; }
has "drift measure"          # references the executable
has "on-track"               # documents the verdict vocabulary
has "diverged"
has "narrative"              # documents the reusable narrative input
has "caller"                 # documents that the caller owns the response
echo "skill lint: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/unit/test-time-machine-check-skill.sh`
Expected: FAIL — `SKILL.md not found`, exit 1.

- [ ] **Step 3: Write the skill**

Create `skills/time-machine-check/SKILL.md`:

```markdown
---
name: time-machine-check
description: Use at a natural beat during a long or no-design task to check whether the work is drifting from intent. Measures change since a baseline SHA and runs a prospective-hindsight ("time machine") reflection, returning an on-track/diverged verdict. The caller decides what to do with the verdict.
---

# Time-Machine Check

A reusable reflective checkpoint. Given a **baseline SHA** and an **evaluation
narrative**, it measures how far the work has drifted and asks the honest
question — then hands back a verdict. **It does not act on the verdict; the
caller does.**

## Inputs

- **sha** (required) — the baseline commit to measure drift from (e.g. recorded
  earlier with `drift mark`).
- **narrative** (required) — the evaluation frame for this context. Default:
  *"Is this going how we thought? If you had a time machine, would you go back
  and design it first?"* Callers pass their own (e.g. executing-plans:
  *"Does the work so far still match the approved plan?"*).
- **files / lines** (optional) — drift thresholds; defaults 4 / 150.

## Procedure

1. Run the drift reading:
   `bash skills/time-machine-check/scripts/drift measure <sha> [--files N] [--lines M]`
   It prints `files=… lines=… crossed=…`.
2. Read the `crossed` flag and the raw numbers **together with the narrative**.
   The number is a prompt to think, not a verdict — a low number with a clear
   "yes, I'd time-machine this" still means diverged; a high number on genuinely
   simple breadth can still be on-track.
3. Answer the narrative honestly.
4. Return a verdict: **on-track** or **diverged**, plus a one-line rationale.

## Boundary

This skill returns a verdict and stops. What happens on **diverged** is the
**caller's** decision — a spike-checkpoint retreats and redesigns; a plan
executor re-plans; a debugger re-forms its hypothesis. Do not bake any one
response into this skill.

## Callers

- **spike-checkpoint** (right-sizing) — see using-superpowers → Right-Sizing.
- Reusable elsewhere by passing a different `narrative`.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/unit/test-time-machine-check-skill.sh`
Expected: `skill lint: 6 passed, 0 failed`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add skills/time-machine-check/SKILL.md tests/unit/test-time-machine-check-skill.sh
git commit -m "feat(time-machine-check): reusable reflective-checkpoint skill"
```

---

### Task 4: Wire the spike-checkpoint into right-sizing

**Files:**
- Modify: `skills/using-superpowers/SKILL.md` (the Right-Sizing section added on this branch)

- [ ] **Step 1: Add the spike-checkpoint subsection**

In `skills/using-superpowers/SKILL.md`, immediately after the
`**Autonomous / headless runs:**` paragraph inside the
`## Right-Sizing Process` section, insert:

```markdown

### Spike-checkpoint (when you skip design)

Right-sizing is safe to be *wrong* because mis-sizing is recoverable. When you
consciously take the no-design path:

1. **Mark a baseline:** `bash skills/time-machine-check/scripts/drift mark`
   (records the clean SHA; warns if the tree is dirty).
2. **Build directly** under the discipline above.
3. **At natural beats** (finished a chunk · hit friction · about to call it done),
   run the **time-machine-check** skill with `sha=<that baseline>` and the spike
   narrative ("would a time machine make me design this first?").
4. **If the verdict is `diverged`,** retreat — and treat the work as a spike, not
   waste:
   - **Capture lessons first** (before touching the tree): what made it bigger,
     the real shape, the trigger to catch next time.
   - **Stash, don't delete:** `git stash push -u -m "spike: <task> @ <sha7>"`.
   - **Full or surgical** (read `git diff <baseline> --stat`): clean tree and
     redesign, or restore baseline and cherry-pick the genuinely-clean keepers
     out of the stash.
   - **Reimplement under TDD regardless** — the stash is reference only; the
     shipped code is test-first.
5. **If `on-track`,** keep going.
```

- [ ] **Step 2: Verify the reference resolves**

Run: `grep -n "time-machine-check" skills/using-superpowers/SKILL.md && test -f skills/time-machine-check/scripts/drift && echo OK`
Expected: prints the matching line(s) and `OK`.

- [ ] **Step 3: Commit**

```bash
git add skills/using-superpowers/SKILL.md
git commit -m "feat(right-sizing): wire spike-checkpoint to time-machine-check"
```

---

### Task 5: Final verification

**Files:** none (verification only)

- [ ] **Step 1: Run the new unit tests**

Run:
```bash
bash tests/unit/test-drift.sh && bash tests/unit/test-time-machine-check-skill.sh
```
Expected: both report `0 failed` and exit 0.

- [ ] **Step 2: Confirm `.superpowers/` stays untracked**

Run: `git status --porcelain | grep -F '.superpowers/' || echo "clean: .superpowers untracked/ignored"`
Expected: `clean: .superpowers untracked/ignored` (it is gitignored).

- [ ] **Step 3: Confirm no regressions (optional — spends tokens / needs Claude API)**

The new tests in Step 1 are the required gate. The repo's `tests/run-all.sh`
behavioral suite invokes `claude` and spends tokens, so run it only when you have
API access and want to confirm the `using-superpowers` edit didn't disturb
skill-triggering:

Run (optional): `bash tests/claude-code/run-skill-tests.sh --test test-using-superpowers.sh`
Expected: passes. `run-all.sh` does not auto-discover `tests/unit/`; the new
deterministic tests run directly (Step 1). Optionally wire `tests/unit/` into
`run-all.sh` as a follow-up.

- [ ] **Step 4: Commit any verification fixes** (only if Steps 1–3 surfaced issues)

```bash
git add -A
git commit -m "test(time-machine-check): verification fixes"
```
