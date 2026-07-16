extends SceneTree
## Drives the complete SDM loss-escalation route and a read-only excellent replay.

const SLICE_SCENE := preload("res://src/presentation/slice/ScarletDevilMansionSliceMode.tscn")
const TEST_ROOT := "user://tests/m12_sdm_vertical_slice"
const EVENT_ID: StringName = &"evt.sdm.late_by_three_minutes"
const JOURNAL_ID: StringName = &"journal.sdm.missing_minute"
const KEEPSAKE_ID: StringName = &"item.keepsake.unfinished_checklist"

var _failures: Array[String] = []
var _slice: VerticalSliceMode
var _kernel: Node
var _save_service: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_prepare_services()
	_slice = SLICE_SCENE.instantiate() as VerticalSliceMode
	root.add_child(_slice)
	await process_frame
	_slice.set_instant_text_for_test(true)
	_expect(_slice.slice_component_id() == &"scarlet_devil_mansion", "SDM scene did not select its slice component")
	_expect(_slice.phase_id() == &"invitation", "new SDM day did not begin at its schedule invitation")

	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"world_map", "schedule invitation did not open the world map")
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"exploration", "map travel did not enter mansion exploration")
	_expect(_kernel.state_snapshot().current_location == &"loc.scarlet_devil_mansion", "mansion travel was not persisted")
	_expect(_slice.complete_exploration_for_test(), "clock-then-tray exploration could not trigger the event")
	_expect(_slice.current_event_node_id() == &"n003", "mansion exploration did not reach Sakuya's opening line")
	_expect(_slice.current_stage_component() == &"mansion_clock", "opening dialogue did not use the clock-corridor stage")

	_accept_line()
	_expect(_slice.phase_id() == &"choice", "Sakuya's opening line did not reach the four-tone choice")
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.current_event_node_id() == &"n_direct_line", "Direct tone did not reach Sakuya's authored response")
	_expect(_kernel.state_snapshot().characters[&"char.sakuya_izayoi"].relationship.respect == 1, "Direct tone did not commit Sakuya Respect exactly once")
	_accept_line()

	_expect(_slice.phase_id() == &"mini.sdm.time_grid_service", "tone response did not instantiate Time Grid Service")
	var time_grid := _slice.active_child_mode() as TimeGridServiceMode
	_expect(time_grid != null and time_grid.assist_settings.no_timer, "Story preset did not inject Time Grid assists")
	_expect(_slice.submit_mode_result_for_test(&"loss", 2), "Time Grid loss could not return to the event")
	_expect(_slice.current_event_node_id() == &"n_service_loss", "Time Grid loss did not reach its escalation line")
	_accept_line()

	_expect(_slice.phase_id() == &"danmaku.sdm.missing_minute_knives", "service loss did not instantiate Missing Minute Knives")
	var knives := _slice.active_child_mode() as BoundaryStainMode
	_expect(
		knives != null
		and knives.assist_settings.safe_lane_preview
		and knives.assist_settings.auto_bomb
		and knives.assist_settings.density_percent == 70,
		"Story preset did not inject the knife-pattern assist contract"
	)
	_expect(_slice.submit_mode_result_for_test(&"assist_clear", 3), "knife assist clear could not return to the event")
	_expect(_slice.current_event_node_id() == &"n_danmaku_assist", "knife assist clear did not reach its authored response")
	_accept_line()

	_expect(_slice.phase_id() == &"afterbeat" and _slice.current_event_node_id() == &"n_after_01", "knife response did not reach the missing-minute afterbeat")
	_expect(_slice.current_stage_component() == &"mansion_afterbeat", "missing-minute line did not use its quiet stage")
	_slice.arm_input_for_test()
	_accept_line()
	_expect(_slice.current_event_node_id() == &"n_after_02", "afterbeat omitted the deliberate blank line")
	_slice.arm_input_for_test()
	_accept_line()
	_expect(_slice.current_event_node_id() == &"n_patchouli", "afterbeat did not reach Patchouli's teaser")
	_expect(_slice.current_stage_component() == &"mansion_library", "Patchouli teaser did not use the library component")
	_accept_line()
	_expect(_slice.current_event_node_id() == &"n_remilia_public" and _slice.current_stage_component() == &"mansion_balcony_public", "Patchouli teaser did not reach Remilia's public scene")
	_accept_line()
	_expect(_slice.current_event_node_id() == &"n_remilia_private" and _slice.current_stage_component() == &"mansion_balcony_private", "Remilia's public mask did not transition to the private scene")
	_accept_line()
	_expect(_slice.phase_id() == &"reward", "Remilia's private line did not complete the event")

	var completed := _kernel.state_snapshot() as GameState
	_expect(EVENT_ID in completed.completed_event_ids, "SDM slice did not record event completion")
	_expect(completed.inventory.keepsakes.has(KEEPSAKE_ID), "SDM slice did not grant the unfinished checklist")
	_expect(completed.journal.entries.has(JOURNAL_ID), "SDM slice did not add the missing-minute Journal entry")
	_expect(EVENT_ID in completed.journal.replay_event_ids, "SDM slice did not unlock read-only replay")
	var observed_flag := completed.flags.get(&"flag.sdm.missing_minute.observed") as FlagState
	_expect(observed_flag != null and observed_flag.boolean_value, "SDM completion flag was not committed")

	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"day_end", "SDM reward did not close and save the day")
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"journal", "SDM day end did not open the Journal")
	var before_replay := GameStateCodec.new().canonical_state(_kernel.state_snapshot())
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.is_replay() and _slice.current_event_node_id() == &"n003", "SDM Journal did not start replay")
	_drive_excellent_replay()
	_expect(_slice.phase_id() == &"replay_complete", "SDM replay did not reach its read-only completion screen")
	_expect(GameStateCodec.new().canonical_state(_kernel.state_snapshot()) == before_replay, "SDM replay mutated the active save")

	_slice.queue_free()
	await process_frame
	_finish()


func _drive_excellent_replay() -> void:
	_accept_line()
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_accept_line()
	_expect(_slice.submit_mode_result_for_test(&"excellent"), "replay Time Grid excellent result failed")
	_accept_line()
	for _afterbeat_index: int in range(2):
		_slice.arm_input_for_test()
		_accept_line()
	for _followup_index: int in range(3):
		_accept_line()


func _accept_line() -> void:
	_slice.handle_semantic_action(GameInput.CONFIRM)


func _prepare_services() -> void:
	_remove_tree(TEST_ROOT)
	var localization := root.get_node_or_null("LocalizationService")
	localization.set_locale(&"en", false)
	var accessibility := root.get_node_or_null("AccessibilityState")
	accessibility.apply_preset(AccessibilityState.Preset.STORY, false)
	_kernel = root.get_node_or_null("GameKernel")
	_kernel.clear_state()
	var created: CommandResult = _kernel.create_new_profile(&"p121", &"accessibility.story")
	_expect(created.is_success(), "M12 test profile could not be created")
	_save_service = root.get_node_or_null("SaveService")
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
	print("M12 SDM vertical slice integration: failures=%d" % _failures.size())
	for failure: String in _failures:
		printerr("FAIL: %s" % failure)
	quit(0 if _failures.is_empty() else 1)
