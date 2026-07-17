#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
RUNNER="res://tests/ui/screenshot_runner.gd"
DISPLAY_DRIVER="${GMH_DISPLAY_DRIVER:-x11}"

if [[ -z "${DISPLAY:-}" ]]; then
	echo "M15 screenshot capture requires an X display; run this script through xvfb-run in CI." >&2
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
	local scale="${4:-100}"
	"$GODOT_BIN" "${RENDER_ARGS[@]}" --path . --script "$RUNNER" -- \
		"--scene=$scene" \
		"--output=res://tests/screenshots/generated/${name}.png" \
		--profile=A \
		"--locale=$locale" \
		"--ui-scale=$scale"
}

capture m15_postgame_dream_en res://tests/ui/fixtures/PostgameHubDreamFixture.tscn en
capture m15_postgame_dream_ja res://tests/ui/fixtures/PostgameHubDreamFixture.tscn ja
capture m15_postgame_seasonal_en res://tests/ui/fixtures/PostgameHubSeasonalFixture.tscn en
capture m15_postgame_seasonal_ja res://tests/ui/fixtures/PostgameHubSeasonalFixture.tscn ja
capture m15_postgame_accord_en res://tests/ui/fixtures/PostgameHubAccordFixture.tscn en
capture m15_postgame_accord_ja res://tests/ui/fixtures/PostgameHubAccordFixture.tscn ja
capture m15_postgame_dream_125_en res://tests/ui/fixtures/PostgameHubDreamFixture.tscn en 125
capture m15_postgame_accord_125_en res://tests/ui/fixtures/PostgameHubAccordFixture.tscn en 125

"$GODOT_BIN" --headless --path . --script res://src/tools/validate_one_bit.gd -- \
	--path=res://tests/screenshots/generated
