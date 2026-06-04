#!/usr/bin/env bash
# Unit tests for the drift script. Self-contained: builds a scratch git repo.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DRIFT="$REPO_ROOT/skills/time-machine-check/scripts/drift"
PASS=0; FAIL=0
assert_eq() { # $1=actual $2=expected $3=label
  if [ "$1" = "$2" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $3 — got '$1' want '$2'"; fi
}
field() { echo "$1" | grep -oE "$2=[^ ]+" | cut -d= -f2; } # extract key=value from a reading line

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

# Bad/nonexistent baseline must fail loudly, not report a false on-track reading
out_rc=0; bash "$DRIFT" measure deadbeefdeadbeef >/dev/null 2>&1 || out_rc=$?
assert_eq "$([ "$out_rc" -ne 0 ] && echo nonzero || echo zero)" "nonzero" "measure: bad sha fails loudly"

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

echo "drift: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
