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

ok "CRUCIBLE_EXPECTED override is honored" \
  "$(LESSONS_CRUCIBLE_BIN="$STUB/crucible" CRUCIBLE_EXPECTED="0.3" bash "$LESSONS" detect-engine)" "floor"

# A stub reporting an older version → mismatch → floor.
cat > "$STUB/crucible-old" <<'SH'
#!/usr/bin/env bash
[ "$1" = "--version" ] && { echo "crucible 0.3.0"; exit 0; }
exit 0
SH
chmod +x "$STUB/crucible-old"
ok "version mismatch selects floor" \
  "$(LESSONS_CRUCIBLE_BIN="$STUB/crucible-old" bash "$LESSONS" detect-engine)" "floor"

# --- Task 2: scratch-harness ----------------------------------------------
HARNESS="$TMP/harness"
LESSON="Always run the test suite before claiming the work is done."
bash "$LESSONS" scratch-harness "$HARNESS" "$LESSON"

ok "baseline ref exists" "$(git -C "$HARNESS" rev-parse --verify -q baseline >/dev/null; echo $?)" "0"
ok "green ref exists"    "$(git -C "$HARNESS" rev-parse --verify -q green    >/dev/null; echo $?)" "0"
ok "only CLAUDE.md differs between refs" \
  "$(git -C "$HARNESS" diff baseline green --name-only)" "CLAUDE.md"
ok "baseline has no lesson" \
  "$(git -C "$HARNESS" show baseline:CLAUDE.md | grep -cF "$LESSON")" "0"
ok "green carries the lesson" \
  "$(git -C "$HARNESS" show green:CLAUDE.md | grep -cF "$LESSON")" "1"

echo "lessons-crucible: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
