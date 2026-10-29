#!/bin/sh
set -eu
cd "$(dirname "$0")"
: "${GODOT:?Set GODOT to the Godot 4.5.2 executable path}"
test_log=$(mktemp)
trap 'rm -f "$test_log"' EXIT HUP INT TERM
for suite in smoke_test.gd tests/input_smoke.gd; do
  if ! "$GODOT" --headless --path . --script "$suite" --quit-after 600 > "$test_log" 2>&1; then
    cat "$test_log"
    exit 1
  fi
  cat "$test_log"
  # Godot can otherwise exit successfully after a script error or the frame watchdog.
  case "$(cat "$test_log")" in
    *"PASS:"*) ;;
    *) echo "Suite did not report completion: $suite" >&2; exit 1 ;;
  esac
done
