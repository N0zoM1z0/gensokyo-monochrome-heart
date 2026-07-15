#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
RUNNER="res://tests/ui/screenshot_runner.gd"
DISPLAY_DRIVER="${GMH_DISPLAY_DRIVER:-x11}"

if [[ -z "${DISPLAY:-}" ]]; then
	echo "M07 screenshot capture requires an X display; run this script through xvfb-run in CI." >&2
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
		"$@"
}

capture m07_spell_intro_a_en res://tests/ui/fixtures/BoundaryStainSpellFixture.tscn A en
capture m07_phase1_100_d_en res://tests/ui/fixtures/BoundaryStainPhase1Fixture.tscn D en
capture m07_phase2_85_a_ja res://tests/ui/fixtures/BoundaryStainPhase2Fixture.tscn A ja
capture m07_focus_70_d_en res://tests/ui/fixtures/BoundaryStainFocusFixture.tscn D en
capture m07_bomb_100_a_ja res://tests/ui/fixtures/BoundaryStainBombFixture.tscn A ja --safe-flash
capture m07_phase3_55_d_ja res://tests/ui/fixtures/BoundaryStainPhase3Fixture.tscn D ja --reduced-motion --safe-flash
capture m07_paused_70_a_en res://tests/ui/fixtures/BoundaryStainPausedFixture.tscn A en
capture m07_result_55_d_ja res://tests/ui/fixtures/BoundaryStainResultFixture.tscn D ja
capture m07_loss_a_en res://tests/ui/fixtures/BoundaryStainLossFixture.tscn A en
capture m07_stress_2500_d_en res://tests/ui/fixtures/BoundaryStainStressFixture.tscn D en

"$GODOT_BIN" --headless --path . --script res://src/tools/validate_one_bit.gd -- \
	--path=res://tests/screenshots/generated
