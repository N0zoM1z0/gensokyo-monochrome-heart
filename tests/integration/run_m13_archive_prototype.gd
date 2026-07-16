extends SceneTree
## Instantiates the ledger-driven finale and its before/after visual rule states.

const TUTORIAL := preload("res://tests/ui/fixtures/ArchiveTutorialFixture.tscn")
const FAMILIAR := preload("res://tests/ui/fixtures/ArchiveFamiliarFixture.tscn")
const REMOVAL := preload("res://tests/ui/fixtures/ArchiveRemovalFixture.tscn")
const REAL_MODE := preload("res://src/presentation/danmaku/ArchivePrototypeMode.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var kernel := root.get_node("GameKernel")
	kernel.clear_state()
	var created: CommandResult = kernel.create_new_profile(&"p135", &"accessibility.story")
	_expect(created.is_success(), "Archive integration profile could not be created")
	var campaign := kernel.state_snapshot() as GameState
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(campaign, RecordStrategyUseCommand.new(&"evt.mtn.tomorrows_headline", &"strategy.photo_frame"))
	dispatcher.dispatch(campaign, RecordStrategyUseCommand.new(&"evt.fixture.second_photo", &"strategy.photo_frame"))
	dispatcher.dispatch(campaign, RecordStrategyUseCommand.new(&"evt.fixture.focus", &"strategy.focus_lane"))
	var accepted: CommandResult = kernel.replace_state(campaign, &"test.archive_strategy_ledger")
	_expect(accepted.is_success(), "Archive integration ledger could not be activated")
	var real_mode := await _spawn(REAL_MODE)
	_expect(
		real_mode.indexed_strategy_tags().slice(0, 2) == [&"strategy.photo_frame", &"strategy.focus_lane"],
		"live Archive mode did not consume the active profile's ranked strategy ledger"
	)
	await _free(real_mode)

	var tutorial := await _spawn(TUTORIAL)
	_expect(tutorial.indexed_strategy_tags() == [&"strategy.photo_frame"], "tutorial did not consume the fixture strategy ledger")
	_expect(tutorial.runtime is ArchiveAdaptiveSimulation, "tutorial did not use the adaptive Archive simulation")
	_expect(tutorial.teaching_keys[0] == &"ui.archive.teach.photo_frame", "tutorial did not disclose the indexed habit")
	await _free(tutorial)

	var familiar := await _spawn(FAMILIAR)
	var familiar_debug := familiar.capture_debug_state()
	_expect(int(familiar_debug.get("phase", -1)) == 2, "familiar fixture did not reach Margin of Error")
	_expect(not bool(familiar_debug.get("familiar_lane_removed", true)), "familiar fixture removed the guide too early")
	_expect(familiar.runtime.safe_lane_preview() == 5, "familiar fixture did not show its shifted safe lane")
	_expect(familiar.runtime.state.player_x_fp == 112 * BoundaryStainSimulation.FP, "familiar fixture did not center the player in the indexed lane")
	await _free(familiar)

	var removal := await _spawn(REMOVAL)
	var removal_debug := removal.capture_debug_state()
	_expect(removal.archive_fixture_after_removal, "removal fixture lost its requested post-transform state")
	_expect(bool(removal_debug.get("familiar_lane_removed", false)), "removal fixture did not cross the authored transform")
	_expect(removal.runtime.safe_lane_preview() == -1, "removal fixture still exposed the obsolete safe guide")
	_expect(removal.runtime.state.player_x_fp == 112 * BoundaryStainSimulation.FP, "removal proof moved the player away from the former lane")
	_expect(int(removal_debug.get("phase_tick", 0)) > removal.runtime.current_phase().transform_tick, "removal proof lacks a post-transform tick")
	await _free(removal)

	print("M13 Archive prototype integration: failures=%d" % _failures.size())
	for failure: String in _failures:
		printerr("FAIL: %s" % failure)
	quit(0 if _failures.is_empty() else 1)


func _spawn(scene: PackedScene) -> ArchivePrototypeMode:
	var mode := scene.instantiate() as ArchivePrototypeMode
	root.add_child(mode)
	await process_frame
	return mode


func _free(mode: ArchivePrototypeMode) -> void:
	mode.free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
