#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
DISPLAY_ARGS=(--headless)

for argument in "$@"; do
	if [[ "$argument" == "--action=launch" ]]; then
		DISPLAY_ARGS=(--display-driver x11 --rendering-driver opengl3 --audio-driver Pulse)
	fi
done

exec "$GODOT_BIN" "${DISPLAY_ARGS[@]}" --path "$PROJECT_ROOT" \
	--script res://src/tools/authoring_workbench.gd -- "$@"
