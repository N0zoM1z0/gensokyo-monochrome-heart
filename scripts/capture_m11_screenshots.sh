#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
RUNNER="res://tests/ui/screenshot_runner.gd"
DISPLAY_DRIVER="${GMH_DISPLAY_DRIVER:-x11}"

if [[ -z "${DISPLAY:-}" ]]; then
	echo "M11 screenshot capture requires an X display; run this script through xvfb-run in CI." >&2
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

capture m11_bullet_lab_phase1_en res://tests/ui/fixtures/BulletPatternLabFixture.tscn en
capture m11_bullet_lab_phase1_ja res://tests/ui/fixtures/BulletPatternLabFixture.tscn ja
capture m11_bullet_lab_phase3_55_en res://tests/ui/fixtures/BulletPatternLabPhase3Fixture.tscn en
capture m11_bullet_lab_help_en res://tests/ui/fixtures/BulletPatternLabHelpFixture.tscn en

"$GODOT_BIN" --headless --path . --script res://src/tools/validate_one_bit.gd -- \
	--path=res://tests/screenshots/generated
