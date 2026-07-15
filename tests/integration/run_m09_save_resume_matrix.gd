extends SceneTree
## Proves M09 save boundaries, exact event resume, backup recovery, and post-load locale switching.

const SLICE_SCENE := preload("res://src/presentation/slice/VerticalSliceMode.tscn")
const TEST_ROOT := "user://tests/m09_save_resume"
const PROFILE_ID: StringName = &"p92"

var _failures: Array[String] = []
var _slice: VerticalSliceMode
var _kernel: Node
var _save_service: Node
var _localization: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_prepare_services()
	await _spawn_slice()
	_drive_to_tea()
	_expect(_slice.phase_id() == &"mini.shrine.tea_temperature", "slice did not reach the Tea boundary")
	_expect(_kernel.state_snapshot().active_event_node_id == &"n005", "Tea boundary did not persist n005")
	await _reload_slot(&"auto_mode", &"ja")
	_expect(_slice.phase_id() == &"mini.shrine.tea_temperature", "before-mode save did not rebuild Tea")
	_expect(_slice.current_event_node_id() == &"n005", "Tea reload changed the event cursor")
	_expect(_localization.locale == &"ja", "locale preference was not retained while rebuilding Tea")

	_expect(_slice.submit_mode_result_for_test(&"clear"), "Tea Clear could not be submitted after reload")
	_expect(_slice.current_event_node_id() == &"n006b", "Tea Clear did not persist its authored response")
	_accept_line()
	_accept_line()
	_expect(_slice.phase_id() == &"danmaku.hkr.boundary_stain", "Tea response did not reach Boundary Stain")
	_expect(_kernel.state_snapshot().active_event_node_id == &"n007", "danmaku boundary did not persist n007")
	await _reload_slot(&"auto_mode", &"en")
	_expect(_slice.phase_id() == &"danmaku.hkr.boundary_stain", "before-mode save did not rebuild Boundary Stain")
	_expect(_slice.current_event_node_id() == &"n007", "Boundary Stain reload changed the event cursor")

	_expect(_slice.submit_mode_result_for_test(&"loss"), "Boundary Stain Loss could not be submitted after reload")
	_expect(_slice.current_event_node_id() == &"n007c", "danmaku Loss did not reach its respectful response")
	await _reload_slot(&"auto_mode", &"en")
	_expect(_slice.phase_id() == &"dialogue", "after-mode save did not rebuild the danmaku result line")
	_expect(_slice.current_event_node_id() == &"n007c", "after-mode save did not preserve n007c")
	_expect(
		_kernel.state_snapshot().characters[&"char.reimu_hakurei"].relationship.respect == 1,
		"save/resume re-applied the Direct tone effect"
	)

	_accept_line()
	_accept_line()
	_expect(_slice.phase_id() == &"duel.hkr.spell_card_terms", "reloaded danmaku response did not reach the duel")
	_expect(_slice.submit_mode_result_for_test(&"loss"), "duel Loss could not be submitted after reload")
	_accept_line()
	for _index: int in range(4):
		_slice.arm_input_for_test()
		_accept_line()
	_expect(_slice.phase_id() == &"reward", "reloaded route did not complete the authored event")

	await _reload_slot(&"auto_event", &"en")
	_expect(_slice.phase_id() == &"reward", "event-completion autosave did not rebuild the reward boundary")
	var completed := _kernel.state_snapshot() as GameState
	_expect(&"evt.hkr.empty_cushion" in completed.completed_event_ids, "event-completion save omitted the completed event")
	_expect(completed.inventory.keepsakes.has(&"item.keepsake.unpaired_cup"), "event-completion save omitted the Keepsake")
	_expect(completed.journal.entries.has(&"journal.hkr.empty_cushion"), "event-completion save omitted the Journal entry")

	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"day_end", "reward reload could not finish the day")
	var second_manual: Variant = _save_service.save_manual(1, null, "2026-07-15T16:00:00Z")
	_expect(second_manual is SaveOperationResult and second_manual.is_success(), "second manual save could not create a recovery backup")
	if not second_manual is SaveOperationResult or not second_manual.is_success():
		await _free_slice()
		_finish()
		return
	_corrupt_current_manual()
	await _free_slice()
	_kernel.clear_state()
	var recovered: Variant = _save_service.load_slot(PROFILE_ID, &"manual_01")
	_expect(recovered is SaveOperationResult and recovered.is_success(), "corrupted current manual save did not recover")
	_expect(recovered is SaveOperationResult and recovered.was_recovered_from_backup, "manual load did not report backup recovery")
	if not recovered is SaveOperationResult or not recovered.is_success():
		_finish()
		return
	await _spawn_slice()
	_expect(_slice.phase_id() == &"journal", "recovered day-end manual save did not rebuild the Journal")
	var recovered_state := _kernel.state_snapshot() as GameState
	_expect(recovered_state.day == 2 and recovered_state.time_slot == &"morning", "recovered manual save lost day-end time")
	_localization.set_locale(&"en", false)
	_slice.handle_semantic_action(GameInput.PAGE_RIGHT)
	_expect(_localization.locale == &"ja", "locale could not switch after a recovered load")
	_expect(_slice.phase_id() == &"journal", "post-load locale switch changed the gameplay cursor")

	await _free_slice()
	_finish()


func _prepare_services() -> void:
	_remove_tree(TEST_ROOT)
	_localization = root.get_node_or_null("LocalizationService")
	_localization.set_locale(&"en", false)
	var accessibility := root.get_node_or_null("AccessibilityState")
	accessibility.apply_preset(AccessibilityState.Preset.STORY, false)
	_kernel = root.get_node_or_null("GameKernel")
	_kernel.clear_state()
	var created: CommandResult = _kernel.create_new_profile(PROFILE_ID, &"accessibility.story")
	_expect(created.is_success(), "save/resume profile could not be created")
	_save_service = root.get_node_or_null("SaveService")
	_save_service.configure_for_test(_kernel, TEST_ROOT)


func _drive_to_tea() -> void:
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.complete_exploration_for_test(), "save/resume setup could not complete exploration")
	_accept_line()
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_accept_line()


func _reload_slot(slot_id: StringName, locale: StringName) -> void:
	await _free_slice()
	_kernel.clear_state()
	_localization.set_locale(locale, false)
	var loaded: Variant = _save_service.load_slot(PROFILE_ID, slot_id)
	_expect(loaded is SaveOperationResult and loaded.is_success(), "could not load %s" % slot_id)
	await _spawn_slice()


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


func _accept_line() -> void:
	_slice.handle_semantic_action(GameInput.CONFIRM)


func _corrupt_current_manual() -> void:
	var path := "%s/%s/manual_01.save" % [TEST_ROOT, PROFILE_ID]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("could not open the current manual save for corruption fixture")
		return
	file.store_string("{deliberately truncated")
	file.close()


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
	print("M09 save/resume matrix: failures=%d" % _failures.size())
	for failure: String in _failures:
		printerr("FAIL: %s" % failure)
	quit(0 if _failures.is_empty() else 1)
