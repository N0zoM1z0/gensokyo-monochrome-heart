#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
RUNNER="res://tests/ui/screenshot_runner.gd"
DISPLAY_DRIVER="${GMH_DISPLAY_DRIVER:-x11}"

if [[ -z "${DISPLAY:-}" ]]; then
	echo "M12 screenshot capture requires an X display; run this script through xvfb-run in CI." >&2
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

capture_pair() {
	local name="$1"
	local scene="$2"
	local profile="$3"
	shift 3
	capture "${name}_en" "$scene" "$profile" en "$@"
	capture "${name}_ja" "$scene" "$profile" ja "$@"
}

capture_pair m12_time_grid_tutorial_a res://tests/ui/fixtures/TimeGridTutorialFixture.tscn A
capture_pair m12_time_grid_active_b res://tests/ui/fixtures/TimeGridActiveFixture.tscn B
capture_pair m12_time_grid_stopped_c res://tests/ui/fixtures/TimeGridStoppedFixture.tscn C --safe-flash
capture_pair m12_time_grid_paused_d res://tests/ui/fixtures/TimeGridPausedFixture.tscn D
capture_pair m12_time_grid_result_a res://tests/ui/fixtures/TimeGridResultFixture.tscn A
capture_pair m12_time_grid_loss_a res://tests/ui/fixtures/TimeGridLossFixture.tscn A
capture_pair m12_time_grid_assist_c res://tests/ui/fixtures/TimeGridAssistFixture.tscn C --reduced-motion --safe-flash
capture m12_time_grid_controller_b_ja res://tests/ui/fixtures/TimeGridActiveFixture.tscn B ja --input-device=controller
capture m12_time_grid_150_a_en res://tests/ui/fixtures/TimeGridActiveFixture.tscn A en --ui-scale=150
capture_pair m12_mansion_exploration_b res://tests/ui/fixtures/MansionServiceExplorationFixture.tscn B
capture_pair m12_mansion_kitchen_c res://tests/ui/fixtures/MansionServiceKitchenFixture.tscn C
capture_pair m12_knives_tutorial_a res://tests/ui/fixtures/MissingMinuteKnivesTutorialFixture.tscn A
capture_pair m12_knives_phase1_b res://tests/ui/fixtures/MissingMinuteKnivesPhase1Fixture.tscn B
capture_pair m12_knives_phase2_c res://tests/ui/fixtures/MissingMinuteKnivesPhase2Fixture.tscn C
capture_pair m12_knives_phase3_d res://tests/ui/fixtures/MissingMinuteKnivesPhase3Fixture.tscn D --safe-flash
capture_pair m12_knives_paused_a res://tests/ui/fixtures/MissingMinuteKnivesPausedFixture.tscn A
capture_pair m12_knives_result_a res://tests/ui/fixtures/MissingMinuteKnivesResultFixture.tscn A
capture_pair m12_knives_loss_d res://tests/ui/fixtures/MissingMinuteKnivesLossFixture.tscn D

"$GODOT_BIN" --headless --path . --script res://src/tools/validate_one_bit.gd -- \
	--path=res://tests/screenshots/generated
