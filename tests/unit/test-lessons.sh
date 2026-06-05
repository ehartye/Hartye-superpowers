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

# cluster: a correction in 1 session is NOT eligible; in 2 distinct sessions IS.
TMP2="$(mktemp -d)"; export LESSONS_HOME="$TMP2/.superpowers"
bash "$LESSONS" capture "Use absolute paths in the Bash tool" --session sA >/dev/null
bash "$LESSONS" capture "Use absolute paths in the Bash tool" --session sA >/dev/null   # same session, dedup
ok "single-session correction is not eligible" "$(bash "$LESSONS" cluster | grep -c .)" "0"
bash "$LESSONS" capture "Use absolute paths in the Bash tool" --session sB >/dev/null   # 2nd distinct session
CL="$(bash "$LESSONS" cluster)"
ok "two-session correction yields one eligible cluster" "$(printf '%s' "$CL" | grep -c .)" "1"
ok "cluster reports distinct_sessions=2" "$(printf '%s\n' "$CL" | awk -F'\t' '{print $2}')" "2"

echo "lessons: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
