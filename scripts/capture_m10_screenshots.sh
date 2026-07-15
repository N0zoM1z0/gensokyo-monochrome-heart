#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
RUNNER="res://tests/ui/screenshot_runner.gd"
DISPLAY_DRIVER="${GMH_DISPLAY_DRIVER:-x11}"

if [[ -z "${DISPLAY:-}" ]]; then
	echo "M10 screenshot capture requires an X display; run this script through xvfb-run in CI." >&2
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
	local scene="$2"
	local profile="$3"
	local locale="$4"
	shift 4
	"$GODOT_BIN" "${RENDER_ARGS[@]}" --path . --script "$RUNNER" -- \
		"--scene=$scene" \
		"--output=res://tests/screenshots/generated/${name}.png" \
		"--profile=$profile" \
		"--locale=$locale" \
		--ui-scale=150 \
		"$@"
}

capture m10_title_150_a_en res://ui/screens/title_screen.tscn A en
capture m10_title_page2_150_d_ja res://ui/screens/title_screen.tscn D ja --focus-id=title.quit
capture m10_options_150_a_en res://ui/screens/options_screen.tscn A en
capture m10_options_page2_150_d_ja res://ui/screens/options_screen.tscn D ja --focus-id=options.one_handed
capture m10_accessibility_150_a_ja res://ui/screens/accessibility_screen.tscn A ja
capture m10_profiles_150_d_ja res://ui/screens/profile_select.tscn D ja
capture m10_pause_150_a_ja res://ui/screens/pause_screen.tscn A ja
capture m10_credits_150_d_en res://ui/screens/credits_screen.tscn D en

"$GODOT_BIN" --headless --path . --script res://src/tools/validate_one_bit.gd -- \
	--path=res://tests/screenshots/generated
