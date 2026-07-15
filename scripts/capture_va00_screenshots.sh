#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
RUNNER="res://tests/ui/screenshot_runner.gd"
DISPLAY_DRIVER="${GMH_DISPLAY_DRIVER:-x11}"

if [[ -z "${DISPLAY:-}" ]]; then
	echo "VA00 screenshot capture requires an X display; run this script through xvfb-run in CI." >&2
	exit 2
fi

RENDER_ARGS=(
	--display-driver "$DISPLAY_DRIVER"
	--rendering-driver opengl3
	--audio-driver Dummy
	--disable-vsync
)

capture() {
	local name="$1"
	shift
	"$GODOT_BIN" "${RENDER_ARGS[@]}" --path . --script "$RUNNER" -- \
		"--output=res://tests/screenshots/generated/${name}.png" "$@"
}

capture profile_a_en --profile=A --locale=en
capture profile_a_ja --profile=A --locale=ja
capture profile_b_en --profile=B --locale=en
capture profile_c_ja --profile=C --locale=ja
capture profile_d_en --profile=D --locale=en
capture profile_d_ja --profile=D --locale=ja
capture forced_a_ja --profile=D --forced-profile=A --locale=ja
capture accessible_a_en --profile=A --locale=en --reduced-motion --safe-flash

"$GODOT_BIN" --headless --path . --script res://src/tools/validate_one_bit.gd -- \
	--path=res://tests/screenshots/generated
