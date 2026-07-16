#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
RUNNER="res://tests/ui/screenshot_runner.gd"
DISPLAY_DRIVER="${GMH_DISPLAY_DRIVER:-x11}"

if [[ -z "${DISPLAY:-}" ]]; then
	echo "M13 screenshot capture requires an X display; run this script through xvfb-run in CI." >&2
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

capture_pair m13_photo_tutorial res://tests/ui/fixtures/TomorrowsHeadlineTutorialFixture.tscn
capture_pair m13_photo_active res://tests/ui/fixtures/TomorrowsHeadlineActiveFixture.tscn
capture_pair m13_photo_capture res://tests/ui/fixtures/TomorrowsHeadlineCaptureFixture.tscn
capture_pair m13_mountain_trail res://tests/ui/fixtures/YoukaiMountainTrailFixture.tscn
capture_pair m13_mountain_threshold res://tests/ui/fixtures/YoukaiMountainThresholdFixture.tscn
capture_pair m13_mountain_slice_invitation res://tests/ui/fixtures/MountainSliceInvitationFixture.tscn
capture_pair m13_mountain_slice_choice res://tests/ui/fixtures/MountainSliceChoiceFixture.tscn
capture_pair m13_mountain_slice_patrol res://tests/ui/fixtures/MountainSlicePatrolFixture.tscn
capture_pair m13_mountain_slice_camera_lowered res://tests/ui/fixtures/MountainSliceCameraLoweredFixture.tscn
capture_pair m13_mountain_slice_reward res://tests/ui/fixtures/MountainSliceRewardFixture.tscn
capture_pair m13_mountain_slice_journal res://tests/ui/fixtures/MountainSliceJournalFixture.tscn
capture_pair m13_archive_tutorial res://tests/ui/fixtures/ArchiveTutorialFixture.tscn
capture_pair m13_archive_familiar res://tests/ui/fixtures/ArchiveFamiliarFixture.tscn
capture_pair m13_archive_removal res://tests/ui/fixtures/ArchiveRemovalFixture.tscn

"$GODOT_BIN" --headless --path . --script res://src/tools/validate_one_bit.gd -- \
	--path=res://tests/screenshots/generated
