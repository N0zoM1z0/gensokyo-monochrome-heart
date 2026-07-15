extends SceneTree
## P0 soak: twenty full slice runs plus ten read-only Journal replay cycles.

const SLICE_SCENE := preload("res://src/presentation/slice/VerticalSliceMode.tscn")
const TEST_ROOT := "user://tests/m09_stability"
const COMPLETE_RUNS := 20
const REPLAY_CYCLES := 10
const OBJECT_DRIFT_LIMIT := 0
const MEMORY_DRIFT_LIMIT_BYTES := 64 * 1024

var _failures: Array[String] = []
var _kernel: Node
var _save_service: Node
var _slice: VerticalSliceMode


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_remove_tree(TEST_ROOT)
	_kernel = root.get_node_or_null("GameKernel")
	_save_service = root.get_node_or_null("SaveService")
	var localization := root.get_node_or_null("LocalizationService")
	localization.set_locale(&"en", false)
	var accessibility := root.get_node_or_null("AccessibilityState")
	accessibility.apply_preset(AccessibilityState.Preset.STORY, false)

	for index: int in range(COMPLETE_RUNS):
		_prepare_profile(StringName("p%d" % (110 + index)), "complete_%02d" % index)
		await _spawn_slice()
		_drive_to_journal("complete run %02d" % (index + 1))
		_press(GameInput.CANCEL)
		_expect(_slice.phase_id() == &"complete", "complete run %02d did not reach completion" % (index + 1))
		_press(GameInput.CONFIRM)
		await _free_slice()

	_prepare_profile(&"p140", "replay_soak")
	await _spawn_slice()
	_drive_to_journal("replay setup")
	var canonical_before := GameStateCodec.new().canonical_state(_kernel.state_snapshot())
	var memory_samples: Array[int] = []
	var object_samples: Array[int] = []
	for cycle: int in range(REPLAY_CYCLES):
		_drive_replay_cycle(cycle + 1)
		await process_frame
		await process_frame
		_expect(
			GameStateCodec.new().canonical_state(_kernel.state_snapshot()) == canonical_before,
			"replay cycle %02d mutated the main save" % (cycle + 1)
		)
		memory_samples.append(OS.get_static_memory_usage())
		object_samples.append(int(Performance.get_monitor(Performance.OBJECT_COUNT)))
	_check_memory_trend(memory_samples, object_samples)
	await _free_slice()
	_remove_tree(TEST_ROOT)
	print(
		"M09 stability matrix: complete_runs=%d replay_cycles=%d memory_bytes=%s objects=%s failures=%d"
		% [COMPLETE_RUNS, REPLAY_CYCLES, memory_samples, object_samples, _failures.size()]
	)
	for failure: String in _failures:
		printerr("FAIL: %s" % failure)
	quit(0 if _failures.is_empty() else 1)


func _prepare_profile(profile_id: StringName, save_leaf: String) -> void:
	_kernel.clear_state()
	var created: CommandResult = _kernel.create_new_profile(profile_id, &"accessibility.story")
	_expect(created.is_success(), "%s profile could not be created" % save_leaf)
	_save_service.configure_for_test(_kernel, "%s/%s" % [TEST_ROOT, save_leaf])


func _spawn_slice() -> void:
	_slice = SLICE_SCENE.instantiate() as VerticalSliceMode
	root.add_child(_slice)
	await process_frame
	_slice.set_instant_text_for_test(true)


func _free_slice() -> void:
	if _slice != null and is_instance_valid(_slice):
		_slice.free()
	_slice = null
	await process_frame
	await process_frame


func _drive_to_journal(label: String) -> void:
	_press(GameInput.CONFIRM)
	_press(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"exploration", "%s did not reach exploration" % label)
	_expect(_slice.complete_exploration_for_test(), "%s could not complete exploration" % label)
	_press(GameInput.CONFIRM)
	_press(GameInput.CONFIRM)
	_press(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"mini.shrine.tea_temperature", "%s did not reach Tea Temperature" % label)
	_expect(_slice.submit_mode_result_for_test(&"loss"), "%s could not submit Tea loss" % label)
	_press(GameInput.CONFIRM)
	_press(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"danmaku.hkr.boundary_stain", "%s did not reach Boundary Stain" % label)
	_expect(_slice.submit_mode_result_for_test(&"loss"), "%s could not submit danmaku loss" % label)
	_press(GameInput.CONFIRM)
	_press(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"duel.hkr.spell_card_terms", "%s did not reach the compact duel" % label)
	_expect(_slice.submit_mode_result_for_test(&"loss"), "%s could not submit fighter loss" % label)
	_press(GameInput.CONFIRM)
	for _line: int in range(4):
		_slice.arm_input_for_test()
		_press(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"reward", "%s did not reach reward" % label)
	_press(GameInput.CONFIRM)
	_press(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"journal", "%s did not reach Journal" % label)


func _drive_replay_cycle(cycle: int) -> void:
	_press(GameInput.CONFIRM)
	_expect(_slice.is_replay() and _slice.current_event_node_id() == &"n003", "replay cycle %02d did not start" % cycle)
	_press(GameInput.CONFIRM)
	_press(GameInput.CONFIRM)
	_press(GameInput.CONFIRM)
	_expect(_slice.submit_mode_result_for_test(&"loss"), "replay cycle %02d could not submit Tea loss" % cycle)
	_press(GameInput.CONFIRM)
	_press(GameInput.CONFIRM)
	_expect(_slice.submit_mode_result_for_test(&"loss"), "replay cycle %02d could not submit danmaku loss" % cycle)
	_press(GameInput.CONFIRM)
	_press(GameInput.CONFIRM)
	_expect(_slice.submit_mode_result_for_test(&"loss"), "replay cycle %02d could not submit fighter loss" % cycle)
	_press(GameInput.CONFIRM)
	for _line: int in range(4):
		_slice.arm_input_for_test()
		_press(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"replay_complete", "replay cycle %02d did not complete" % cycle)
	_press(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"journal", "replay cycle %02d did not return to Journal" % cycle)


func _press(action: StringName) -> void:
	_slice.handle_semantic_action(action)


func _check_memory_trend(memory_samples: Array[int], object_samples: Array[int]) -> void:
	if memory_samples.size() != REPLAY_CYCLES or object_samples.size() != REPLAY_CYCLES:
		_failures.append("replay soak did not capture every memory sample")
		return
	var memory_drift := memory_samples[-1] - memory_samples[0]
	var object_drift := object_samples[-1] - object_samples[0]
	_expect(
		memory_drift <= MEMORY_DRIFT_LIMIT_BYTES,
		"static memory grew by %d bytes across replay soak" % memory_drift
	)
	_expect(
		object_drift <= OBJECT_DRIFT_LIMIT,
		"live object count grew by %d across replay soak" % object_drift
	)
	var memory_rises := 0
	var object_rises := 0
	for index: int in range(1, REPLAY_CYCLES):
		if memory_samples[index] > memory_samples[index - 1]:
			memory_rises += 1
		if object_samples[index] > object_samples[index - 1]:
			object_rises += 1
	_expect(memory_rises < REPLAY_CYCLES - 1, "static memory rose on every replay cycle")
	_expect(object_rises < REPLAY_CYCLES - 1, "live object count rose on every replay cycle")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _remove_tree(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var child := "%s/%s" % [path, entry]
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(child))
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(absolute)
