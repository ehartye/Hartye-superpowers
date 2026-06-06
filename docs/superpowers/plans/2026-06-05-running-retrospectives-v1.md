# running-retrospectives v1 (standalone floor) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use h-superpowers:subagent-driven-development, h-superpowers:team-driven-development, or h-superpowers:executing-plans to implement this plan (ask user which approach). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the standalone floor of `running-retrospectives` — a deliberately-invoked retrospective skill that captures recurring project-specific corrections, proves each via an inline RED→GREEN check, and promotes survivors into the agent's project auto-memory.

**Architecture:** A deterministic bash CLI (`lessons`, mirroring the `drift` script precedent) owns the mechanical pieces (capture + CRLF-normalized hashing + dedup, distinct-session clustering, the promote/reject margin decision, prune). The `SKILL.md` conducts the funnel and the agent-driven inline RED→GREEN runner (subagent trials), then promotes by writing a `type: feedback` memory file. Recall is automatic via the already-injected project `MEMORY.md` — no `using-superpowers`/SessionStart edit. Phases 2–3 (agent-stalker SENSE, crucible PROVE) are named seams only.

**Tech Stack:** bash (cross-platform: git-bash on Windows + Linux), awk for TSV parsing, `sha256sum`/`shasum` for hashing, markdown SKILL.md. Tests are self-contained `tests/unit/test-*.sh` auto-discovered by `tests/unit/run.sh`. Per spec `docs/superpowers/specs/2026-06-05-running-retrospectives-design.md`.

**Conventions to follow (from the existing `drift` script `skills/time-machine-check/scripts/drift`):**
- `#!/usr/bin/env bash` + `set -uo pipefail`.
- Subcommand dispatch via `case`; bad usage prints to stderr and `exit 2`.
- State lives under `$(git rev-parse --show-toplevel)/.superpowers/` (already gitignored).
- Tests override paths via env so they never touch the real repo state.

---

### Task 1: `lessons` script — `capture` (append + CRLF-normalized hash + per-session dedup)

**Files:**
- Create: `skills/running-retrospectives/scripts/lessons`
- Create: `tests/unit/test-lessons.sh`

- [ ] **Step 1: Write the failing test.** Create `tests/unit/test-lessons.sh`:

```bash
#!/usr/bin/env bash
# Deterministic unit tests for the running-retrospectives `lessons` script (no tokens).
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LESSONS="$REPO_ROOT/skills/running-retrospectives/scripts/lessons"
PASS=0; FAIL=0
ok()  { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $1 — expected '$3', got '$2'"; fi; }

# Isolate all state in a temp dir; never touch the real repo .superpowers.
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
export LESSONS_HOME="$TMP/.superpowers"
FILE="$LESSONS_HOME/lessons-candidates.tsv"

# capture writes one TSV line and prints the hash
H1="$(bash "$LESSONS" capture "Always run the suite before saying done" --session s1)"
ok "capture prints a 16-hex hash" "$(printf '%s' "$H1" | grep -cE '^[0-9a-f]{16}$')" "1"
ok "capture wrote exactly one line" "$(wc -l < "$FILE" | tr -d ' ')" "1"

# CRLF/whitespace normalization: same correction with CRLF + extra spaces hashes identically
H2="$(printf 'Always run the suite   before saying done\r' | { read -r line; bash "$LESSONS" capture "$line" --session s2; })"
ok "CRLF + whitespace normalize to same hash" "$H2" "$H1"

# per-session dedup: same (hash, session) does not append a second line
bash "$LESSONS" capture "Always run the suite before saying done" --session s1 >/dev/null
ok "same hash+session is idempotent (still 2 lines)" "$(wc -l < "$FILE" | tr -d ' ')" "2"

echo "lessons: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run, verify it fails.**

Run: `bash tests/unit/test-lessons.sh`
Expected: FAIL — the script doesn't exist yet (`bash: .../lessons: No such file or directory`), non-zero exit.

- [ ] **Step 3: Implement `capture`.** Create `skills/running-retrospectives/scripts/lessons`:

```bash
#!/usr/bin/env bash
# lessons — deterministic mechanics for running-retrospectives. No judgment, no LLM.
#   lessons capture <text> [--source S] [--confidence C] [--session ID]
#   lessons cluster [--threshold N]
#   lessons decide --k K --red-fail RF --green-pass GP
#   lessons prune <hash>
set -uo pipefail

home_dir() { echo "${LESSONS_HOME:-$(git rev-parse --show-toplevel)/.superpowers}"; }
cand_file() { echo "$(home_dir)/lessons-candidates.tsv"; }

# Normalize for hashing: strip CR, collapse whitespace runs to one space, trim ends.
normalize() { printf '%s' "$1" | tr -d '\r' | tr '\t' ' ' | tr -s ' ' | sed 's/^ *//; s/ *$//'; }

hash_text() {
  local norm; norm="$(normalize "$1")"
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$norm" | sha256sum | cut -c1-16
  else
    printf '%s' "$norm" | shasum -a 256 | cut -c1-16
  fi
}

cmd_capture() {
  local text="${1:-}"; shift || true
  [ -n "$text" ] || { echo "usage: lessons capture <text> [--source S] [--confidence C] [--session ID]" >&2; exit 2; }
  local source="user" confidence="high" session="${LESSONS_SESSION:-${CLAUDE_CODE_SESSION_ID:-unknown}}"
  while [ $# -gt 0 ]; do
    case "$1" in
      --source) source="${2:?--source needs a value}"; shift 2;;
      --confidence) confidence="${2:?--confidence needs a value}"; shift 2;;
      --session) session="${2:?--session needs a value}"; shift 2;;
      *) echo "unknown flag: $1" >&2; exit 2;;
    esac
  done
  local dir; dir="$(home_dir)"; mkdir -p "$dir"
  local file; file="$(cand_file)"
  local h; h="$(hash_text "$text")"
  # Per-session dedup: same correction already captured this session → no-op.
  if [ -f "$file" ] && awk -F'\t' -v h="$h" -v s="$session" '$1==h && $4==s {found=1} END{exit !found}' "$file"; then
    echo "$h"; return 0
  fi
  # Sanitize text for single-line TSV storage (no tabs/newlines in the field).
  local safe; safe="$(printf '%s' "$text" | tr -d '\r' | tr '\t\n' '  ')"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$h" "$(date +%s)" "$confidence" "$session" "$source" "$safe" >> "$file"
  echo "$h"
}

case "${1:-}" in
  capture) shift; cmd_capture "$@";;
  *) echo "usage: lessons {capture|cluster|decide|prune} ..." >&2; exit 2;;
esac
```

TSV column order: `hash  ts  confidence  session  source  text`. (Note the dedup awk checks `$1==h && $4==s` — `$4` is the session column.)

- [ ] **Step 4: Run, verify it passes.**

Run: `bash tests/unit/test-lessons.sh`
Expected: `lessons: 4 passed, 0 failed`, exit 0.

- [ ] **Step 5: Commit.**

```bash
git add skills/running-retrospectives/scripts/lessons tests/unit/test-lessons.sh
git commit -m "feat(running-retrospectives): lessons capture + CRLF-normalized hash + per-session dedup"
```

---

### Task 2: `lessons cluster` — distinct-session recurrence counting

**Files:**
- Modify: `skills/running-retrospectives/scripts/lessons`
- Modify: `tests/unit/test-lessons.sh`

- [ ] **Step 1: Append the failing test.** In `tests/unit/test-lessons.sh`, insert this block immediately BEFORE the final summary line (`echo "lessons: ..."`):

```bash
# cluster: a correction in 1 session is NOT eligible; in 2 distinct sessions IS.
TMP2="$(mktemp -d)"; export LESSONS_HOME="$TMP2/.superpowers"
bash "$LESSONS" capture "Use absolute paths in the Bash tool" --session sA >/dev/null
bash "$LESSONS" capture "Use absolute paths in the Bash tool" --session sA >/dev/null   # same session, dedup
ok "single-session correction is not eligible" "$(bash "$LESSONS" cluster | grep -c .)" "0"
bash "$LESSONS" capture "Use absolute paths in the Bash tool" --session sB >/dev/null   # 2nd distinct session
CL="$(bash "$LESSONS" cluster)"
ok "two-session correction yields one eligible cluster" "$(printf '%s' "$CL" | grep -c .)" "1"
ok "cluster reports distinct_sessions=2" "$(printf '%s\n' "$CL" | awk -F'\t' '{print $2}')" "2"
```

- [ ] **Step 2: Run, verify the new assertions fail.**

Run: `bash tests/unit/test-lessons.sh`
Expected: FAIL — `cluster` is unknown (`usage: lessons {capture|...}`), so the cluster assertions fail. Non-zero exit.

- [ ] **Step 3: Implement `cluster`.** In `skills/running-retrospectives/scripts/lessons`, add the function before the `case` block:

```bash
cmd_cluster() {
  local threshold=2
  while [ $# -gt 0 ]; do
    case "$1" in
      --threshold) threshold="${2:?--threshold needs a value}"; shift 2;;
      *) echo "unknown flag: $1" >&2; exit 2;;
    esac
  done
  local file; file="$(cand_file)"
  [ -f "$file" ] || return 0   # no candidates → no clusters → empty output
  # Group by hash; count DISTINCT sessions per hash (not raw captures); emit
  # eligible clusters as: hash <tab> distinct_sessions <tab> total <tab> text
  awk -F'\t' -v n="$threshold" '
    { total[$1]++; if (!(($1 SUBSEP $4) in seen)) { seen[$1 SUBSEP $4]=1; sess[$1]++ }; txt[$1]=$6 }
    END { for (h in total) if (sess[h] >= n) printf "%s\t%s\t%s\t%s\n", h, sess[h], total[h], txt[h] }
  ' "$file" | sort -t$'\t' -k2,2nr
}
```

And add the dispatch case (between `capture` and the `*` fallback):

```bash
  cluster) shift; cmd_cluster "$@";;
```

- [ ] **Step 4: Run, verify it passes.**

Run: `bash tests/unit/test-lessons.sh`
Expected: `lessons: 7 passed, 0 failed`, exit 0.

- [ ] **Step 5: Commit.**

```bash
git add skills/running-retrospectives/scripts/lessons tests/unit/test-lessons.sh
git commit -m "feat(running-retrospectives): lessons cluster with distinct-session recurrence"
```

---

### Task 3: `lessons decide` (RED→GREEN margin) and `lessons prune`

**Files:**
- Modify: `skills/running-retrospectives/scripts/lessons`
- Modify: `tests/unit/test-lessons.sh`

- [ ] **Step 1: Append the failing test.** In `tests/unit/test-lessons.sh`, insert immediately BEFORE the final summary line:

```bash
# decide: promote only when baseline fails the majority AND with-lesson passes the majority (k=3 → majority 2).
ok "decide promotes on 3 red-fail / 3 green-pass"  "$(bash "$LESSONS" decide --k 3 --red-fail 3 --green-pass 3; echo $?)" "promote
0"
ok "decide rejects when baseline didn't fail enough" "$(bash "$LESSONS" decide --k 3 --red-fail 1 --green-pass 3 >/dev/null; echo $?)" "1"
ok "decide rejects when lesson didn't fix it"        "$(bash "$LESSONS" decide --k 3 --red-fail 3 --green-pass 1 >/dev/null; echo $?)" "1"

# prune: removes all rows for a hash from the candidate file.
TMP3="$(mktemp -d)"; export LESSONS_HOME="$TMP3/.superpowers"
HP="$(bash "$LESSONS" capture "Prune me" --session p1)"
bash "$LESSONS" capture "Prune me" --session p2 >/dev/null
bash "$LESSONS" capture "Keep me" --session p1 >/dev/null
bash "$LESSONS" prune "$HP" >/dev/null
ok "prune removed both rows of the target hash" "$(grep -c "$HP" "$TMP3/.superpowers/lessons-candidates.tsv")" "0"
ok "prune left the other lesson intact"         "$(wc -l < "$TMP3/.superpowers/lessons-candidates.tsv" | tr -d ' ')" "1"
```

(The first assertion compares two lines: stdout `promote` then the exit code `0`.)

- [ ] **Step 2: Run, verify the new assertions fail.**

Run: `bash tests/unit/test-lessons.sh`
Expected: FAIL — `decide` and `prune` are unknown subcommands. Non-zero exit.

- [ ] **Step 3: Implement `decide` and `prune`.** In `skills/running-retrospectives/scripts/lessons`, add both functions before the `case` block:

```bash
cmd_decide() {
  local k="" rf="" gp=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --k) k="${2:?--k needs a value}"; shift 2;;
      --red-fail) rf="${2:?--red-fail needs a value}"; shift 2;;
      --green-pass) gp="${2:?--green-pass needs a value}"; shift 2;;
      *) echo "unknown flag: $1" >&2; exit 2;;
    esac
  done
  [ -n "$k" ] && [ -n "$rf" ] && [ -n "$gp" ] || { echo "usage: lessons decide --k K --red-fail RF --green-pass GP" >&2; exit 2; }
  local majority=$(( k / 2 + 1 ))   # k=3 → 2
  if [ "$rf" -ge "$majority" ] && [ "$gp" -ge "$majority" ]; then
    echo "promote"; return 0
  fi
  local reason="baseline failed $rf/$k, with-lesson passed $gp/$k; need >=$majority each"
  echo "reject: $reason"; return 1
}

cmd_prune() {
  local h="${1:-}"
  [ -n "$h" ] || { echo "usage: lessons prune <hash>" >&2; exit 2; }
  local file; file="$(cand_file)"
  [ -f "$file" ] || return 0
  local tmp; tmp="$(mktemp)"
  awk -F'\t' -v h="$h" '$1!=h' "$file" > "$tmp" && mv "$tmp" "$file"
}
```

And add both dispatch cases (before the `*` fallback):

```bash
  decide) shift; cmd_decide "$@";;
  prune)  shift; cmd_prune "$@";;
```

- [ ] **Step 4: Run, verify it passes.**

Run: `bash tests/unit/test-lessons.sh`
Expected: `lessons: 12 passed, 0 failed`, exit 0.

- [ ] **Step 5: Run the whole unit suite to confirm auto-discovery + no regressions.**

Run: `bash tests/unit/run.sh`
Expected: the existing suites still pass AND a `--- test-lessons.sh ---` section reporting `lessons: 12 passed, 0 failed`; overall exit 0.

- [ ] **Step 6: Commit.**

```bash
git add skills/running-retrospectives/scripts/lessons tests/unit/test-lessons.sh
git commit -m "feat(running-retrospectives): lessons decide (RED->GREEN margin) + prune"
```

---

### Task 4: `SKILL.md` — the conducting retrospective skill (authored under writing-skills)

**Files:**
- Create: `skills/running-retrospectives/SKILL.md`

**REQUIRED SUB-SKILL:** Use h-superpowers:writing-skills — this is TDD for process docs. The discipline below IS the RED→GREEN of that skill.

- [ ] **Step 1: RED — baseline pressure test (watch an agent fail without the skill).** Dispatch a subagent with NO knowledge of this skill, given a candidate file containing a correction that recurred across 2 sessions, and the instruction "promote durable lessons from these corrections." Document verbatim what it does. Expected baseline failures to capture: it promotes on recurrence alone (no RED→GREEN proof), and/or writes the lesson into the shipped plugin / a new file rather than the project auto-memory, and/or skips the distinct-session check. Save the observed rationalizations — they are what the skill must close.

- [ ] **Step 2: GREEN — write the minimal `SKILL.md`** addressing exactly those baseline failures. Create `skills/running-retrospectives/SKILL.md`:

```markdown
---
name: running-retrospectives
description: Use at a deliberate reflective moment (end of a working session, or when you notice you keep getting corrected on the same thing) to turn recurring project-specific corrections into validated, durable memory. Captures corrections, proves each lesson with a RED->GREEN check, promotes survivors into project auto-memory.
---

# Running Retrospectives

## Overview

Turn recurring corrections into **validated** durable lessons. The spine: **no
lesson is promoted without a failing baseline** — you must watch an agent do the
wrong thing without the lesson, and comply with it. Recurrence alone is not
validation.

This skill **conducts**; it does not re-implement sensing or proving. The
mechanical pieces live in `scripts/lessons` (a deterministic bash CLI). v1 is the
standalone floor: project-specific lessons only, promoted into the agent's project
auto-memory.

## The RED->GREEN contract (rigid — do not soften)

A clustered candidate may be promoted ONLY IF, for a reproducible scenario
distilled from its corrections:
- **RED:** an agent WITHOUT the lesson exhibits the bad behavior, AND
- **GREEN:** an agent WITH the lesson injected does not,
- across **k=3 trials each**, with the **majority margin** (`lessons decide`), AND
- a GREEN failure means **reword or reject** (<=2 rewrite attempts), never promote.

No RED (the failure won't reproduce at baseline) means there is nothing to
validate — do NOT promote.

## Procedure

1. **Capture** (run during/after the session, for each generalizable correction
   the user gave you):
   `scripts/lessons capture "<the correction, in imperative form>" --source user`
   The script stamps a CRLF-normalized content hash + the current session id
   (`$CLAUDE_CODE_SESSION_ID`) + timestamp, and dedups within a session.
2. **Cluster:** `scripts/lessons cluster` → eligible clusters (recurred across
   >=2 distinct sessions) as `hash <tab> distinct_sessions <tab> total <tab> text`.
3. **For each eligible cluster, run the inline RED->GREEN runner:**
   a. **Distill a scenario** from the cluster's corrections — a concrete task that
      recreates the situation where the agent erred. **Show it to the user** before
      running trials.
   b. **RED:** dispatch 3 fresh subagents on the scenario WITHOUT the lesson. Judge
      each: did it exhibit the bad behavior? Count failures = `RF`.
   c. **GREEN:** dispatch 3 fresh subagents on the same scenario WITH the lesson
      text injected into their instructions. Judge each: did it comply? Count
      passes = `GP`.
   d. **Decide:** `scripts/lessons decide --k 3 --red-fail RF --green-pass GP`.
      `promote` (exit 0) or `reject` (exit 1).
   e. If reject because GREEN failed: reword the lesson and retry from (b), up to
      twice, then drop it.
4. **Promote (interactive)** — only on a `promote` verdict, and only after the user
   approves what will be written:
   - Write the lesson as a **`type: feedback`** memory file in **your project
     auto-memory directory** (the one your memory instructions name for this
     project, e.g. `~/.claude/projects/<this-project>/memory/`), with a one-line
     pointer added to that `MEMORY.md`. Include the **why** and how to apply it.
   - This is **project-local** — it only applies to this project. NEVER write the
     lesson into this plugin's shipped files (skills/, CLAUDE.md). Improving the
     plugin itself is a different pipeline (writing-skills).
   - Prune the promoted cluster from candidates: `scripts/lessons prune <hash>`.
5. **Recall is automatic** — the project `MEMORY.md` is already injected each
   session, so a promoted lesson is recalled for free. Do not add a SessionStart or
   using-superpowers hook. Keep promoted lessons few; retire superseded ones
   (pruning the auto-memory is budget reclamation — it bounds per-session injection).

## Scope (v1)

- **Project-specific lessons only** — "how to work well in this project."
- Out of scope: improving h-sup the plugin (use writing-skills); cross-project
  general-behavior lessons (deferred).

## Composing with siblings (named seams — NOT built in v1)

- **agent-stalker = SENSE (Phase 2):** if installed, widen capture to agent-to-agent
  corrections from its recorded message log; source sets entry confidence. Same gate.
- **crucible = PROVE (Phase 3):** if installed, replace the inline runner with a
  crucible A/B experiment (baseline vs. the lesson commit) for statistical rigor.

Both are detected, never required. The RED->GREEN contract is identical across tiers.

## Common rationalizations, answered

| Thought | Reality |
|---------|---------|
| "It recurred twice, just promote it." | Recurrence is the entry ticket, not the proof. No RED->GREEN, no promotion. |
| "The failure won't reproduce, but the lesson is obviously right." | No reproducible RED = nothing to validate. Don't promote. |
| "One baseline run failed — good enough." | One run is noise. k=3 with a majority margin. |
| "I'll just add it to CLAUDE.md / a skill." | That bakes a project lesson into the shipped plugin. Project lessons go in project auto-memory. |
```

- [ ] **Step 3: GREEN verification — re-run the baseline scenario WITH the skill.** Dispatch a fresh subagent given this `SKILL.md` and the same candidate file from Step 1. Verify it now: clusters by distinct sessions, runs (or states it would run) RED→GREEN before promoting, targets the project auto-memory as `type: feedback`, and refuses to promote a cluster whose failure doesn't reproduce. If it finds a new loophole, add a row to the rationalizations table and re-verify (REFACTOR).

- [ ] **Step 4: Commit.**

```bash
git add skills/running-retrospectives/SKILL.md
git commit -m "feat(running-retrospectives): conducting skill (RED->GREEN gate, project-auto-memory promotion)"
```

---

### Task 5: End-to-end smoke + final verification

**Files:** none (verification only) — unless a gap is found.

- [ ] **Step 1: Mechanical end-to-end with the script** (no tokens). In a throwaway temp home, drive the full mechanical path and confirm each stage:

```bash
T="$(mktemp -d)"; export LESSONS_HOME="$T/.superpowers"
L="skills/running-retrospectives/scripts/lessons"
bash "$L" capture "Run bash tests/run-all.sh before claiming done" --session one >/dev/null
bash "$L" capture "Run bash tests/run-all.sh before claiming done" --session two >/dev/null
bash "$L" cluster                                   # expect one eligible cluster, distinct_sessions=2
H="$(bash "$L" cluster | awk -F'\t' '{print $1}')"
bash "$L" decide --k 3 --red-fail 3 --green-pass 3  # expect: promote (exit 0)
bash "$L" prune "$H"                                # expect the cluster removed
bash "$L" cluster                                   # expect empty
unset LESSONS_HOME
```
Expected: cluster shows the lesson with `2` distinct sessions; decide prints `promote`; after prune, cluster is empty.

- [ ] **Step 2: Confirm the floor touched no always-loaded surface.**

Run: `git diff --name-only main... -- skills/using-superpowers/ hooks/ && echo "---"`
Expected: no output before `---` (v1 adds NO `using-superpowers` or hook changes — recall is via the existing auto-memory).

- [ ] **Step 3: Run the full deterministic unit suite.**

Run: `bash tests/unit/run.sh`
Expected: all suites pass including `test-lessons.sh` (`lessons: 12 passed, 0 failed`); exit 0.

- [ ] **Step 4: Confirm no shipped-plugin file became a lesson store.**

Run: `git status --porcelain && echo OK`
Expected: only the intended new files under `skills/running-retrospectives/` and `tests/unit/test-lessons.sh` are tracked; no stray `memory/` directory was created inside the repo (promoted lessons live in the external project auto-memory, not in-repo).

- [ ] **Step 5: Commit any verification fixes** (only if Steps 1–4 surfaced issues).

```bash
git add -A
git commit -m "fix(running-retrospectives): verification fixes"
```
