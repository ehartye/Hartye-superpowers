# running-retrospectives Phase 3 (crucible PROVE) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use h-superpowers:subagent-driven-development, h-superpowers:team-driven-development, or h-superpowers:executing-plans to implement this plan (ask user which approach). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add crucible as a detected, preferred RED→GREEN validation tier for running-retrospectives, behind v1's engine-agnostic contract, retaining the inline floor as fallback — with zero crucible companion changes.

**Architecture:** Four new deterministic subcommands on the existing `skills/running-retrospectives/scripts/lessons` bash CLI (`detect-engine`, `scratch-harness`, `gen-spec`, `crucible-decide`) plus a tier-selection branch in `SKILL.md`. RR generates a throwaway two-commit git "harness" (baseline CLAUDE.md without the lesson, green with it), emits an `experiment.toml`, drives `crucible run` against a **fresh per-run results DB**, reads back per-approach gate-pass counts via the documented `crucible query` CLI, and feeds them through the **same v1 margin primitive** (`cmd_decide`). crucible's savings-verdict is ignored.

**Tech Stack:** Bash (cross-platform: Windows git-bash + Linux/macOS), git, the crucible CLI (v0.4.x, optional/detected). Deterministic `test-*.sh` files auto-discovered by `tests/unit/run.sh`; no external CLIs in the unit suite (crucible-dependent checks are guarded and auto-skip).

---

## File Structure

- **Modify** `skills/running-retrospectives/scripts/lessons` — add 4 subcommands + dispatch entries. Reuses `cmd_decide`, `home_dir`, existing arg-parse style.
- **Create** `tests/unit/test-lessons-crucible.sh` — deterministic unit tests for the 4 new subcommands; grows task by task; auto-discovered by `tests/unit/run.sh`.
- **Modify** `skills/running-retrospectives/SKILL.md` — add tier selection to the Procedure (`3-FLOOR` vs `3-CRUCIBLE`), document the crucible sub-procedure, update the "Composing with siblings" section (crucible PROVE is now built), add rationalization rows.
- **Modify** `docs/superpowers/specs/2026-06-06-running-retrospectives-phase3-crucible-design.md` — one clarifying sentence: fresh-DB-per-run supersedes the illustrative `WHERE experiment_id=?` filter.

**Conventions to follow (from the v1 `lessons` script):**
- `set -uo pipefail` at top; subcommands are `cmd_<name>()` functions dispatched by a `case` at the bottom.
- Flag parsing: `while [ $# -gt 0 ]; do case "$1" in --flag) var="${2:?...}"; shift 2;; *) echo "unknown flag: $1" >&2; exit 2;; esac; done`.
- Invoked as `bash scripts/lessons <subcommand>` (script is NOT marked executable — matches the `drift` precedent).
- Tests isolate state in `mktemp -d` dirs cleaned via a single `trap '... ' EXIT` that lists ALL temp dirs (see v1 `test-lessons.sh` TMP/TMP2/TMP3 pattern).

---

## Task 1: Tier detection (`detect-engine`)

Detect whether to use the crucible tier or the inline floor: crucible must be present AND its major.minor must match the pinned expected version. Anything else → `floor`. The crucible binary name is overridable via `LESSONS_CRUCIBLE_BIN` (so tests can point at a stub) and the expected version via `CRUCIBLE_EXPECTED`.

**Files:**
- Create: `tests/unit/test-lessons-crucible.sh`
- Modify: `skills/running-retrospectives/scripts/lessons`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/test-lessons-crucible.sh`:

```bash
#!/usr/bin/env bash
# Deterministic unit tests for the running-retrospectives crucible tier (no tokens).
# crucible itself is never required: detection uses a stub binary; spec/scratch
# checks are pure git+text; a guarded block runs `crucible validate` only if the
# real CLI happens to be on PATH.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LESSONS="$REPO_ROOT/skills/running-retrospectives/scripts/lessons"
PASS=0; FAIL=0
ok() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $1 — expected '$3', got '$2'"; fi; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# --- Task 1: detect-engine -------------------------------------------------
# A stub crucible that reports a matching version → engine is "crucible".
STUB="$TMP/bin"; mkdir -p "$STUB"
cat > "$STUB/crucible" <<'SH'
#!/usr/bin/env bash
[ "$1" = "--version" ] && { echo "crucible 0.4.0"; exit 0; }
exit 0
SH
chmod +x "$STUB/crucible"

ok "matching version selects crucible" \
  "$(LESSONS_CRUCIBLE_BIN="$STUB/crucible" bash "$LESSONS" detect-engine)" "crucible"

ok "absent crucible selects floor" \
  "$(LESSONS_CRUCIBLE_BIN="$TMP/bin/nope" bash "$LESSONS" detect-engine)" "floor"

# A stub reporting an older version → mismatch → floor.
cat > "$STUB/crucible-old" <<'SH'
#!/usr/bin/env bash
[ "$1" = "--version" ] && { echo "crucible 0.3.0"; exit 0; }
exit 0
SH
chmod +x "$STUB/crucible-old"
ok "version mismatch selects floor" \
  "$(LESSONS_CRUCIBLE_BIN="$STUB/crucible-old" bash "$LESSONS" detect-engine)" "floor"

echo "lessons-crucible: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/unit/test-lessons-crucible.sh`
Expected: FAIL — `detect-engine` is an unknown subcommand (`usage: lessons {capture|cluster|decide|prune} ...`), so the three `ok` checks report wrong values.

- [ ] **Step 3: Add `cmd_detect_engine` and dispatch entry**

In `skills/running-retrospectives/scripts/lessons`, add this function (after `cmd_prune`, before the final `case`):

```bash
cmd_detect_engine() {
  local bin="${LESSONS_CRUCIBLE_BIN:-crucible}"
  local expected="${CRUCIBLE_EXPECTED:-0.4}"   # pinned major.minor; bump when crucible's contract moves
  local out ver
  if out="$("$bin" --version 2>/dev/null)"; then
    ver="$(printf '%s' "$out" | grep -oE '[0-9]+\.[0-9]+' | head -1)"
    if [ "$ver" = "$expected" ]; then echo "crucible"; return 0; fi
  fi
  echo "floor"
}
```

Add to the dispatch `case` (before the `*)` default):

```bash
  detect-engine) shift; cmd_detect_engine "$@";;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/unit/test-lessons-crucible.sh`
Expected: PASS — `lessons-crucible: 3 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add skills/running-retrospectives/scripts/lessons tests/unit/test-lessons-crucible.sh
git commit -m "feat(rr): crucible tier detection (detect-engine)"
```

---

## Task 2: Scratch harness construction (`scratch-harness`)

Build the throwaway git repo crucible materializes as its two variants: a `baseline` commit/tag with a CLAUDE.md that does NOT contain the lesson, and a `green` commit/tag that does. The only file that differs between the two refs is `CLAUDE.md` (so the experiment's `editable_surface = ["CLAUDE.md"]` holds).

**Files:**
- Modify: `tests/unit/test-lessons-crucible.sh`
- Modify: `skills/running-retrospectives/scripts/lessons`

- [ ] **Step 1: Write the failing test**

Insert before the final `echo "lessons-crucible: ..."` line in `tests/unit/test-lessons-crucible.sh`:

```bash
# --- Task 2: scratch-harness ----------------------------------------------
HARNESS="$TMP/harness"
LESSON="Always run the test suite before claiming the work is done."
bash "$LESSONS" scratch-harness "$HARNESS" "$LESSON"

ok "baseline ref exists" "$(git -C "$HARNESS" rev-parse --verify -q baseline >/dev/null; echo $?)" "0"
ok "green ref exists"    "$(git -C "$HARNESS" rev-parse --verify -q green    >/dev/null; echo $?)" "0"
ok "only CLAUDE.md differs between refs" \
  "$(git -C "$HARNESS" diff baseline green --name-only)" "CLAUDE.md"
ok "baseline has no lesson" \
  "$(git -C "$HARNESS" show baseline:CLAUDE.md | grep -c "$LESSON")" "0"
ok "green carries the lesson" \
  "$(git -C "$HARNESS" show green:CLAUDE.md | grep -c "$LESSON")" "1"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/unit/test-lessons-crucible.sh`
Expected: FAIL — `scratch-harness` is unknown; the git refs don't exist so the `rev-parse` checks return non-zero and the diff is empty.

- [ ] **Step 3: Add `cmd_scratch_harness` and dispatch entry**

Add the function to `skills/running-retrospectives/scripts/lessons`:

```bash
cmd_scratch_harness() {
  local dir="${1:-}" lesson="${2:-}"
  [ -n "$dir" ] && [ -n "$lesson" ] || { echo "usage: lessons scratch-harness <dir> <lesson-text>" >&2; exit 2; }
  mkdir -p "$dir"
  git -C "$dir" init -q
  git -C "$dir" config user.email "rr@local"
  git -C "$dir" config user.name "running-retrospectives"
  git -C "$dir" config commit.gpgsign false
  # baseline: CLAUDE.md WITHOUT the lesson (stable marker so the file exists in both refs).
  printf '# Project guidance\n' > "$dir/CLAUDE.md"
  git -C "$dir" add CLAUDE.md
  git -C "$dir" commit -qm baseline
  git -C "$dir" tag baseline
  # green: same file WITH the lesson appended.
  printf '# Project guidance\n\n%s\n' "$lesson" > "$dir/CLAUDE.md"
  git -C "$dir" add CLAUDE.md
  git -C "$dir" commit -qm green
  git -C "$dir" tag green
}
```

Add to the dispatch `case`:

```bash
  scratch-harness) shift; cmd_scratch_harness "$@";;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/unit/test-lessons-crucible.sh`
Expected: PASS — `lessons-crucible: 8 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add skills/running-retrospectives/scripts/lessons tests/unit/test-lessons-crucible.sh
git commit -m "feat(rr): scratch-harness builds baseline/green refs for crucible"
```

---

## Task 3: Experiment spec generation (`gen-spec`)

Emit a well-formed `experiment.toml` pointing at the scratch harness, with the two approaches, the `CLAUDE.md` editable surface, `trials=3`, and an optional deterministic `[gate] command`. Also add a **guarded** integration check that runs the real `crucible validate` only when the CLI is on PATH (so the deterministic suite never depends on it).

**Files:**
- Modify: `tests/unit/test-lessons-crucible.sh`
- Modify: `skills/running-retrospectives/scripts/lessons`

- [ ] **Step 1: Write the failing test**

Insert before the final `echo` line in `tests/unit/test-lessons-crucible.sh`:

```bash
# --- Task 3: gen-spec ------------------------------------------------------
SPEC="$(bash "$LESSONS" gen-spec --harness "$HARNESS" \
         --task "Implement add(a,b) and tell me when it is done." \
         --gate-command "grep -q 'npm test' transcript.txt")"

ok "spec sets harness path"        "$(printf '%s\n' "$SPEC" | grep -c "harness = \"$HARNESS\"")" "1"
ok "spec base_ref is baseline"     "$(printf '%s\n' "$SPEC" | grep -c 'base_ref = "baseline"')" "1"
ok "spec trials default 3"         "$(printf '%s\n' "$SPEC" | grep -c 'trials = 3')" "1"
ok "spec restricts surface"        "$(printf '%s\n' "$SPEC" | grep -Fc 'allow = ["CLAUDE.md"]')" "1"
ok "spec has baseline approach"    "$(printf '%s\n' "$SPEC" | grep -c 'name = "baseline"')" "1"
ok "spec has green approach"       "$(printf '%s\n' "$SPEC" | grep -c 'name = "green"')" "1"
ok "spec carries gate command"     "$(printf '%s\n' "$SPEC" | grep -c "command = ")" "1"

# Guarded integration: only when the real crucible CLI is installed. Skips
# silently otherwise so the deterministic suite has no external dependency.
if command -v crucible >/dev/null 2>&1; then
  printf '%s\n' "$SPEC" > "$TMP/exp.toml"
  ok "real crucible validate accepts the generated spec" \
    "$(crucible validate "$TMP/exp.toml" >/dev/null 2>&1; echo $?)" "0"
else
  echo "  (crucible not installed — skipping live validate check)"
fi
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/unit/test-lessons-crucible.sh`
Expected: FAIL — `gen-spec` is unknown, so `$SPEC` is the usage error and every `grep -c` returns 0.

- [ ] **Step 3: Add `cmd_gen_spec` and dispatch entry**

Add the function to `skills/running-retrospectives/scripts/lessons`:

```bash
cmd_gen_spec() {
  local harness="" task="" gate_cmd="" judge_model="claude-haiku-4-5-20251001" trials=3
  while [ $# -gt 0 ]; do
    case "$1" in
      --harness) harness="${2:?--harness needs a value}"; shift 2;;
      --task) task="${2:?--task needs a value}"; shift 2;;
      --gate-command) gate_cmd="${2:?--gate-command needs a value}"; shift 2;;
      --judge-model) judge_model="${2:?--judge-model needs a value}"; shift 2;;
      --trials) trials="${2:?--trials needs a value}"; shift 2;;
      *) echo "unknown flag: $1" >&2; exit 2;;
    esac
  done
  [ -n "$harness" ] && [ -n "$task" ] || { echo "usage: lessons gen-spec --harness DIR --task TEXT [--gate-command CMD] [--judge-model M] [--trials N]" >&2; exit 2; }
  cat <<EOF
[experiment]
name = "rr-lesson-validation"
harness = "$harness"
base_ref = "baseline"
trials = $trials

[test_project]
task = "$task"

[editable_surface]
allow = ["CLAUDE.md"]
EOF
  if [ -n "$gate_cmd" ]; then
    printf '\n[gate]\ncommand = "%s"\n' "$gate_cmd"
  fi
  cat <<EOF

[judge]
model = "$judge_model"

[[approach]]
name = "baseline"
ref = "baseline"

[[approach]]
name = "green"
ref = "green"
EOF
}
```

Add to the dispatch `case`:

```bash
  gen-spec) shift; cmd_gen_spec "$@";;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/unit/test-lessons-crucible.sh`
Expected: PASS — `lessons-crucible: 15 passed, 0 failed` (16 if the real crucible CLI is installed and the guarded live-validate check runs; otherwise it prints the skip note).

- [ ] **Step 5: Commit**

```bash
git add skills/running-retrospectives/scripts/lessons tests/unit/test-lessons-crucible.sh
git commit -m "feat(rr): gen-spec emits crucible experiment.toml"
```

---

## Task 4: Crucible result parsing + margin decision (`crucible-decide`)

Read the encoded `crucible query` output (`approach:passes/total` per line, possibly wrapped in a Python dict repr) from stdin, derive RED-fail count (baseline failures = total − passes) and GREEN-pass count (green passes), and feed them through the **existing** `cmd_decide` primitive so both tiers share one margin rule. Promote → exit 0; reject → exit 1.

**Files:**
- Modify: `tests/unit/test-lessons-crucible.sh`
- Modify: `skills/running-retrospectives/scripts/lessons`

- [ ] **Step 1: Write the failing test**

Insert before the final `echo` line in `tests/unit/test-lessons-crucible.sh`:

```bash
# --- Task 4: crucible-decide ----------------------------------------------
# Output mimics `crucible query "... approach||':'||SUM(gate_passed)||'/'||COUNT(*) ..."`,
# which prints one Python dict repr per row. crucible-decide ignores the wrapper.
PROMOTE_IN="{'r': 'baseline:0/3'}
{'r': 'green:3/3'}"
NORED_IN="{'r': 'baseline:2/3'}
{'r': 'green:3/3'}"
NOGREEN_IN="{'r': 'baseline:0/3'}
{'r': 'green:1/3'}"

ok "promote when baseline fails majority and green passes majority" \
  "$(printf '%s\n' "$PROMOTE_IN" | bash "$LESSONS" crucible-decide --k 3; echo $?)" "promote
0"
ok "reject when baseline did not fail enough (no RED)" \
  "$(printf '%s\n' "$NORED_IN" | bash "$LESSONS" crucible-decide --k 3 >/dev/null; echo $?)" "1"
ok "reject when green did not pass enough (no GREEN)" \
  "$(printf '%s\n' "$NOGREEN_IN" | bash "$LESSONS" crucible-decide --k 3 >/dev/null; echo $?)" "1"
ok "reject (exit 1) when results are unparseable" \
  "$(printf 'garbage\n' | bash "$LESSONS" crucible-decide --k 3 >/dev/null 2>&1; echo $?)" "1"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/unit/test-lessons-crucible.sh`
Expected: FAIL — `crucible-decide` is unknown; exit codes are 2 (usage error) not the expected promote/1/1/1.

- [ ] **Step 3: Add `cmd_crucible_decide` and dispatch entry**

Add the function to `skills/running-retrospectives/scripts/lessons` (it reuses `cmd_decide`, so define it after `cmd_decide`):

```bash
cmd_crucible_decide() {
  local k=3
  while [ $# -gt 0 ]; do
    case "$1" in
      --k) k="${2:?--k needs a value}"; shift 2;;
      *) echo "unknown flag: $1" >&2; exit 2;;
    esac
  done
  local input base green
  input="$(cat)"
  # Extract "baseline:PASSES/TOTAL" and "green:PASSES/TOTAL" regardless of any
  # surrounding dict/quote wrapper that `crucible query` prints.
  base="$(printf '%s' "$input" | grep -oE 'baseline:[0-9]+/[0-9]+' | head -1)"
  green="$(printf '%s' "$input" | grep -oE 'green:[0-9]+/[0-9]+' | head -1)"
  [ -n "$base" ] && [ -n "$green" ] || { echo "reject: could not parse crucible results (baseline='$base' green='$green')" >&2; return 1; }
  local bp bt gp
  bp="${base#baseline:}"; bt="${bp#*/}"; bp="${bp%/*}"   # baseline passes, total
  gp="${green#green:}";   gp="${gp%/*}"                  # green passes
  local rf=$(( bt - bp ))                                # RED-fail = baseline failures
  cmd_decide --k "$k" --red-fail "$rf" --green-pass "$gp"
}
```

Add to the dispatch `case`:

```bash
  crucible-decide) shift; cmd_crucible_decide "$@";;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/unit/test-lessons-crucible.sh`
Expected: PASS — `lessons-crucible: 19 passed, 0 failed`.

- [ ] **Step 5: Run the full unit suite to confirm nothing regressed**

Run: `bash tests/unit/run.sh`
Expected: every block passes, including `lessons: 12 passed` (v1, untouched) and `lessons-crucible: 19 passed`; overall exit 0.

- [ ] **Step 6: Commit**

```bash
git add skills/running-retrospectives/scripts/lessons tests/unit/test-lessons-crucible.sh
git commit -m "feat(rr): crucible-decide parses query output into the shared margin rule"
```

---

## Task 5: SKILL.md crucible tier (authored under writing-skills)

Add tier selection to the Procedure so the skill routes to crucible when present and the inline floor otherwise, document the crucible sub-procedure, and update the siblings section. Follow `h-superpowers:writing-skills` — the change is a process-doc edit; its RED→GREEN check is the behavioral pressure test in Step 4.

**Files:**
- Modify: `skills/running-retrospectives/SKILL.md`
- Create: `tests/claude-code/test-running-retrospectives-crucible-tier.sh`

- [ ] **Step 1: Write the failing behavioral test**

Create `tests/claude-code/test-running-retrospectives-crucible-tier.sh`. It puts a crucible stub on PATH (so the skill's `detect-engine` returns `crucible`) and asserts the skill routes to the crucible tier rather than only the inline subagent runner. Keep the assertion loose — per the brittle-behavioral-test caution, the load-bearing guarantees live in the unit suite; this only checks routing.

```bash
#!/usr/bin/env bash
# Behavioral: with crucible "installed" (stub on PATH), the running-retrospectives
# skill should route validation through the crucible tier, not the inline floor.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/test-helpers.sh"

# Stub crucible so detect-engine resolves to the crucible tier without spending tokens.
STUBDIR="$(mktemp -d)"; trap 'rm -rf "$STUBDIR"' EXIT
cat > "$STUBDIR/crucible" <<'SH'
#!/usr/bin/env bash
case "$1" in
  --version) echo "crucible 0.4.0";;
  validate)  echo "editable surface OK for all approaches";;
  run)       echo "verdict=keep_baseline winner=baseline"; echo "report: /tmp/r.md";;
  query)     echo "{'r': 'baseline:0/3'}"; echo "{'r': 'green:3/3'}";;
esac
exit 0
SH
chmod +x "$STUBDIR/crucible"
export PATH="$STUBDIR:$PATH"

run_claude "I'm running a retrospective on a lesson that has already recurred across two sessions and is eligible. crucible is installed. Walk me through exactly how you would validate it before promoting — name the engine and the concrete commands you'd run." 90

assert_contains "$CLAUDE_OUTPUT" "crucible" "routes to the crucible tier"
PASS_FAIL=$?
exit "$PASS_FAIL"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/claude-code/run-skill-tests.sh --test test-running-retrospectives-crucible-tier.sh`
Expected: FAIL — current SKILL.md only describes the inline floor; the agent does not route to crucible because the skill gives it no crucible procedure.

- [ ] **Step 3: Edit SKILL.md — add tier selection and the crucible sub-procedure**

In `skills/running-retrospectives/SKILL.md`, change the opening of Procedure step 3. Replace this line:

```markdown
3. **For each eligible cluster, run the inline RED->GREEN runner:**
```

with:

```markdown
3. **For each eligible cluster, select the validation engine and run the
   RED->GREEN contract.** Run `bash scripts/lessons detect-engine`:
   - prints `crucible` → use **3-CRUCIBLE** (statistical tier),
   - prints `floor` → use **3-FLOOR** (the inline runner; v1 behavior).
   The contract (RED, GREEN, k=3, majority margin, <=2 rewords, no-RED-no-promote)
   is identical across tiers — only who runs the trials changes. If crucible is
   absent or fails at any point, fall back to 3-FLOOR; never skip the gate.

   **3-FLOOR — inline runner:**
```

(The existing sub-steps a–e stay exactly as they are; they are now the body of 3-FLOOR.)

Then immediately after sub-step (e) of 3-FLOOR, add the crucible sub-procedure:

```markdown
   **3-CRUCIBLE — crucible as the PROVE engine:**
   a. **Distill a scenario** — a concrete task recreating where the agent erred.
      **Show it to the user** before spending tokens (same as 3-FLOOR).
   b. **Build the variant pair:**
      `bash scripts/lessons scratch-harness "$TMP/harness" "<the lesson, imperative form>"`
      (a throwaway git repo: `baseline` ref without the lesson, `green` ref with it).
   c. **Generate the experiment** with a deterministic gate (the highest-fidelity
      signal — prefer it):
      `bash scripts/lessons gen-spec --harness "$TMP/harness" --task "<scenario>" --gate-command "<observable check>" > "$TMP/exp.toml"`
      `gen-spec` emits a `[gate] command`. If the behavior is only checkable via
      output assertions or an LLM judge, hand-edit `$TMP/exp.toml` to add
      `[gate] assertions = [...]` or a `[judge.rubric]` `followed-lesson` dimension
      before validate — crucible supports both (see its spec). Generating those
      richer gate forms is a deliberate follow-up, not part of this phase.
   d. **Free pre-check (no tokens):** `crucible validate "$TMP/exp.toml"`. Fix any
      editable-surface error before the paid run.
   e. **User approves** the scenario and the spec before the paid run.
   f. **Run the trials:** `crucible run "$TMP/exp.toml" --db "$TMP/results.db"`
      (a fresh per-run DB, so the trials table holds exactly this experiment).
   g. **Decide (RR owns the margin; crucible's own verdict is ignored):**
      `crucible query "SELECT approach || ':' || SUM(gate_passed) || '/' || COUNT(*) AS r FROM trials GROUP BY approach" --db "$TMP/results.db" | bash scripts/lessons crucible-decide --k 3`
      → `promote` (exit 0) or `reject` (exit 1). A baseline that passes the majority
      means **no RED reproduced — not promotable** (crucible-decide enforces this).
   h. If rejected because GREEN failed: reword the lesson and retry from (b), up to
      twice, then drop it.
```

- [ ] **Step 4: Update the "Composing with siblings" section**

Replace the crucible bullet in that section:

```markdown
- **crucible = PROVE (Phase 3):** if installed, replace the inline runner with a
  crucible A/B experiment (baseline vs. the lesson commit) for statistical rigor.
```

with:

```markdown
- **crucible = PROVE (Phase 3, BUILT):** when `detect-engine` finds a
  version-matched crucible, validation runs as a crucible A/B experiment
  (baseline ref vs. green ref) for statistical rigor — see 3-CRUCIBLE. RR
  generates the experiment and owns the margin decision; crucible's
  savings-oriented verdict is not used. Absent/mismatched crucible falls back to
  the inline floor.
```

And add two rows to the "Common rationalizations, answered" table:

```markdown
| "crucible isn't installed — skip the validation this once." | No. Fall back to the inline floor (3-FLOOR). The gate is never skipped. |
| "crucible says keep_baseline, so reject." | crucible's verdict is savings-tuned and irrelevant here. RR reads raw gate-pass counts via crucible-decide; that — not crucible's verdict — is the RED->GREEN decision. |
```

- [ ] **Step 5: Run the behavioral test to verify it passes**

Run: `bash tests/claude-code/run-skill-tests.sh --test test-running-retrospectives-crucible-tier.sh`
Expected: PASS — the agent names crucible and the concrete commands. (If it flakes on phrasing rather than substance, adjust the assertion text, not the skill — per the brittle-behavioral-test note.)

- [ ] **Step 6: Commit**

```bash
git add skills/running-retrospectives/SKILL.md tests/claude-code/test-running-retrospectives-crucible-tier.sh
git commit -m "feat(rr): SKILL.md routes to crucible PROVE tier when installed"
```

---

## Task 6: End-to-end smoke + verification + spec note

Confirm the whole tier composes deterministically, the v1 floor is untouched, and reconcile the spec with the fresh-DB resolution discovered during planning.

**Files:**
- Modify: `docs/superpowers/specs/2026-06-06-running-retrospectives-phase3-crucible-design.md`

- [ ] **Step 1: Add the fresh-DB clarification to the spec**

In the spec's **Decision — RR owns the margin** section, the code block illustrates the query with `WHERE experiment_id=?`. Add this sentence immediately after that code block:

```markdown
In practice RR runs each experiment against a **fresh throwaway `--db`**, so the
`trials` table holds exactly one experiment and the per-approach query needs no
`experiment_id` filter (crucible's `run` does not print the id, and `crucible
query` takes no bind parameters). The query encodes `approach:passes/total` as a
scalar so the result is parseable regardless of the dict-repr row wrapper.
```

- [ ] **Step 2: Run the full deterministic unit suite**

Run: `bash tests/unit/run.sh`
Expected: exit 0. Includes `lessons: 12 passed` (v1 floor primitives untouched) and `lessons-crucible: 19 passed` (new tier). Confirms both tiers share `cmd_decide` and the v1 path still works.

- [ ] **Step 3: Confirm graceful degradation explicitly**

Run:
```bash
LESSONS="skills/running-retrospectives/scripts/lessons"
LESSONS_CRUCIBLE_BIN=/nonexistent bash "$LESSONS" detect-engine
```
Expected output: `floor` — with no crucible, the skill takes the v1 inline path. This is the safety net: crucible's absence never weakens validation.

- [ ] **Step 4: Confirm the 3-FLOOR text is unchanged (no behavioral regression)**

v1 shipped no committed `tests/claude-code/` behavioral test for running-retrospectives
(its coverage is the unit suite + the writing-skills baseline), so there is no floor
behavioral test to re-run. The regression guard is instead that the 3-FLOOR
sub-steps must be **byte-identical** to v1 — Task 5 only adds text around them.

Run: `git diff main -- skills/running-retrospectives/SKILL.md`
Expected: the diff shows only **additions** (the tier-selection intro, the 3-CRUCIBLE
block, the siblings/rationalization updates). The original step-3 sub-steps a–e
appear unchanged (now under the 3-FLOOR heading). If any floor sub-step line shows
as modified/deleted, restore it — the floor path must stay exactly as v1 shipped it.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/specs/2026-06-06-running-retrospectives-phase3-crucible-design.md
git commit -m "docs(rr): note fresh-DB-per-run supersedes the illustrative experiment_id filter"
```

---

## Notes for the executor

- **Reuse, don't duplicate.** `cmd_crucible_decide` MUST call `cmd_decide` for the
  margin — do not re-implement the majority math. That shared primitive is what
  guarantees the crucible tier and the inline floor agree.
- **Zero crucible changes.** Everything is in `lessons` + `SKILL.md`. If you find
  yourself wanting to edit the crucible repo, stop — that's out of scope (deferred
  to a future `[decision] mode="behavior"` only if a second consumer needs it).
- **No Phase 2.** Do not touch capture sources / agent-stalker. `--source` stays
  user-only as in v1.
- **Gate strategy is deterministic-command-only this phase.** `gen-spec` emits a
  `[gate] command` (the spec's preferred, highest-fidelity tier). The assertions and
  judge-rubric fallbacks the spec names are reachable by hand-editing the generated
  toml, but emitting them from `gen-spec` is a deliberate follow-up — don't build it
  here unless the user asks.
- **Cross-platform.** All bash must run under Windows git-bash and Linux/macOS.
  `git -C`, `grep -oE`, `printf`, parameter expansion are all portable; avoid
  GNU-only flags.
- **Verification before "done"** (h-superpowers:verification-before-completion):
  paste the actual `bash tests/unit/run.sh` output showing both `lessons` and
  `lessons-crucible` green before claiming the task complete.
```
