extends SceneTree
## Drives Tomorrow's Headline through the reusable day shell and read-only replay.

const SLICE_SCENE := preload("res://src/presentation/slice/YoukaiMountainSliceMode.tscn")
const TEST_ROOT := "user://tests/m13_mountain_vertical_slice"
const EVENT_ID: StringName = &"evt.mtn.tomorrows_headline"
const JOURNAL_ID: StringName = &"journal.mtn.tomorrows_headline"
const KEEPSAKE_ID: StringName = &"item.keepsake.unprinted_caption"
const REGIONAL_CAST: Array[StringName] = [
	&"char.aya_shameimaru",
	&"char.hatate_himekaidou",
	&"char.momiji_inubashiri",
	&"char.nitori_kawashiro",
	&"char.sanae_kochiya",
]

var _failures: Array[String] = []
var _slice: VerticalSliceMode
var _kernel: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_prepare_services()
	var definition := EventSliceDefinitionFactory.build(&"youkai_mountain")
	_expect(definition.visible_character_ids == REGIONAL_CAST, "mountain composition omitted a regional cast context")
	_expect(
		EventSliceDefinitionFactory.for_event(EVENT_ID).component_id == &"youkai_mountain",
		"event lookup did not resolve the mountain composition"
	)
	_slice = SLICE_SCENE.instantiate() as VerticalSliceMode
	root.add_child(_slice)
	await process_frame
	_slice.set_instant_text_for_test(true)
	_expect(_slice.slice_component_id() == &"youkai_mountain", "mountain scene selected the wrong slice component")
	_expect(_slice.phase_id() == &"invitation", "mountain day did not begin with tomorrow's newspaper")

	_confirm()
	_expect(_slice.phase_id() == &"world_map", "newspaper did not open the world map")
	_confirm()
	_expect(_slice.phase_id() == &"exploration", "Wind Ridge travel did not enter exploration")
	_expect(_kernel.state_snapshot().current_location == &"loc.youkai_mountain", "mountain travel was not persisted")
	_expect(_slice.complete_exploration_for_test(), "future paper and intact rail could not trigger Aya")
	_expect(_slice.current_event_node_id() == &"n003", "mountain exploration did not reach Aya's report")
	_expect(_slice.current_stage_component() == &"mountain_report", "Aya's report did not use the raised-camera stage")

	_confirm()
	_expect(_slice.current_event_node_id() == &"n004", "Aya's report omitted the future plate evidence")
	_confirm()
	_expect(_slice.phase_id() == &"choice", "Aya's evidence did not reach the publication boundary")
	_confirm()
	_expect(_slice.current_event_node_id() == &"n_direct_line", "Direct tone did not reach Aya's response")
	_expect(_slice.current_stage_component() == &"mountain_boundary", "boundary response did not close the report frame")
	_confirm()
	_expect(_slice.current_event_node_id() == &"n_photo_origin", "boundary response omitted the causal route setup")
	_expect(_slice.current_stage_component() == &"mountain_route", "causal setup did not show the converging routes")
	_confirm()

	_expect(_slice.phase_id() == &"danmaku.mtn.tomorrows_headline", "causal setup did not instantiate Wind-Frame")
	var wind_frame := _slice.active_child_mode() as BoundaryStainMode
	_expect(
		wind_frame != null
		and wind_frame.mode_context.mode_id == &"danmaku.mtn.tomorrows_headline"
		and wind_frame.assist_settings.safe_lane_preview
		and wind_frame.assist_settings.auto_bomb,
		"Story preset did not reach the composed Wind-Frame mode"
	)
	_expect(
		_slice.submit_mode_result_for_test(&"clear", 2, [&"strategy.photo_frame", &"photo.capture.composed"]),
		"Wind-Frame clear could not return to Aya"
	)
	_expect(_slice.current_event_node_id() == &"n_danmaku_clear", "Wind-Frame clear reached the wrong response")
	_expect(_slice.current_stage_component() == &"mountain_new_frame", "clear response omitted the unpredicted frame")
	_confirm()

	_expect(_slice.phase_id() == &"afterbeat" and _slice.current_event_node_id() == &"n_after_01", "clear response omitted the patrol reveal")
	_expect(_slice.current_stage_component() == &"mountain_patrol", "patrol reveal did not show the closed route")
	_slice.arm_input_for_test()
	_confirm()
	_expect(_slice.current_event_node_id() == &"n_after_02", "patrol reveal omitted Aya's publication decision")
	_expect(_slice.current_stage_component() == &"mountain_camera_lowered", "Aya's decision did not lower the camera")
	_slice.arm_input_for_test()
	_confirm()
	_expect(_slice.phase_id() == &"reward", "camera-lowered afterbeat did not complete the event")

	var completed := _kernel.state_snapshot() as GameState
	_expect(EVENT_ID in completed.completed_event_ids, "mountain slice did not record event completion")
	_expect(completed.inventory.keepsakes.has(KEEPSAKE_ID), "mountain slice did not grant the unprinted caption")
	_expect(completed.journal.entries.has(JOURNAL_ID), "mountain slice did not add the caption Journal entry")
	_expect(EVENT_ID in completed.journal.replay_event_ids, "mountain slice did not unlock read-only replay")
	_expect(completed.rumors.has(&"rumor.mtn.tomorrows_headline"), "mountain slice did not add the withheld-headline rumor")
	_expect(
		completed.journal.entries.has(JOURNAL_ID)
		and &"strategy.photo_frame" in completed.journal.entries[JOURNAL_ID].tags,
		"mountain Journal did not retain the locale-free photo-frame strategy"
	)
	_expect(
		RecordedStrategyLedger.ranked_tags(completed) == [&"strategy.photo_frame"],
		"mountain completion did not expose a strategy to the Archive ledger"
	)

	_confirm()
	_expect(_slice.phase_id() == &"day_end", "mountain reward did not save and close the day")
	var day_end := _kernel.state_snapshot() as GameState
	var retold := day_end.rumors.get(&"rumor.mtn.tomorrows_headline") as RumorState
	_expect(
		retold != null
		and retold.claim_key == &"rumor.mtn.tomorrows_headline.reporter_prevented_accident"
		and retold.reliability_milli == 610
		and retold.privacy == &"public"
		and retold.mutation_count == 1
		and retold.confidence_label() == &"reported",
		"day end did not mutate the withheld headline into its public retelling"
	)
	for region_id: StringName in [&"loc.hakurei_shrine", &"loc.scarlet_devil_mansion"]:
		_expect(
			day_end.regions[region_id].condition_id == &"region.rumor.future_headline_arrived",
			"headline retelling did not reach %s" % region_id
		)
	_confirm()
	_expect(_slice.phase_id() == &"journal", "mountain day end did not open the Journal")
	var before_replay := GameStateCodec.new().canonical_state(_kernel.state_snapshot())
	_confirm()
	_expect(_slice.is_replay() and _slice.current_event_node_id() == &"n003", "Journal did not start mountain replay")
	_drive_loss_replay()
	_expect(_slice.phase_id() == &"replay_complete", "mountain replay did not reach read-only completion")
	_expect(GameStateCodec.new().canonical_state(_kernel.state_snapshot()) == before_replay, "mountain replay mutated the active save")

	_slice.queue_free()
	await process_frame
	_finish()


func _drive_loss_replay() -> void:
	_confirm()
	_confirm()
	_confirm()
	_confirm()
	_confirm()
	_expect(_slice.submit_mode_result_for_test(&"loss"), "replay Wind-Frame loss could not return")
	_confirm()
	_slice.arm_input_for_test()
	_confirm()
	_slice.arm_input_for_test()
	_confirm()


func _confirm() -> void:
	_slice.handle_semantic_action(GameInput.CONFIRM)


func _prepare_services() -> void:
	_remove_tree(TEST_ROOT)
	var localization := root.get_node_or_null("LocalizationService")
	localization.set_locale(&"en", false)
	var accessibility := root.get_node_or_null("AccessibilityState")
	accessibility.apply_preset(AccessibilityState.Preset.STORY, false)
	_kernel = root.get_node_or_null("GameKernel")
	_kernel.clear_state()
	var created: CommandResult = _kernel.create_new_profile(&"p132", &"accessibility.story")
	_expect(created.is_success(), "M13 mountain test profile could not be created")
	var save_service := root.get_node_or_null("SaveService")
	save_service.configure_for_test(_kernel, TEST_ROOT)


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
	print("M13 Youkai Mountain vertical slice integration: failures=%d" % _failures.size())
	for failure: String in _failures:
		printerr("FAIL: %s" % failure)
	quit(0 if _failures.is_empty() else 1)
