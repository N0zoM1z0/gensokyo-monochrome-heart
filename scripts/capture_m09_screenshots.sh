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

capture m09_invitation_a_en res://tests/ui/fixtures/VerticalSliceInvitationFixture.tscn A en
capture m09_map_c_ja res://tests/ui/fixtures/VerticalSliceMapFixture.tscn C ja
capture m09_exploration_b_en res://tests/ui/fixtures/VerticalSliceExplorationFixture.tscn B en --safe-flash
capture m09_dialogue_a_ja res://tests/ui/fixtures/VerticalSliceDialogueFixture.tscn A ja
capture m09_choice_forced_a_en res://tests/ui/fixtures/VerticalSliceChoiceFixture.tscn D en --forced-profile=A
capture m09_tea_c_ja res://tests/ui/fixtures/VerticalSliceTeaFixture.tscn C ja --reduced-motion --safe-flash
capture m09_danmaku_d_en res://tests/ui/fixtures/VerticalSliceDanmakuFixture.tscn D en --safe-flash
capture m09_fighter_a_ja res://tests/ui/fixtures/VerticalSliceFighterFixture.tscn A ja --reduced-motion --safe-flash
capture m09_afterbeat_a_en res://tests/ui/fixtures/VerticalSliceAfterbeatFixture.tscn A en
capture m09_reward_c_ja res://tests/ui/fixtures/VerticalSliceRewardFixture.tscn C ja
capture m09_day_end_d_en res://tests/ui/fixtures/VerticalSliceDayEndFixture.tscn D en
capture m09_journal_a_ja res://tests/ui/fixtures/VerticalSliceJournalFixture.tscn A ja
capture m09_replay_complete_b_en res://tests/ui/fixtures/VerticalSliceReplayCompleteFixture.tscn B en
capture m09_complete_d_ja res://tests/ui/fixtures/VerticalSliceCompleteFixture.tscn D ja
capture m09_credits_a_en res://ui/screens/credits_screen.tscn A en
capture m09_credits_a_ja res://ui/screens/credits_screen.tscn A ja
capture m09_exploration_controller_b_ja res://tests/ui/fixtures/VerticalSliceExplorationFixture.tscn B ja --input-device=controller
capture m09_fighter_left_hand_a_en res://tests/ui/fixtures/VerticalSliceFighterFixture.tscn A en --one-handed=left

"$GODOT_BIN" --headless --path . --script res://src/tools/validate_one_bit.gd -- \
	--path=res://tests/screenshots/generated
