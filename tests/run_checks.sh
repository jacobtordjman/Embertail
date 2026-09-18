#!/bin/sh
# Run from any directory; GODOT_BIN can select a specific Godot 4 executable.
set -eu
PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [ -n "${GODOT_BIN:-}" ]; then
    GODOT=$GODOT_BIN
elif command -v godot >/dev/null 2>&1; then
    GODOT=$(command -v godot)
elif command -v godot4 >/dev/null 2>&1; then
    GODOT=$(command -v godot4)
elif [ -x /Applications/Godot.app/Contents/MacOS/Godot ]; then
    GODOT=/Applications/Godot.app/Contents/MacOS/Godot
else
    printf '%s\n' 'Godot 4 is required. Set GODOT_BIN to its executable.' >&2
    exit 127
fi
mkdir -p "$PROJECT_DIR/tests/results"
run_check() {
    label=$1
    shift
    logfile="$PROJECT_DIR/tests/results/$label.log"
    status=0
    "$GODOT" --headless --path "$PROJECT_DIR" --log-file "$PROJECT_DIR/tests/results/$label.engine.log" "$@" > "$logfile" 2>&1 || status=$?
    cat "$logfile"
    if [ "$status" -ne 0 ]; then
        return "$status"
    fi
    # Godot can emit script errors and still return zero, so inspect its log too.
    if command -v rg >/dev/null 2>&1; then
        if rg -q 'SCRIPT ERROR:|ERROR:' "$logfile"; then return 1; fi
    elif grep -Eq 'SCRIPT ERROR:|ERROR:' "$logfile"; then
        return 1
    fi
}
run_check import --editor --import --quit
run_check integration --fixed-fps 60 --script res://tests/integration.gd
run_check traversal --fixed-fps 60 --script res://tests/traversal.gd
run_check character --fixed-fps 60 --script res://tests/character.gd
