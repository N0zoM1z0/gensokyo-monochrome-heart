extends SceneTree
## Drives one full Story-preset day plus a read-only Journal replay.

const SLICE_SCENE := preload("res://src/presentation/slice/VerticalSliceMode.tscn")
const TEST_ROOT := "user://tests/m09_vertical_slice"

var _failures: Array[String] = []
var _slice: VerticalSliceMode
var _kernel: Node
var _save_service: Node
var _completed_results: Array[ModeResult] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_prepare_services()
	_slice = SLICE_SCENE.instantiate() as VerticalSliceMode
	_slice.mode_completed.connect(func(result: ModeResult) -> void: _completed_results.append(result))
	root.add_child(_slice)
	await process_frame
	_slice.set_instant_text_for_test(true)
	_expect(_slice.phase_id() == &"invitation", "new profile did not begin at the lodging invitation")

	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"world_map", "invitation did not open the world map")
	var prepared := _kernel.state_snapshot() as GameState
	_expect(prepared.chapter_id == &"chapter.1" and prepared.time_slot == &"day", "day desk did not prepare chapter one daytime state")

	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"exploration", "map travel did not enter the real shrine exploration")
	var exploration := _slice.active_child_mode() as ExplorationMode
	_expect(exploration != null and exploration.exploration_context.story_navigation_hints, "Story preset did not enable the exploration navigation hint")
	_expect(_kernel.state_snapshot().current_location == &"loc.hakurei_shrine", "map travel did not persist Hakurei Shrine")
	_expect(_slice.complete_exploration_for_test(), "real exploration could not complete the cup/cushion objective")
	_expect(_slice.phase_id() == &"dialogue" and _slice.current_event_node_id() == &"n003", "exploration trigger did not start the authored event opening")
	_expect(_slice.music_player.is_dialogue_ducked, "important dialogue did not duck the music bed")

	_slice.handle_semantic_action(GameInput.PAGE_RIGHT)
	_expect(_slice.current_text().contains("湯呑み"), "live locale switch did not update the production dialogue")
	_slice.handle_semantic_action(GameInput.PAGE_LEFT)
	_expect(_slice.current_text().contains("second cup"), "dialogue locale did not switch back to English in place")
	_accept_line()
	_expect(_slice.phase_id() == &"choice" and _slice.current_event_node_id() == &"n004", "opening line did not reach the four-tone choice")
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.current_event_node_id() == &"n_direct_line", "Direct choice did not reach its authored response")
	var after_choice := _kernel.state_snapshot() as GameState
	_expect(after_choice.characters[&"char.reimu_hakurei"].relationship.respect == 1, "Direct relationship effect was not committed exactly once")

	_accept_line()
	_expect(_slice.phase_id() == &"mini.shrine.tea_temperature", "tone response did not instantiate Tea Temperature")
	_expect(not _slice.music_player.is_dialogue_ducked, "mechanical mode retained dialogue music ducking")
	var tea := _slice.active_child_mode() as TeaTemperatureMode
	_expect(
		tea != null
		and tea.assist_settings.slower_heat_change
		and tea.assist_settings.wider_target_band
		and tea.assist_settings.no_timer,
		"Story preset did not inject all Tea Temperature assists"
	)
	_expect(_slice.submit_mode_result_for_test(&"excellent", 2), "typed Excellent result could not return from Tea Temperature")
	_expect(_slice.current_event_node_id() == &"n006a", "Excellent result did not reach its response line")
	_accept_line()
	_expect(_slice.current_event_node_id() == &"n006d", "tea response omitted the boundary-stain setup")
	_accept_line()
	_expect(_slice.phase_id() == &"danmaku.hkr.boundary_stain", "boundary setup did not instantiate the real danmaku mode")
	var danmaku := _slice.active_child_mode() as BoundaryStainMode
	_expect(
		danmaku != null
		and danmaku.assist_settings.density_percent == 70
		and danmaku.assist_settings.bullet_speed_percent == 90
		and danmaku.assist_settings.safe_lane_preview
		and danmaku.assist_settings.auto_bomb
		and danmaku.assist_settings.no_flash,
		"Story preset did not inject the complete Boundary Stain assist set"
	)
	_expect(
		_slice.resolve_input_candidates([GameInput.CANCEL, GameInput.FOCUS, GameInput.HEAVY]) == GameInput.FOCUS,
		"shared B/X binding did not resolve exclusively to Focus during danmaku"
	)
	_slice.music_player.advance_for_test(AdaptiveTestTonePlayer.BAR_SECONDS)
	_expect(_slice.music_player.current_state_id == &"mus_border_crossing", "boundary music did not change at a bar boundary")
	_expect(_slice.submit_mode_result_for_test(&"assist_clear", 3), "typed Assist Clear could not return from Boundary Stain")
	_expect(_slice.current_event_node_id() == &"n007b", "Assist Clear did not reach its respectful authored response")
	_accept_line()
	_expect(_slice.current_event_node_id() == &"n007d", "danmaku response omitted Marisa's arrival")
	_accept_line()
	_expect(_slice.phase_id() == &"duel.hkr.spell_card_terms", "Marisa's line did not instantiate the compact fighter")
	var fighter := _slice.active_child_mode() as CompactFighterMode
	_expect(
		fighter != null
		and fighter.assist_settings.simple_inputs
		and fighter.assist_settings.hold_to_guard
		and fighter.assist_settings.speed_percent == 90
		and fighter.assist_settings.auto_face
		and fighter.assist_settings.no_flash,
		"Story preset did not inject the complete compact-fighter assist set"
	)
	_expect(
		_slice.resolve_input_candidates([GameInput.CANCEL, GameInput.FOCUS, GameInput.HEAVY]) == GameInput.HEAVY,
		"shared B/X binding did not resolve exclusively to Heavy during the duel"
	)
	_slice.music_player.advance_for_test(AdaptiveTestTonePlayer.BAR_SECONDS)
	_expect(_slice.music_player.current_state_id == &"mus_shrine_duel", "duel music did not change at a bar boundary")
	_expect(_slice.submit_mode_result_for_test(&"win"), "typed Win could not return from the compact fighter")
	_expect(_slice.current_event_node_id() == &"n008a", "fighter Win did not reach its authored response")
	_accept_line()
	_expect(_slice.phase_id() == &"afterbeat" and _slice.current_event_node_id() == &"n_afterbeat_01", "fighter response did not enter the quiet afterbeat")
	var guarded_node := _slice.current_event_node_id()
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.current_event_node_id() == guarded_node, "buffered Confirm skipped the first quiet afterbeat")
	for expected_node: StringName in [&"n_afterbeat_02", &"n_afterbeat_03", &"n_afterbeat_04"]:
		_slice.arm_input_for_test()
		_accept_line()
		_expect(_slice.current_event_node_id() == expected_node, "quiet afterbeat omitted %s" % expected_node)
	_slice.arm_input_for_test()
	_accept_line()
	_expect(_slice.phase_id() == &"reward", "afterbeat did not reach Keepsake and Journal presentation")

	var completed := _kernel.state_snapshot() as GameState
	_expect(EVENT_ID in completed.completed_event_ids, "full slice did not record event completion")
	_expect(completed.inventory.keepsakes.has(&"item.keepsake.unpaired_cup"), "full slice did not grant the Keepsake")
	_expect(completed.journal.entries.has(&"journal.hkr.empty_cushion"), "full slice did not add the Journal observation")
	_expect(EVENT_ID in completed.journal.replay_event_ids, "full slice did not unlock Journal replay")

	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"day_end", "reward presentation did not close and save the day")
	var next_day := _kernel.state_snapshot() as GameState
	_expect(next_day.day == 2 and next_day.time_slot == &"morning", "day end did not advance to the next morning")
	_expect(next_day.journal.entries[&"journal.hkr.empty_cushion"].is_read, "viewed Journal observation was not marked read")
	var cards := _save_service.list_cards(&"p91") as Array[SaveCardMetadata]
	var card_ids: Array[StringName] = []
	for card: SaveCardMetadata in cards:
		card_ids.append(card.slot_id)
	for required: StringName in [&"manual_01", &"auto_day", &"auto_event", &"auto_mode"]:
		_expect(required in card_ids, "slice omitted required save card %s" % required)

	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"journal", "day end did not open the Journal")
	_slice.set_ui_scale_fixture(150)
	_expect(_slice.ui_scale_percent() == 150 and _slice.large_text_page_for_test() == 0, "Journal did not enter its 150% reflow layout")
	_slice.handle_semantic_action(GameInput.MOVE_DOWN)
	_expect(_slice.large_text_page_for_test() == 1, "150% Journal did not expose its next readable text page")
	_slice.handle_semantic_action(GameInput.MOVE_UP)
	_expect(_slice.large_text_page_for_test() == 0, "150% Journal did not return to its first readable text page")
	var before_replay := GameStateCodec.new().canonical_state(_kernel.state_snapshot())
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.is_replay() and _slice.current_event_node_id() == &"n003", "Journal did not start a read-only event replay")
	_drive_replay_loss_branch()
	_expect(_slice.phase_id() == &"replay_complete", "Journal replay did not reach its completion screen")
	_expect(GameStateCodec.new().canonical_state(_kernel.state_snapshot()) == before_replay, "Journal replay mutated the main save")
	var telemetry := _slice.telemetry_snapshot()
	_expect(bool(telemetry.get("completed", false)), "slice completion did not finalize local acceptance telemetry")
	_expect(FileAccess.file_exists(VerticalSliceTelemetry.DEFAULT_PATH), "slice completion did not write local acceptance telemetry")
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"journal", "replay completion did not return to the Journal")
	_slice.handle_semantic_action(GameInput.CANCEL)
	_expect(
		_slice.phase_id() == &"complete" and _completed_results.is_empty(),
		"Journal Finish did not stop on the explicit completion screen"
	)
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_expect(
		_completed_results.size() == 1 and _completed_results[0].result_tag == &"complete",
		"completion confirmation did not emit exactly one shell return"
	)

	_slice.queue_free()
	await process_frame
	_finish()


func _drive_replay_loss_branch() -> void:
	_accept_line()
	_slice.handle_semantic_action(GameInput.CONFIRM)
	_accept_line()
	_expect(_slice.submit_mode_result_for_test(&"loss"), "replay Tea loss could not return")
	_accept_line()
	_accept_line()
	_expect(_slice.submit_mode_result_for_test(&"loss"), "replay danmaku loss could not return")
	_accept_line()
	_accept_line()
	_expect(_slice.submit_mode_result_for_test(&"loss"), "replay fighter loss could not return")
	_accept_line()
	for _index: int in range(4):
		_slice.arm_input_for_test()
		_accept_line()


func _accept_line() -> void:
	_slice.handle_semantic_action(GameInput.CONFIRM)


func _prepare_services() -> void:
	_remove_tree(TEST_ROOT)
	var localization := root.get_node_or_null("LocalizationService")
	if localization != null:
		localization.set_locale(&"en", false)
	var accessibility := root.get_node_or_null("AccessibilityState")
	if accessibility != null:
		accessibility.apply_preset(AccessibilityState.Preset.STORY, false)
	_kernel = root.get_node_or_null("GameKernel")
	_kernel.clear_state()
	var created: CommandResult = _kernel.create_new_profile(&"p91", &"accessibility.story")
	_expect(created.is_success(), "test profile could not be created")
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
	print("M09 vertical slice integration: failures=%d" % _failures.size())
	for failure: String in _failures:
		printerr("FAIL: %s" % failure)
	quit(0 if _failures.is_empty() else 1)


const EVENT_ID: StringName = &"evt.hkr.empty_cushion"
