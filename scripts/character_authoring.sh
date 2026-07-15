#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"

exec "$GODOT_BIN" --headless --path "$PROJECT_ROOT" \
	--script res://src/tools/character_authoring.gd -- "$@"
