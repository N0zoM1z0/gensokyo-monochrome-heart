#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
RUNNER="res://tests/ui/screenshot_runner.gd"
DISPLAY_DRIVER="${GMH_DISPLAY_DRIVER:-x11}"

if [[ -z "${DISPLAY:-}" ]]; then
	echo "M14 screenshot capture requires an X display; run this script through xvfb-run in CI." >&2
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
	local locale="$3"
	"$GODOT_BIN" "${RENDER_ARGS[@]}" --path . --script "$RUNNER" -- \
		"--scene=$scene" \
		"--output=res://tests/screenshots/generated/${name}.png" \
		--profile=A \
		"--locale=$locale"
}

capture_pair() {
	local name="$1"
	local scene="$2"
	capture "${name}_en" "$scene" en
	capture "${name}_ja" "$scene" ja
}

capture_pair m14_reimu_offerings_line res://tests/ui/fixtures/ReimuOfferingsLineFixture.tscn
capture_pair m14_reimu_offerings_choice res://tests/ui/fixtures/ReimuOfferingsChoiceFixture.tscn
capture_pair m14_reimu_quiet_line res://tests/ui/fixtures/ReimuQuietLineFixture.tscn
capture_pair m14_reimu_quiet_choice res://tests/ui/fixtures/ReimuQuietChoiceFixture.tscn
capture_pair m14_reimu_quiet_tutorial res://tests/ui/fixtures/QuietChoreTutorialFixture.tscn
capture_pair m14_reimu_quiet_sit res://tests/ui/fixtures/QuietChoreSitFixture.tscn
capture_pair m14_reimu_quiet_story_pulse res://tests/ui/fixtures/QuietChoreStoryPulseFixture.tscn
capture_pair m14_reimu_quiet_result res://tests/ui/fixtures/QuietChoreResultFixture.tscn

"$GODOT_BIN" --headless --path . --script res://src/tools/validate_one_bit.gd -- \
	--path=res://tests/screenshots/generated
