#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
RUNNER="res://tests/ui/screenshot_runner.gd"
DISPLAY_DRIVER="${GMH_DISPLAY_DRIVER:-x11}"

if [[ -z "${DISPLAY:-}" ]]; then
	echo "M08 screenshot capture requires an X display; run this script through xvfb-run in CI." >&2
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

capture m08_fighter_intro_a_en res://tests/ui/fixtures/CompactFighterIntroFixture.tscn A en
capture m08_fighter_active_a_ja res://tests/ui/fixtures/CompactFighterActiveFixture.tscn A ja
capture m08_fighter_active_d_en res://tests/ui/fixtures/CompactFighterActiveFixture.tscn D en
capture m08_fighter_hitboxes_a_en res://tests/ui/fixtures/CompactFighterHitboxFixture.tscn A en
capture m08_fighter_spell_break_d_ja res://tests/ui/fixtures/CompactFighterSpellBreakFixture.tscn D ja --safe-flash
capture m08_fighter_hit_a_en res://tests/ui/fixtures/CompactFighterHitFixture.tscn A en
capture m08_fighter_down_a_en res://tests/ui/fixtures/CompactFighterDownFixture.tscn A en --reduced-motion
capture m08_fighter_paused_a_ja res://tests/ui/fixtures/CompactFighterPausedFixture.tscn A ja
capture m08_fighter_training_a_en res://tests/ui/fixtures/CompactFighterTrainingFixture.tscn A en
capture m08_fighter_result_win_c_ja res://tests/ui/fixtures/CompactFighterResultWinFixture.tscn C ja
capture m08_fighter_result_loss_a_en res://tests/ui/fixtures/CompactFighterResultLossFixture.tscn A en
capture m08_fighter_stress_d_en res://tests/ui/fixtures/CompactFighterStressFixture.tscn D en

"$GODOT_BIN" --headless --path . --script res://src/tools/validate_one_bit.gd -- \
	--path=res://tests/screenshots/generated
