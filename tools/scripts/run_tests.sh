#!/bin/zsh
# Run all headless logic tests for APHELION.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT="$ROOT/tools/godot/godot"
FAIL=0
for t in test_campaign test_loop test_combat test_menu test_visual; do
  echo "=== $t ==="
  "$GODOT" --headless --path "$ROOT/game" --script "res://tests/$t.gd" || FAIL=1
done
if [ "$FAIL" -ne 0 ]; then
  echo "TESTS FAILED"
  exit 1
fi
echo "ALL TESTS PASSED"
