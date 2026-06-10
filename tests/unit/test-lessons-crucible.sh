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
# A stub crucible that meets the minimum version → engine is "crucible".
STUB="$TMP/bin"; mkdir -p "$STUB"
cat > "$STUB/crucible" <<'SH'
#!/usr/bin/env bash
[ "$1" = "--version" ] && { echo "crucible 0.6.1"; exit 0; }
exit 0
SH
chmod +x "$STUB/crucible"

ok "version meeting minimum selects crucible" \
  "$(LESSONS_CRUCIBLE_BIN="$STUB/crucible" bash "$LESSONS" detect-engine)" "crucible"

ok "absent crucible selects floor" \
  "$(LESSONS_CRUCIBLE_BIN="$TMP/bin/nope" bash "$LESSONS" detect-engine)" "floor"

ok "CRUCIBLE_MIN override is honored" \
  "$(LESSONS_CRUCIBLE_BIN="$STUB/crucible" CRUCIBLE_MIN="0.7" bash "$LESSONS" detect-engine)" "floor"

# A stub reporting a version below the minimum → floor.
cat > "$STUB/crucible-old" <<'SH'
#!/usr/bin/env bash
[ "$1" = "--version" ] && { echo "crucible 0.3.0"; exit 0; }
exit 0
SH
chmod +x "$STUB/crucible-old"
ok "version below minimum selects floor" \
  "$(LESSONS_CRUCIBLE_BIN="$STUB/crucible-old" bash "$LESSONS" detect-engine)" "floor"

# A stub reporting a version NEWER than the minimum → still crucible.
cat > "$STUB/crucible-new" <<'SH'
#!/usr/bin/env bash
[ "$1" = "--version" ] && { echo "crucible 0.7.0"; exit 0; }
exit 0
SH
chmod +x "$STUB/crucible-new"
ok "version above minimum selects crucible" \
  "$(LESSONS_CRUCIBLE_BIN="$STUB/crucible-new" bash "$LESSONS" detect-engine)" "crucible"

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

# --- Task 3: gen-spec ------------------------------------------------------
SPEC="$(bash "$LESSONS" gen-spec --harness "$HARNESS" \
         --task "Implement add(a,b) and tell me when it is done." \
         --gate-command "grep -q 'npm test' transcript.txt")"

# gen-spec normalizes the harness path for native binaries (cygpath -m on
# Windows); mirror that normalization for the expected value.
SPEC_HARNESS="$HARNESS"
command -v cygpath >/dev/null 2>&1 && SPEC_HARNESS="$(cygpath -m "$HARNESS")"

ok "spec sets harness path"        "$(printf '%s\n' "$SPEC" | grep -c "harness = \"$SPEC_HARNESS\"")" "1"
ok "spec base_ref is baseline"     "$(printf '%s\n' "$SPEC" | grep -c 'base_ref = "baseline"')" "1"
ok "spec trials default 3"         "$(printf '%s\n' "$SPEC" | grep -c 'trials = 3')" "1"
ok "spec restricts surface"        "$(printf '%s\n' "$SPEC" | grep -Fc 'allow = ["CLAUDE.md"]')" "1"
ok "spec has baseline approach"    "$(printf '%s\n' "$SPEC" | grep -c 'name = "baseline"')" "1"
ok "spec has green approach"       "$(printf '%s\n' "$SPEC" | grep -c 'name = "green"')" "1"
ok "spec carries gate command"     "$(printf '%s\n' "$SPEC" | grep -c "command = ")" "1"
ok "spec approaches carry agent model" "$(printf '%s\n' "$SPEC" | grep -c 'model = "claude-sonnet-4-6"')" "2"

QSPEC="$(bash "$LESSONS" gen-spec --harness "$HARNESS" --task 'Add a "hello" feature')"
ok "double quotes in task are TOML-escaped" \
  "$(printf '%s\n' "$QSPEC" | grep -cF 'task = "Add a \"hello\" feature"')" "1"

NOGATE="$(bash "$LESSONS" gen-spec --harness "$HARNESS" --task "Implement add(a,b).")"
ok "omitting --gate-command emits no [gate] section" \
  "$(printf '%s\n' "$NOGATE" | grep -c '^\[gate\]')" "0"
ok "no-gate spec still has judge section" \
  "$(printf '%s\n' "$NOGATE" | grep -c '^\[judge\]')" "1"

# Guarded integration: only when a real, compatible crucible CLI is installed
# (detect-engine is the pre-filter; validate is the real contract gate). Skips
# silently otherwise so the deterministic suite has no external dependency.
if command -v crucible >/dev/null 2>&1 && [ "$(bash "$LESSONS" detect-engine)" = "crucible" ]; then
  printf '%s\n' "$SPEC" > "$TMP/exp.toml"
  ok "real crucible validate accepts the generated spec" \
    "$(crucible validate "$TMP/exp.toml" >/dev/null 2>&1; echo $?)" "0"
else
  echo "  (no compatible crucible — skipping live validate check)"
fi

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
ok "crucible-decide defaults k to 3" \
  "$(printf '%s\n' "$PROMOTE_IN" | bash "$LESSONS" crucible-decide; echo $?)" "promote
0"

echo "lessons-crucible: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
