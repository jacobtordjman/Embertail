#!/bin/sh
set -eu
GAME_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -n "${GODOT_BIN:-}" ]; then
    GAME_GODOT=$GODOT_BIN
elif command -v godot >/dev/null 2>&1; then
    GAME_GODOT=$(command -v godot)
elif command -v godot4 >/dev/null 2>&1; then
    GAME_GODOT=$(command -v godot4)
elif [ -x /Applications/Godot.app/Contents/MacOS/Godot ]; then
    GAME_GODOT=/Applications/Godot.app/Contents/MacOS/Godot
elif [ -x /opt/homebrew/bin/godot ]; then
    GAME_GODOT=/opt/homebrew/bin/godot
else
    printf '%s\n' 'Godot 4 is required. Import project.godot in the Godot editor, or set GODOT_BIN.' >&2
    exit 127
fi
# Fresh checkouts need their generated PNG/WAV resources imported first.
"$GAME_GODOT" --headless --path "$GAME_DIR" --editor --import --quit
exec "$GAME_GODOT" --path "$GAME_DIR" "$@"
