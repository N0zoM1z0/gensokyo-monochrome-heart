#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

GODOT_BIN="${GODOT_BIN:-godot}"
EXPECTED_GODOT_VERSION="${GMH_EXPECTED_GODOT_VERSION:-4.7.1.stable.official.a13da4feb}"
LOG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/gmh-verify.XXXXXX")"
trap 'rm -rf "$LOG_DIR"' EXIT

fail() {
	echo "VERIFY FAILED: $*" >&2
	exit 1
}

run_checked() {
	local label="$1"
	shift
	local log="$LOG_DIR/${label// /_}.log"
	echo "==> $label"
	if ! "$@" >"$log" 2>&1; then
		cat "$log"
		fail "$label exited unsuccessfully"
	fi
	cat "$log"
	if grep -Eq 'SCRIPT ERROR:|^[[:space:]]*ERROR:' "$log"; then
		fail "$label emitted a Godot error despite returning success"
	fi
}

run_live_retry() {
	local label="$1"
	local attempts="$2"
	shift 2
	echo "==> $label"
	for attempt in $(seq 1 "$attempts"); do
		# Keep microbenchmark output live. Redirecting this tight CPU fixture to
		# the workspace filesystem introduces host I/O contention large enough to
		# dominate the provisional 3.5 ms budget on some desktop runners.
		if "$@"; then
			return 0
		fi
		if [[ "$attempt" -lt "$attempts" ]]; then
			echo "RETRY: $label attempt $attempt/$attempts was outside its provisional budget"
		fi
	done
	fail "$label exited unsuccessfully after $attempts attempts"
}

run_expected_failure() {
	local label="$1"
	local expected_text="$2"
	shift 2
	local log="$LOG_DIR/${label// /_}.log"
	echo "==> $label (expected failure)"
	if "$@" >"$log" 2>&1; then
		cat "$log"
		fail "$label unexpectedly succeeded"
	fi
	cat "$log"
	if ! grep -Fq "$expected_text" "$log"; then
		fail "$label omitted expected diagnostic: $expected_text"
	fi
}

command -v "$GODOT_BIN" >/dev/null 2>&1 || fail "Godot is unavailable; run scripts/install_godot.sh"
actual_version="$($GODOT_BIN --version)"
[[ "$actual_version" == "$EXPECTED_GODOT_VERSION" ]] || \
	fail "Godot version is $actual_version; expected $EXPECTED_GODOT_VERSION"
echo "Godot version: $actual_version"

run_checked "design package" python3 design/tools/validate_package.py
run_checked "content synchronization" python3 scripts/sync_design_content.py --check
run_checked "font synchronization" python3 scripts/sync_fonts.py --check
run_checked "Python syntax" python3 -m compileall -q scripts
run_checked "M12 architecture reuse scan" python3 scripts/validate_m12_architecture.py

# Measure the provisional CPU budget before the editor/import and authoring
# subprocesses heat or contend with the runner. Functional integration remains
# later in the suite; this isolated microbenchmark must measure the pool itself.
run_live_retry "M07 packed bullet stress" 2 "$GODOT_BIN" --headless --path . \
	--script res://tests/performance/run_m07_bullet_pool_stress.gd

git diff --check
git diff --cached --check

run_checked "Godot clean import" "$GODOT_BIN" --headless --editor --path . --quit
run_checked "content validation" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/validate_content.gd
run_checked "typed content validation" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/validate_typed_content.gd
run_checked "runtime content cache" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/build_content_cache.gd -- --check
run_checked "one-bit validation" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/validate_one_bit.gd
run_checked "pixel alignment" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/validate_pixel_alignment.gd -- \
	--scene=res://src/presentation/shell/Main.tscn \
	--scene=res://ui/screens/credits_screen.tscn \
	--scene=res://src/presentation/slice/VerticalSliceMode.tscn \
	--scene=res://tests/ui/fixtures/VerticalSliceInvitationFixture.tscn \
	--scene=res://tests/ui/fixtures/VerticalSliceMapFixture.tscn \
	--scene=res://tests/ui/fixtures/VerticalSliceExplorationFixture.tscn \
	--scene=res://tests/ui/fixtures/VerticalSliceDialogueFixture.tscn \
	--scene=res://tests/ui/fixtures/VerticalSliceChoiceFixture.tscn \
	--scene=res://tests/ui/fixtures/VerticalSliceTeaFixture.tscn \
	--scene=res://tests/ui/fixtures/VerticalSliceDanmakuFixture.tscn \
	--scene=res://tests/ui/fixtures/VerticalSliceFighterFixture.tscn \
	--scene=res://tests/ui/fixtures/VerticalSliceAfterbeatFixture.tscn \
	--scene=res://tests/ui/fixtures/VerticalSliceRewardFixture.tscn \
	--scene=res://tests/ui/fixtures/VerticalSliceDayEndFixture.tscn \
	--scene=res://tests/ui/fixtures/VerticalSliceJournalFixture.tscn \
	--scene=res://tests/ui/fixtures/VerticalSliceReplayCompleteFixture.tscn \
	--scene=res://tests/ui/fixtures/VerticalSliceCompleteFixture.tscn \
	--scene=res://tests/ui/fixtures/VisualFoundationFixture.tscn \
	--scene=res://tests/ui/fixtures/DialogueEventFixture.tscn \
	--scene=res://tests/ui/fixtures/DialogueChoiceFixture.tscn \
	--scene=res://tests/ui/fixtures/ReimuOfferingsLineFixture.tscn \
	--scene=res://tests/ui/fixtures/ReimuOfferingsChoiceFixture.tscn \
	--scene=res://tests/ui/fixtures/ReimuQuietLineFixture.tscn \
	--scene=res://tests/ui/fixtures/ReimuQuietChoiceFixture.tscn \
	--scene=res://tests/ui/fixtures/ReimuPromiseChoiceFixture.tscn \
	--scene=res://tests/ui/fixtures/BroomBackseatTutorialFixture.tscn \
	--scene=res://src/presentation/minigames/QuietChoreMode.tscn \
	--scene=res://tests/ui/fixtures/QuietChoreTutorialFixture.tscn \
	--scene=res://tests/ui/fixtures/QuietChoreSitFixture.tscn \
	--scene=res://tests/ui/fixtures/QuietChoreStoryPulseFixture.tscn \
	--scene=res://tests/ui/fixtures/QuietChoreResultFixture.tscn \
	--scene=res://src/presentation/exploration/ExplorationMode.tscn \
	--scene=res://tests/ui/fixtures/ExplorationFocusFixture.tscn \
	--scene=res://src/presentation/minigames/TeaTemperatureMode.tscn \
	--scene=res://tests/ui/fixtures/TeaTemperatureActiveFixture.tscn \
	--scene=res://tests/ui/fixtures/TeaTemperatureAssistFixture.tscn \
	--scene=res://tests/ui/fixtures/TeaTemperatureResultFixture.tscn \
	--scene=res://src/presentation/minigames/TimeGridServiceMode.tscn \
	--scene=res://tests/ui/fixtures/TimeGridTutorialFixture.tscn \
	--scene=res://tests/ui/fixtures/TimeGridActiveFixture.tscn \
	--scene=res://tests/ui/fixtures/TimeGridStoppedFixture.tscn \
	--scene=res://tests/ui/fixtures/TimeGridPausedFixture.tscn \
	--scene=res://tests/ui/fixtures/TimeGridResultFixture.tscn \
	--scene=res://tests/ui/fixtures/TimeGridLossFixture.tscn \
	--scene=res://tests/ui/fixtures/TimeGridAssistFixture.tscn \
	--scene=res://src/presentation/minigames/FiveImpossibleErrandsMode.tscn \
	--scene=res://tests/ui/fixtures/FiveErrandsTutorialFixture.tscn \
	--scene=res://tests/ui/fixtures/FiveErrandsActiveFixture.tscn \
	--scene=res://tests/ui/fixtures/FiveErrandsRefusalFixture.tscn \
	--scene=res://tests/ui/fixtures/FiveErrandsResultFixture.tscn \
	--scene=res://src/presentation/minigames/SoulGardenMode.tscn \
	--scene=res://tests/ui/fixtures/SoulGardenTutorialFixture.tscn \
	--scene=res://tests/ui/fixtures/SoulGardenActiveFixture.tscn \
	--scene=res://tests/ui/fixtures/SoulGardenCarriedFixture.tscn \
	--scene=res://tests/ui/fixtures/SoulGardenMismatchFixture.tscn \
	--scene=res://tests/ui/fixtures/SoulGardenResultFixture.tscn \
	--scene=res://src/presentation/exploration/MansionServiceExplorationMode.tscn \
	--scene=res://tests/ui/fixtures/MansionServiceExplorationFixture.tscn \
	--scene=res://tests/ui/fixtures/MansionServiceKitchenFixture.tscn \
	--scene=res://src/presentation/exploration/YoukaiMountainExplorationMode.tscn \
	--scene=res://tests/ui/fixtures/YoukaiMountainTrailFixture.tscn \
	--scene=res://tests/ui/fixtures/YoukaiMountainThresholdFixture.tscn \
	--scene=res://src/presentation/slice/ScarletDevilMansionSliceMode.tscn \
	--scene=res://src/presentation/slice/YoukaiMountainSliceMode.tscn \
	--scene=res://tests/ui/fixtures/MountainSliceFixtureBase.tscn \
	--scene=res://tests/ui/fixtures/MountainSliceInvitationFixture.tscn \
	--scene=res://tests/ui/fixtures/MountainSliceChoiceFixture.tscn \
	--scene=res://tests/ui/fixtures/MountainSlicePatrolFixture.tscn \
	--scene=res://tests/ui/fixtures/MountainSliceCameraLoweredFixture.tscn \
	--scene=res://tests/ui/fixtures/MountainSliceRewardFixture.tscn \
	--scene=res://tests/ui/fixtures/MountainSliceJournalFixture.tscn \
	--scene=res://tests/ui/fixtures/MansionSliceFixtureBase.tscn \
	--scene=res://tests/ui/fixtures/MansionSliceInvitationFixture.tscn \
	--scene=res://tests/ui/fixtures/MansionSliceChoiceFixture.tscn \
	--scene=res://tests/ui/fixtures/MansionSliceAfterbeatFixture.tscn \
	--scene=res://tests/ui/fixtures/MansionSliceLibraryFixture.tscn \
	--scene=res://tests/ui/fixtures/MansionSliceRemiliaPublicFixture.tscn \
	--scene=res://tests/ui/fixtures/MansionSliceRemiliaPrivateFixture.tscn \
	--scene=res://tests/ui/fixtures/MansionSliceRewardFixture.tscn \
	--scene=res://tests/ui/fixtures/MansionSliceJournalFixture.tscn \
	--scene=res://src/presentation/danmaku/MissingMinuteKnivesMode.tscn \
	--scene=res://tests/ui/fixtures/MissingMinuteKnivesTutorialFixture.tscn \
	--scene=res://tests/ui/fixtures/MissingMinuteKnivesPhase1Fixture.tscn \
	--scene=res://tests/ui/fixtures/MissingMinuteKnivesPhase2Fixture.tscn \
	--scene=res://tests/ui/fixtures/MissingMinuteKnivesPhase3Fixture.tscn \
	--scene=res://tests/ui/fixtures/MissingMinuteKnivesPausedFixture.tscn \
	--scene=res://tests/ui/fixtures/MissingMinuteKnivesResultFixture.tscn \
	--scene=res://tests/ui/fixtures/MissingMinuteKnivesLossFixture.tscn \
	--scene=res://src/presentation/danmaku/BoundaryStainMode.tscn \
	--scene=res://tests/ui/fixtures/BoundaryStainSpellFixture.tscn \
	--scene=res://tests/ui/fixtures/BoundaryStainPhase1Fixture.tscn \
	--scene=res://tests/ui/fixtures/BoundaryStainFocusFixture.tscn \
	--scene=res://tests/ui/fixtures/BoundaryStainBombFixture.tscn \
	--scene=res://tests/ui/fixtures/BoundaryStainPhase2Fixture.tscn \
	--scene=res://tests/ui/fixtures/BoundaryStainPhase3Fixture.tscn \
	--scene=res://tests/ui/fixtures/BoundaryStainPausedFixture.tscn \
	--scene=res://tests/ui/fixtures/BoundaryStainResultFixture.tscn \
	--scene=res://tests/ui/fixtures/BoundaryStainLossFixture.tscn \
	--scene=res://tests/ui/fixtures/BoundaryStainAssistClearFixture.tscn \
	--scene=res://tests/ui/fixtures/BoundaryStainStressFixture.tscn \
	--scene=res://src/presentation/danmaku/TomorrowsHeadlineMode.tscn \
	--scene=res://tests/ui/fixtures/TomorrowsHeadlineTutorialFixture.tscn \
	--scene=res://tests/ui/fixtures/TomorrowsHeadlineActiveFixture.tscn \
	--scene=res://tests/ui/fixtures/TomorrowsHeadlineCaptureFixture.tscn \
	--scene=res://src/presentation/fighter/CompactFighterMode.tscn \
	--scene=res://tests/ui/fixtures/CompactFighterIntroFixture.tscn \
	--scene=res://tests/ui/fixtures/CompactFighterActiveFixture.tscn \
	--scene=res://tests/ui/fixtures/CompactFighterHitboxFixture.tscn \
	--scene=res://tests/ui/fixtures/CompactFighterSpellBreakFixture.tscn \
	--scene=res://tests/ui/fixtures/CompactFighterDownFixture.tscn \
	--scene=res://tests/ui/fixtures/CompactFighterPausedFixture.tscn \
	--scene=res://tests/ui/fixtures/CompactFighterTrainingFixture.tscn \
	--scene=res://tests/ui/fixtures/CompactFighterResultWinFixture.tscn \
	--scene=res://tests/ui/fixtures/CompactFighterResultLossFixture.tscn \
	--scene=res://tests/ui/fixtures/CompactFighterStressFixture.tscn \
	--scene=res://src/presentation/tools/BulletPatternLab.tscn \
	--scene=res://tests/ui/fixtures/BulletPatternLabFixture.tscn \
	--scene=res://tests/ui/fixtures/BulletPatternLabPhase3Fixture.tscn \
	--scene=res://tests/ui/fixtures/BulletPatternLabHelpFixture.tscn
run_checked "release validation" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/validate_release.gd -- --release
run_checked "headless tests" "$GODOT_BIN" --headless --path . \
	--script res://tests/run_all.gd
run_checked "M11 event authoring duplicate" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/author_event.gd -- \
	--action=duplicate --event-id=evt.hkr.verification_fixture --output="$LOG_DIR/m11-authoring"
run_checked "M11 event authoring validation" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/author_event.gd -- \
	--action=validate --bundle="$LOG_DIR/m11-authoring"
run_checked "M11 English event preview" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/author_event.gd -- \
	--action=preview --bundle="$LOG_DIR/m11-authoring" --locale=en \
	--output="$LOG_DIR/m11-authoring/preview-en.md"
run_checked "M11 Japanese event preview" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/author_event.gd -- \
	--action=preview --bundle="$LOG_DIR/m11-authoring" --locale=ja \
	--output="$LOG_DIR/m11-authoring/preview-ja.md"
run_checked "M11 character skills catalog" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/character_authoring.gd -- --action=list
run_checked "M11 Reimu skills browser" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/character_authoring.gd -- \
	--action=show --character-id=char.reimu_hakurei
run_checked "M11 valid character-agent output" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/character_authoring.gd -- \
	--action=validate-output --character-id=char.reimu_hakurei \
	--input=res://tests/fixtures/authoring/valid_reimu_agent_output.json
run_expected_failure "M11 multi-facet agent output" "at most one state facet may change" \
	"$GODOT_BIN" --headless --path . --script res://src/tools/character_authoring.gd -- \
	--action=validate-output --character-id=char.reimu_hakurei \
	--input=res://tests/fixtures/invalid/authoring/multiple_agent_state_changes.json
run_expected_failure "M11 schema-invalid agent output" "missing required property spoken_line_ja" \
	"$GODOT_BIN" --headless --path . --script res://src/tools/character_authoring.gd -- \
	--action=validate-output --character-id=char.reimu_hakurei \
	--input=res://tests/fixtures/invalid/authoring/missing_agent_japanese.json
run_checked "M11 debug workbench registry" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/authoring_workbench.gd -- --action=list
run_checked "M11 save migration workbench" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/authoring_workbench.gd -- \
	--action=inspect --target=save.v1_route_affinity
run_checked "M11 legal test-tone audition" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/authoring_workbench.gd -- \
	--action=smoke --target=tone.shrine_day
for workbench_target in scene.tea.active scene.danmaku.phase1 scene.fighter.hitbox; do
	run_checked "M11 fixture smoke ${workbench_target}" "$GODOT_BIN" --headless --path . \
		--script res://src/tools/authoring_workbench.gd -- \
		--action=smoke --target="$workbench_target"
done
run_checked "M11 registered screenshot delegation" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/authoring_workbench.gd -- \
	--action=screenshot --target=scene.fighter.hitbox \
	--output="$LOG_DIR/m11-fighter-hitbox.png" --profile=A --locale=en --ui-scale=100
run_checked "M11 Bullet Pattern Lab draft" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/bullet_pattern_lab.gd -- \
	--action=duplicate --pattern-id=danmaku.lab.verification_fixture \
	--output="$LOG_DIR/m11-bullet-pattern.json"
run_checked "M11 Bullet Pattern Lab report" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/bullet_pattern_lab.gd -- \
	--action=report --input="$LOG_DIR/m11-bullet-pattern.json"
run_checked "M11 Bullet Pattern Lab simulation" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/bullet_pattern_lab.gd -- \
	--action=smoke --input="$LOG_DIR/m11-bullet-pattern.json" --density=85 --speed=70
run_checked "M11 event dependency report" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/author_event.gd -- \
	--action=dependencies --bundle="$LOG_DIR/m11-authoring" \
	--output="$LOG_DIR/m11-authoring/dependencies.md"
for locale in en ja; do
	for ui_scale in 100 150; do
		run_checked "M11 ${locale} width report at ${ui_scale} percent" \
			"$GODOT_BIN" --headless --path . --script res://src/tools/author_event.gd -- \
			--action=width-report --bundle="$LOG_DIR/m11-authoring" \
			--locale="$locale" --ui-scale="$ui_scale" \
			--output="$LOG_DIR/m11-authoring/width-${locale}-${ui_scale}.md"
	done
done
run_checked "M03 generated state inspector" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/inspect_state.gd -- --profile=p01
run_checked "M03 migration fixture inspector" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/inspect_state.gd -- \
	--fixture=res://tests/fixtures/saves/v1_route_affinity_payload.json
run_checked "M01 navigation integration" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m01_flow.gd
run_checked "M04 dialogue integration" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m04_dialogue_flow.gd
run_checked "M05 exploration integration" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m05_exploration_flow.gd
run_checked "M06 tea event integration" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m06_tea_event_flow.gd
run_checked "M07 Boundary Stain event integration" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m07_boundary_stain_event_flow.gd
run_checked "M08 fighter event integration" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m08_fighter_event_flow.gd
run_checked "M09 vertical slice integration" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m09_vertical_slice_flow.gd
run_checked "M09 save and resume matrix" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m09_save_resume_matrix.gd
run_checked "M09 accessibility route matrix" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m09_accessibility_matrix.gd
run_checked "M09 stability matrix" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m09_stability_matrix.gd
run_checked "M12 SDM vertical slice integration" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m12_sdm_vertical_slice_flow.gd
run_checked "M12 SDM save and resume matrix" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m12_sdm_save_resume_matrix.gd
run_checked "M12 SDM accessibility matrix" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m12_sdm_accessibility_matrix.gd
run_checked "M13 Youkai Mountain exploration integration" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m13_mountain_exploration_flow.gd
run_checked "M13 Eientei bamboo loop integration" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m13_bamboo_loop_flow.gd
run_checked "M13 Five Impossible Errands integration" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m13_five_impossible_errands.gd
run_checked "M13 Soul Garden integration" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m13_soul_garden.gd
run_checked "M13 five-region campaign backbone" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m13_campaign_backbone.gd
run_checked "M13 Tomorrow's Headline event integration" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m13_tomorrows_headline_event_flow.gd
run_checked "M13 Youkai Mountain vertical slice integration" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m13_mountain_vertical_slice_flow.gd
run_checked "M13 Youkai Mountain save and resume matrix" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m13_mountain_save_resume_matrix.gd
run_checked "M13 recorded-strategy Archive prototype" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m13_archive_prototype.gd
run_checked "M14 Reimu Offerings Without Owners event" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m14_reimu_offerings_event.gd
run_checked "M14 Reimu The Day Nothing Happens event" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m14_reimu_quiet_day_event.gd
run_checked "M14 Reimu route progression persistence" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m14_reimu_route_progression.gd
run_checked "M14 Reimu guesthouse boundary event" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m14_reimu_guesthouse_event.gd
run_checked "M14 Reimu unasked rescue event" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m14_reimu_unasked_rescue_event.gd
run_checked "M14 Reimu perfectly recorded tea event" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m14_reimu_recorded_tea_event.gd
run_checked "M14 Reimu Promise finale" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m14_reimu_promise_event.gd
run_checked "M14 Marisa Crash Landing event" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m14_marisa_crash_landing.gd
run_checked "M14 Marisa Field Notes event" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m14_marisa_field_notes.gd
run_checked "M14 Marisa shelf boundary event" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m14_marisa_shelf_event.gd
run_checked "M14 Marisa talent conflict event" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m14_marisa_talent_event.gd
run_checked "M14 Marisa weather rescue event" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m14_marisa_rescue_event.gd
run_checked "M14 Marisa infinite experiment event" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m14_marisa_infinite_experiment.gd
run_checked "M14 Marisa Promise finale" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m14_marisa_promise_event.gd
run_checked "M14 Sakuya corridor event" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m14_sakuya_corridor_event.gd
run_checked "M14 Sakuya kitchen event" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m14_sakuya_kitchen_event.gd
run_checked "M14 Sakuya competence boundary event" env XDG_DATA_HOME="$LOG_DIR/user-data" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m14_sakuya_competence_event.gd
run_checked "runtime smoke" "$GODOT_BIN" --headless --path . --quit-after 60

run_expected_failure "duplicate ID fixture" "duplicate stable ID" \
	"$GODOT_BIN" --headless --path . --script res://src/tools/validate_content.gd -- \
	--fixture-duplicate-ids
run_expected_failure "typed invalid ID fixture" "invalid stable ID format" \
	"$GODOT_BIN" --headless --path . --script res://src/tools/validate_typed_content.gd -- \
	--fixture-invalid-id
run_expected_failure "typed duplicate ID fixture" "duplicate stable ID" \
	"$GODOT_BIN" --headless --path . --script res://src/tools/validate_typed_content.gd -- \
	--fixture-duplicate-id
run_expected_failure "missing event reference fixture" "unknown location reference" \
	"$GODOT_BIN" --headless --path . --script res://src/tools/validate_typed_content.gd -- \
	--fixture-missing-event-reference
run_expected_failure "missing localization reference fixture" "unknown localization reference" \
	"$GODOT_BIN" --headless --path . --script res://src/tools/validate_typed_content.gd -- \
	--fixture-missing-localization-reference
run_expected_failure "missing typed source fixture" "file is missing" \
	"$GODOT_BIN" --headless --path . --script res://src/tools/validate_typed_content.gd -- \
	--fixture-missing-file
run_expected_failure "M02 invalid startup gate" "Title route blocked by invalid ContentDB before presentation." \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m02_invalid_boot.gd
run_expected_failure "M04 unbounded event cycle" "unbounded event cycle" \
	"$GODOT_BIN" --headless --path . --script res://tests/integration/run_m04_invalid_cycle.gd
run_expected_failure "gray pixel fixture" "got #808080" \
	"$GODOT_BIN" --headless --path . --script res://src/tools/validate_one_bit.gd -- \
	--fixture-gray
run_expected_failure "fractional position fixture" "got (10.500,12.000)" \
	"$GODOT_BIN" --headless --path . --script res://src/tools/validate_pixel_alignment.gd -- \
	--fixture-fractional
run_expected_failure "placeholder fixture" "placeholder filename is forbidden" \
	"$GODOT_BIN" --headless --path . --script res://src/tools/validate_release.gd -- \
	--fixture-placeholder

if [[ "${GMH_SKIP_SCREENSHOTS:-0}" == "1" ]]; then
	echo "==> screenshot matrix explicitly skipped with GMH_SKIP_SCREENSHOTS=1"
else
	run_checked "VA00 screenshot matrix" ./scripts/capture_va00_screenshots.sh
	run_checked "M01 screenshot matrix" ./scripts/capture_m01_screenshots.sh
	run_checked "M04 screenshot matrix" ./scripts/capture_m04_screenshots.sh
	run_checked "M05 screenshot matrix" ./scripts/capture_m05_screenshots.sh
	run_checked "M06 screenshot matrix" ./scripts/capture_m06_screenshots.sh
	run_checked "M07 screenshot matrix" ./scripts/capture_m07_screenshots.sh
	run_checked "M08 screenshot matrix" ./scripts/capture_m08_screenshots.sh
	run_checked "M09 screenshot matrix" ./scripts/capture_m09_screenshots.sh
	run_checked "M10 150 percent UI screenshot matrix" ./scripts/capture_m10_screenshots.sh
	run_checked "M11 authoring screenshot matrix" ./scripts/capture_m11_screenshots.sh
	run_checked "M12 Scarlet Devil Mansion screenshot matrix" ./scripts/capture_m12_screenshots.sh
	run_checked "M13 Wind-Frame, mountain, and Archive screenshot matrix" ./scripts/capture_m13_screenshots.sh
	run_checked "M14 Reimu route screenshot matrix" ./scripts/capture_m14_screenshots.sh
	run_checked "M07 rendered bullet stress" "$GODOT_BIN" \
		--display-driver "${GMH_DISPLAY_DRIVER:-x11}" \
		--rendering-driver opengl3 \
		--audio-driver Dummy \
		--disable-vsync \
		--path . \
		--script res://tests/performance/run_m07_render_stress.gd
	run_checked "M08 rendered fighter stress" "$GODOT_BIN" \
		--display-driver "${GMH_DISPLAY_DRIVER:-x11}" \
		--rendering-driver opengl3 \
		--audio-driver Dummy \
		--disable-vsync \
		--path . \
		--script res://tests/performance/run_m08_fighter_render_stress.gd
fi

echo "Foundation verification passed."
