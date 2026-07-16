extends SceneTree
## Proves generic-slice auto-selection at every SDM save boundary.

const SDM_SCENE := preload("res://src/presentation/slice/ScarletDevilMansionSliceMode.tscn")
const BASE_SCENE := preload("res://src/presentation/slice/VerticalSliceMode.tscn")
const TEST_ROOT := "user://tests/m12_sdm_save_resume"
const PROFILE_ID: StringName = &"p122"

var _failures: Array[String] = []
var _slice: VerticalSliceMode
var _kernel: Node
var _save_service: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_prepare_services()
	await _spawn_slice(SDM_SCENE)
	_drive_to_time_grid()
	_expect(_slice.phase_id() == &"mini.sdm.time_grid_service", "setup did not reach Time Grid")
	_expect(_kernel.state_snapshot().active_event_node_id == &"n006", "Time Grid boundary did not persist n006")

	await _reload_slot(&"auto_mode")
	_expect(_slice.slice_component_id() == &"scarlet_devil_mansion", "base slice did not infer SDM from the active event")
	_expect(_slice.phase_id() == &"mini.sdm.time_grid_service", "before-mode save did not rebuild Time Grid")
	_expect(_slice.current_event_node_id() == &"n006", "Time Grid reload changed the event cursor")
	_expect(_slice.submit_mode_result_for_test(&"loss"), "Time Grid loss failed after reload")
	_expect(_slice.current_event_node_id() == &"n_service_loss", "reloaded Time Grid loss did not reach its line")
	_accept_line()
	_expect(_slice.phase_id() == &"danmaku.sdm.missing_minute_knives", "service loss did not reach knives")
	_expect(_kernel.state_snapshot().active_event_node_id == &"n_danmaku", "knife boundary did not persist n_danmaku")

	await _reload_slot(&"auto_mode")
	_expect(_slice.phase_id() == &"danmaku.sdm.missing_minute_knives", "before-mode save did not rebuild knives")
	_expect(_slice.current_event_node_id() == &"n_danmaku", "knife reload changed the event cursor")
	_expect(_slice.submit_mode_result_for_test(&"assist_clear"), "knife assist clear failed after reload")
	_expect(_slice.current_event_node_id() == &"n_danmaku_assist", "knife result did not persist its authored line")

	await _reload_slot(&"auto_mode")
	_expect(_slice.phase_id() == &"dialogue" and _slice.current_event_node_id() == &"n_danmaku_assist", "after-mode save did not rebuild the knife result line")
	_expect(_kernel.state_snapshot().characters[&"char.sakuya_izayoi"].relationship.respect == 1, "save/resume re-applied Sakuya's Direct effect")
	_accept_line()
	for _afterbeat_index: int in range(2):
		_slice.arm_input_for_test()
		_accept_line()
	for _followup_index: int in range(3):
		_accept_line()
	_expect(_slice.phase_id() == &"reward", "resumed SDM route did not complete")

	await _reload_slot(&"auto_event")
	_expect(_slice.slice_component_id() == &"scarlet_devil_mansion", "base slice did not infer SDM from its unread completed Journal entry")
	_expect(_slice.phase_id() == &"reward", "event-completion save did not rebuild the SDM reward")
	var completed := _kernel.state_snapshot() as GameState
	_expect(completed.inventory.keepsakes.has(&"item.keepsake.unfinished_checklist"), "event-completion save omitted the checklist")
	_expect(completed.journal.entries.has(&"journal.sdm.missing_minute"), "event-completion save omitted the Journal entry")

	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"day_end", "reward confirmation did not finish the SDM day")
	await _reload_slot(&"manual_01")
	_expect(_slice.slice_component_id() == &"scarlet_devil_mansion", "day-end manual save lost its completed SDM region shell")
	_expect(_slice.phase_id() == &"journal", "day-end manual save did not reopen the completed SDM Journal")
	_expect(_kernel.state_snapshot().journal.entries[&"journal.sdm.missing_minute"].is_read, "day-end manual save did not retain the read marker")

	await _free_slice()
	_finish()


func _drive_to_time_grid() -> void:
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.complete_exploration_for_test(), "save/resume setup could not complete mansion exploration")
	_accept_line()
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_accept_line()


func _reload_slot(slot_id: StringName) -> void:
	await _free_slice()
	_kernel.clear_state()
	var loaded: Variant = _save_service.load_slot(PROFILE_ID, slot_id)
	_expect(loaded is SaveOperationResult and loaded.is_success(), "could not load %s" % slot_id)
	await _spawn_slice(BASE_SCENE)


func _spawn_slice(scene: PackedScene) -> void:
	_slice = scene.instantiate() as VerticalSliceMode
	root.add_child(_slice)
	await process_frame
	_slice.set_instant_text_for_test(true)


func _free_slice() -> void:
	if _slice != null and is_instance_valid(_slice):
		_slice.free()
	_slice = null
	await process_frame
	await process_frame


func _accept_line() -> void:
	_slice.handle_semantic_action(GameInput.CONFIRM)


func _prepare_services() -> void:
	_remove_tree(TEST_ROOT)
	root.get_node("LocalizationService").set_locale(&"en", false)
	root.get_node("AccessibilityState").apply_preset(AccessibilityState.Preset.STORY, false)
	_kernel = root.get_node("GameKernel")
	_kernel.clear_state()
	var created: CommandResult = _kernel.create_new_profile(PROFILE_ID, &"accessibility.story")
	_expect(created.is_success(), "M12 save/resume profile could not be created")
	_save_service = root.get_node("SaveService")
	_save_service.configure_for_test(_kernel, TEST_ROOT)


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


func _finish() -> void:
	_remove_tree(TEST_ROOT)
	print("M12 SDM save/resume matrix: failures=%d" % _failures.size())
	for failure: String in _failures:
		printerr("FAIL: %s" % failure)
	quit(0 if _failures.is_empty() else 1)
