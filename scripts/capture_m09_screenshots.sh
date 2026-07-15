#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
RUNNER="res://tests/ui/screenshot_runner.gd"
DISPLAY_DRIVER="${GMH_DISPLAY_DRIVER:-x11}"

if [[ -z "${DISPLAY:-}" ]]; then
	echo "M09 screenshot capture requires an X display; run this script through xvfb-run in CI." >&2
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

capture_pair m09_invitation_a res://tests/ui/fixtures/VerticalSliceInvitationFixture.tscn A
capture_pair m09_map_c res://tests/ui/fixtures/VerticalSliceMapFixture.tscn C
capture_pair m09_exploration_b res://tests/ui/fixtures/VerticalSliceExplorationFixture.tscn B --safe-flash
capture_pair m09_dialogue_a res://tests/ui/fixtures/VerticalSliceDialogueFixture.tscn A
capture_pair m09_choice_forced_a res://tests/ui/fixtures/VerticalSliceChoiceFixture.tscn D --forced-profile=A
capture_pair m09_tea_c res://tests/ui/fixtures/VerticalSliceTeaFixture.tscn C --reduced-motion --safe-flash
capture_pair m09_danmaku_d res://tests/ui/fixtures/VerticalSliceDanmakuFixture.tscn D --safe-flash
capture_pair m09_fighter_a res://tests/ui/fixtures/VerticalSliceFighterFixture.tscn A --reduced-motion --safe-flash
capture_pair m09_afterbeat_a res://tests/ui/fixtures/VerticalSliceAfterbeatFixture.tscn A
capture_pair m09_reward_c res://tests/ui/fixtures/VerticalSliceRewardFixture.tscn C
capture_pair m09_day_end_d res://tests/ui/fixtures/VerticalSliceDayEndFixture.tscn D
capture_pair m09_journal_a res://tests/ui/fixtures/VerticalSliceJournalFixture.tscn A
capture_pair m09_replay_complete_b res://tests/ui/fixtures/VerticalSliceReplayCompleteFixture.tscn B
capture_pair m09_complete_d res://tests/ui/fixtures/VerticalSliceCompleteFixture.tscn D
capture_pair m09_credits_a res://ui/screens/credits_screen.tscn A
capture m09_exploration_controller_b_ja res://tests/ui/fixtures/VerticalSliceExplorationFixture.tscn B ja --input-device=controller
capture m09_fighter_left_hand_a_en res://tests/ui/fixtures/VerticalSliceFighterFixture.tscn A en --one-handed=left

"$GODOT_BIN" --headless --path . --script res://src/tools/validate_one_bit.gd -- \
	--path=res://tests/screenshots/generated
