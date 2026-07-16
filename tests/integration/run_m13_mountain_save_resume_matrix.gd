extends SceneTree
## Proves strategy, rumor, region, and cursor state across every mountain save boundary.

const MOUNTAIN_SCENE := preload("res://src/presentation/slice/YoukaiMountainSliceMode.tscn")
const BASE_SCENE := preload("res://src/presentation/slice/VerticalSliceMode.tscn")
const TEST_ROOT := "user://tests/m13_mountain_save_resume"
const PROFILE_ID: StringName = &"p134"
const EVENT_ID: StringName = &"evt.mtn.tomorrows_headline"
const JOURNAL_ID: StringName = &"journal.mtn.tomorrows_headline"
const RUMOR_ID: StringName = &"rumor.mtn.tomorrows_headline"

var _failures: Array[String] = []
var _slice: VerticalSliceMode
var _kernel: Node
var _save_service: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_prepare_services()
	await _spawn_slice(MOUNTAIN_SCENE)
	_drive_to_wind_frame()
	_expect(_slice.phase_id() == &"danmaku.mtn.tomorrows_headline", "setup did not reach Wind-Frame")
	_expect(_kernel.state_snapshot().active_event_node_id == &"n_danmaku", "mode checkpoint did not persist n_danmaku")

	await _reload_slot(&"auto_mode")
	_expect(_slice.slice_component_id() == &"youkai_mountain", "base slice did not infer the active mountain event")
	_expect(_slice.phase_id() == &"danmaku.mtn.tomorrows_headline", "before-mode save did not rebuild Wind-Frame")
	_expect(
		_slice.submit_mode_result_for_test(&"clear", 2, [&"strategy.photo_frame"]),
		"reloaded Wind-Frame result could not return"
	)
	_expect(_slice.current_event_node_id() == &"n_danmaku_clear", "after-mode cursor did not reach the clear response")

	await _reload_slot(&"auto_mode")
	var after_mode := _kernel.state_snapshot() as GameState
	_expect(_slice.current_event_node_id() == &"n_danmaku_clear", "after-mode save did not rebuild the clear response")
	_expect(
		RecordedStrategyLedger.ranked_tags(after_mode) == [&"strategy.photo_frame"],
		"after-mode save lost the recorded photo-frame strategy"
	)
	var count := after_mode.flags.get(&"flag.archive.strategy.photo_frame") as FlagState
	_expect(count != null and count.integer_value == 1, "save/resume re-applied the photo-frame strategy")

	_accept_line()
	_slice.arm_input_for_test()
	_accept_line()
	_slice.arm_input_for_test()
	_accept_line()
	_expect(_slice.phase_id() == &"reward", "resumed mountain event did not complete")

	await _reload_slot(&"auto_event")
	var completed := _kernel.state_snapshot() as GameState
	_expect(_slice.phase_id() == &"reward", "event-completion save did not rebuild the mountain reward")
	_expect(EVENT_ID in completed.completed_event_ids, "event-completion save lost Tomorrow's Headline")
	_expect(completed.rumors.has(RUMOR_ID), "event-completion save lost the initial rumor")
	if completed.rumors.has(RUMOR_ID):
		var initial := completed.rumors[RUMOR_ID] as RumorState
		_expect(
			initial.claim_key == &"rumor.mtn.tomorrows_headline.withheld_correction"
			and initial.mutation_count == 0
			and initial.privacy == &"shared",
			"event-completion save changed the rumor before day end"
		)
	_expect(
		completed.journal.entries.has(JOURNAL_ID)
		and &"strategy.photo_frame" in completed.journal.entries[JOURNAL_ID].tags,
		"event-completion save lost the Journal strategy evidence"
	)

	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"day_end", "reward confirmation did not finish the mountain day")
	await _reload_slot(&"manual_01")
	var resumed_day := _kernel.state_snapshot() as GameState
	_expect(_slice.phase_id() == &"journal", "day-end manual save did not reopen the mountain Journal")
	_expect(resumed_day.day == 2 and resumed_day.time_slot == &"morning", "day-end save lost the next morning")
	var retold := resumed_day.rumors.get(RUMOR_ID) as RumorState
	_expect(
		retold != null
		and retold.claim_key == &"rumor.mtn.tomorrows_headline.reporter_prevented_accident"
		and retold.mutation_count == 1
		and retold.reliability_milli == 610
		and retold.privacy == &"public",
		"day-end save lost or repeated the public rumor retelling"
	)
	for region_id: StringName in [&"loc.hakurei_shrine", &"loc.scarlet_devil_mansion"]:
		_expect(
			resumed_day.regions[region_id].condition_id == &"region.rumor.future_headline_arrived",
			"day-end save lost the cross-region condition at %s" % region_id
		)
	var resumed_count := resumed_day.flags.get(&"flag.archive.strategy.photo_frame") as FlagState
	_expect(resumed_count != null and resumed_count.integer_value == 1, "day-end resume changed the Archive strategy count")
	_expect(resumed_day.journal.entries[JOURNAL_ID].is_read, "day-end resume lost the Journal read marker")

	await _free_slice()
	_finish()


func _drive_to_wind_frame() -> void:
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.complete_exploration_for_test(), "save/resume setup could not complete mountain exploration")
	_accept_line()
	_accept_line()
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_accept_line()
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
	_expect(created.is_success(), "M13 save/resume profile could not be created")
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
	print("M13 Youkai Mountain save/resume matrix: failures=%d" % _failures.size())
	for failure: String in _failures:
		printerr("FAIL: %s" % failure)
	quit(0 if _failures.is_empty() else 1)
