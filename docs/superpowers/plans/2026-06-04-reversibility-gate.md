# Reversibility-Centered Right-Sizing Gate Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use h-superpowers:subagent-driven-development, h-superpowers:team-driven-development, or h-superpowers:executing-plans to implement this plan (ask user which approach). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the v2 escalation-trigger gate with a reversibility-centered gate — design upfront only for irreversible/destructive or obviously-large work; act + arm the spike-checkpoint on everything reversible.

**Architecture:** Prose edits to two skill files, gated by a deterministic structural lint (no tokens). TDD shape: write the lint assertions (red, because the current v2 text lacks the new phrasing) → make the edit → lint green. The lint pins the load-bearing pieces (the reversibility question, the irreversible list, the obvious-size override, the discipline spine) so future edits can't silently drop them.

**Tech Stack:** bash, markdown skills. Repo is bash-only; tests are self-contained `test-*.sh` discovered by `tests/unit/run.sh`. Per spec `docs/superpowers/specs/2026-06-04-reversibility-gate-design.md`.

---

### Task 1: Reversibility gate in `using-superpowers`

**Files:**
- Create: `tests/unit/test-right-sizing-gate.sh`
- Modify: `skills/using-superpowers/SKILL.md` (the `## Right-Sizing Process` section)

- [ ] **Step 1: Write the failing lint** — create `tests/unit/test-right-sizing-gate.sh`:

```bash
#!/usr/bin/env bash
# Structural lint for the reversibility-centered right-sizing gate (deterministic, no tokens).
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
US="$REPO_ROOT/skills/using-superpowers/SKILL.md"
PASS=0; FAIL=0
has()   { if grep -qF "$2" "$1"; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $(basename "$1") missing '$2'"; fi; }
hasnt() { if grep -qF "$2" "$1"; then FAIL=$((FAIL+1)); echo "FAIL: $(basename "$1") still contains '$2'"; else PASS=$((PASS+1)); fi; }

# using-superpowers: the reversibility gate
has   "$US" "rollback fully undo it"          # the one reversibility question
has   "$US" "schema migrations"               # irreversible list
has   "$US" "external side effects"           # irreversible list
has   "$US" "Obviously large"                 # the obvious-size override
has   "$US" "test-driven-development"          # discipline spine retained
hasnt "$US" "requirements are ambiguous or underspecified"  # v2 ambiguity-trigger removed

echo "right-sizing gate lint: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run, verify it fails**

Run: `bash tests/unit/test-right-sizing-gate.sh`
Expected: FAIL — the current v2 text lacks "rollback fully undo it", "schema migrations", etc., and still contains "requirements are ambiguous or underspecified". Non-zero exit.

- [ ] **Step 3: Make the edit.** In `skills/using-superpowers/SKILL.md`, READ the file first to confirm the anchor. Replace the entire block from the heading `## Right-Sizing Process (default to action; escalate on triggers)` through the `**Autonomous / headless runs:**` paragraph (i.e. everything up to, but NOT including, the `### Spike-checkpoint (when you skip design)` line) with exactly:

```markdown
## Right-Sizing Process (default to action; gate only what you can't take back)

Before applying process, ask one question: **if this goes wrong, can a `git` rollback fully undo it?**

- **Reversible (yes)** → **act now.** State a one-line intent ("Adding X to do Y"), implement directly under the discipline below, and arm the spike-checkpoint. A wrong call is recoverable — the checkpoint catches drift and you redesign from the spike. Don't pre-design reversible work just because it's unclear or has a few moving parts; that's what the checkpoint is for.
- **Irreversible / destructive (no)** → **design upfront, always.** The time machine can't save you here — the harm escapes a `git` rollback:
  - persisted-data changes / schema migrations
  - deleting or overwriting data, files, or history git can't restore (force-push, history rewrite, data drops)
  - changing a published or public contract others already depend on (public API, released package)
  - external side effects (payments, emails / notifications, third-party API calls)
  - security, auth, secrets, or crypto
- **Obviously large / multi-subsystem** → **design upfront** too — not because it's irreversible, but because spiking a known-big effort wastes the spike (you'd trip the drift checkpoint almost immediately and roll back a lot). Design the elephant; don't spike it.

Two entrances, same discipline: if the user explicitly asks to design (e.g. invokes brainstorming directly), honor it and design, scaled to complexity. Right-sizing decides ceremony when *you* detect creative work — not when the user already asked for design.

**Discipline — never skipped, at any size:**

- **test-driven-development** — a failing test before the code that passes it.
- **systematic-debugging** — root cause before fix.
- **verification-before-completion** — evidence before any "done" / "fixed" / "passing" claim.

**Autonomous / headless runs:** with no user to approve, never stall waiting for an approval that cannot come. For an irreversible/destructive action you cannot safely take alone, state the open question and the most reasonable assumption explicitly before proceeding; for reversible work, act and let the checkpoint catch a mis-size.
```

Leave the `### Spike-checkpoint (when you skip design)` subsection that follows unchanged.

- [ ] **Step 4: Run, verify it passes**

Run: `bash tests/unit/test-right-sizing-gate.sh`
Expected: `right-sizing gate lint: 6 passed, 0 failed`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add tests/unit/test-right-sizing-gate.sh skills/using-superpowers/SKILL.md
git commit -m "feat(right-sizing): reversibility-centered gate in using-superpowers"
```

---

### Task 2: HARD-GATE + anti-pattern in `brainstorming`

**Files:**
- Modify: `tests/unit/test-right-sizing-gate.sh` (append brainstorming assertions)
- Modify: `skills/brainstorming/SKILL.md` (the `<HARD-GATE>` block and the anti-pattern section)

- [ ] **Step 1: Append failing assertions.** In `tests/unit/test-right-sizing-gate.sh`, insert the following block immediately BEFORE the final summary line (`echo "right-sizing gate lint: ..."`):

```bash
# brainstorming: gate + anti-pattern
BR="$REPO_ROOT/skills/brainstorming/SKILL.md"
has   "$BR" "irreversible or destructive"     # gate keys on reversibility
has   "$BR" "obviously large"                 # obvious-size override
has   "$BR" "rollback"                        # references the git-rollback test
has   "$BR" "un-migrate"                       # anti-pattern's irreversible example
has   "$BR" "blast radius"                      # anti-pattern framing
hasnt "$BR" "Under-design:"                    # old anti-pattern bullet replaced
```

- [ ] **Step 2: Run, verify the new assertions fail**

Run: `bash tests/unit/test-right-sizing-gate.sh`
Expected: FAIL on the brainstorming assertions (current v2 HARD-GATE lacks "irreversible or destructive", "un-migrate", "blast radius", and still has "Under-design:"). Non-zero exit.

- [ ] **Step 3: Edit the HARD-GATE.** In `skills/brainstorming/SKILL.md`, READ the file, then replace the entire current `<HARD-GATE>...</HARD-GATE>` block with exactly:

```markdown
<HARD-GATE>
Escalate to a design-and-approval cycle before implementing when the work is **irreversible or destructive** — its harm escapes a `git` rollback (data / schema migrations, deleting or overwriting data or history, a published / public contract, external side effects like payments or emails, security / auth / secrets) — OR it is **obviously large / multi-subsystem**, OR the **user asked to design** (see using-superpowers → Right-Sizing Process). When escalating, do NOT invoke any implementation skill, write code, scaffold, or take implementation action until you have presented a design and the user has approved it.

Otherwise — reversible, not-obviously-large work — do NOT gate: state a one-line intent, implement directly under the discipline (test-driven-development, systematic-debugging, verification-before-completion), and arm the spike-checkpoint so a mis-size is recoverable. In autonomous/headless runs with no user to approve, never stall.
</HARD-GATE>
```

- [ ] **Step 4: Edit the anti-pattern.** In the same file, replace the entire `## Anti-Pattern: Mis-Sizing The Ceremony` section (the heading and its body, up to but not including the next `##`/`<` heading — currently the `## Checklist` heading) with exactly:

```markdown
## Anti-Pattern: Mis-Sizing The Ceremony

Size by reversibility and blast radius, not line count. Two failure modes:

- **Over-ceremony:** gating reversible work you could've just done — a one-line helper, a rename, a self-contained function. If a wrong call is recoverable (the spike-checkpoint has your back), don't pay for a design-and-approval cycle up front.
- **Under-protection:** treating an *irreversible* action as routine because the code looks small. A three-line schema migration is not "Quick" — you can't un-migrate. If the harm escapes a `git` rollback, design first, however short the diff.
```

- [ ] **Step 5: Run, verify it passes**

Run: `bash tests/unit/test-right-sizing-gate.sh`
Expected: `right-sizing gate lint: 12 passed, 0 failed`, exit 0.

- [ ] **Step 6: Commit**

```bash
git add tests/unit/test-right-sizing-gate.sh skills/brainstorming/SKILL.md
git commit -m "feat(right-sizing): reversibility gate in brainstorming HARD-GATE + anti-pattern"
```

---

### Task 3: Final verification

**Files:** none (verification only)

- [ ] **Step 1: Run the whole deterministic unit suite**

Run: `bash tests/unit/run.sh`
Expected: all three suites pass — `drift: 13 passed`, `skill lint: 6 passed`, `right-sizing gate lint: 12 passed`, exit 0. (The aggregator auto-discovers `test-right-sizing-gate.sh`.)

- [ ] **Step 2: Confirm internal consistency of the gate references**

Run: `grep -n "rollback fully undo" skills/using-superpowers/SKILL.md && grep -n "irreversible or destructive" skills/brainstorming/SKILL.md && echo OK`
Expected: prints the matching lines and `OK` — both files carry the reversibility framing.

- [ ] **Step 3: Confirm no stale v2 trigger language remains**

Run: `grep -rn "escalate on triggers\|requirements are ambiguous or underspecified\|Under-design:" skills/using-superpowers/SKILL.md skills/brainstorming/SKILL.md || echo "clean: no v2 trigger language"`
Expected: `clean: no v2 trigger language`.

- [ ] **Step 4: (Optional — spends tokens / needs Claude API) behavioral check**

The using-superpowers/brainstorming edits could affect skill-triggering behavior. Only if you have API access:
Run: `bash tests/claude-code/run-skill-tests.sh --test test-using-superpowers.sh`
Expected: passes. Not a required gate (the deterministic lint in Step 1 is).

- [ ] **Step 5: Commit any verification fixes** (only if Steps 1–3 surfaced issues)

```bash
git add -A
git commit -m "fix(right-sizing): verification fixes"
```
