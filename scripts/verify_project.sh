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
	--scene=res://tests/ui/fixtures/VisualFoundationFixture.tscn \
	--scene=res://tests/ui/fixtures/DialogueEventFixture.tscn \
	--scene=res://tests/ui/fixtures/DialogueChoiceFixture.tscn \
	--scene=res://src/presentation/exploration/ExplorationMode.tscn \
	--scene=res://tests/ui/fixtures/ExplorationFocusFixture.tscn \
	--scene=res://src/presentation/minigames/TeaTemperatureMode.tscn \
	--scene=res://tests/ui/fixtures/TeaTemperatureActiveFixture.tscn \
	--scene=res://tests/ui/fixtures/TeaTemperatureAssistFixture.tscn \
	--scene=res://tests/ui/fixtures/TeaTemperatureResultFixture.tscn \
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
	--scene=res://tests/ui/fixtures/BoundaryStainStressFixture.tscn
run_checked "release validation" "$GODOT_BIN" --headless --path . \
	--script res://src/tools/validate_release.gd -- --release
run_checked "headless tests" "$GODOT_BIN" --headless --path . \
	--script res://tests/run_all.gd
run_checked "M07 packed bullet stress" "$GODOT_BIN" --headless --path . \
	--script res://tests/performance/run_m07_bullet_pool_stress.gd
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
	run_checked "M07 rendered bullet stress" "$GODOT_BIN" \
		--display-driver "${GMH_DISPLAY_DRIVER:-x11}" \
		--rendering-driver opengl3 \
		--audio-driver Dummy \
		--disable-vsync \
		--path . \
		--script res://tests/performance/run_m07_render_stress.gd
fi

echo "Foundation verification passed."
