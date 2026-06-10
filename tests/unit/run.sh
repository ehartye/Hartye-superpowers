#!/usr/bin/env bash
# Runs all deterministic unit tests in tests/unit/ (no tokens, no required
# external CLIs — guarded checks may use an optional CLI when installed).
# Each test-*.sh is self-contained and exits non-zero on failure.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
fail=0
for t in "$DIR"/test-*.sh; do
  [ -e "$t" ] || continue
  echo "--- $(basename "$t") ---"
  if bash "$t"; then :; else fail=1; fi
done
exit "$fail"
