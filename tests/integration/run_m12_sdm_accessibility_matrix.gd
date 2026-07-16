extends SceneTree
## Completes the SDM slice through mapped controller and one-handed Low Motion input.

const SLICE_SCENE := preload("res://src/presentation/slice/ScarletDevilMansionSliceMode.tscn")
const TEST_ROOT := "user://tests/m12_sdm_accessibility"

var _failures: Array[String] = []
var _kernel: Node
var _save_service: Node
var _router := InputRouter.new()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_remove_tree(TEST_ROOT)
	_kernel = root.get_node("GameKernel")
	_save_service = root.get_node("SaveService")
	var scenarios := [
		{"id": "controller_story_ja", "controller": true, "preset": AccessibilityState.Preset.STORY, "hand": InputMapInstaller.OneHandedPreset.NONE, "locale": &"ja"},
		{"id": "keyboard_low_left_en", "controller": false, "preset": AccessibilityState.Preset.LOW_MOTION, "hand": InputMapInstaller.OneHandedPreset.LEFT_HAND, "locale": &"en"},
	]
	for index: int in range(scenarios.size()):
		await _run_scenario(scenarios[index], index)
	_remove_tree(TEST_ROOT)
	_router.free()
	print("M12 SDM accessibility matrix: scenarios=%d failures=%d" % [scenarios.size(), _failures.size()])
	for failure: String in _failures:
		printerr("FAIL: %s" % failure)
	quit(0 if _failures.is_empty() else 1)


func _run_scenario(scenario: Dictionary, index: int) -> void:
	var scenario_id := String(scenario.id)
	_prepare_scenario(scenario, StringName("p%d" % (123 + index)))
	_validate_device_contract(bool(scenario.controller), scenario_id)
	var slice := SLICE_SCENE.instantiate() as VerticalSliceMode
	var completions: Array[ModeResult] = []
	slice.mode_completed.connect(func(result: ModeResult) -> void: completions.append(result))
	root.add_child(slice)
	await process_frame
	slice.set_instant_text_for_test(true)
	_press(slice, GameInput.CONFIRM, scenario)
	_press(slice, GameInput.CONFIRM, scenario)
	_expect(slice.phase_id() == &"exploration", scenario_id, "did not reach mansion exploration")
	_expect(slice.complete_exploration_for_test(), scenario_id, "could not complete clock/tray exploration")
	_press(slice, GameInput.CONFIRM, scenario)
	_press(slice, GameInput.CONFIRM, scenario)
	_press(slice, GameInput.CONFIRM, scenario)
	_expect(slice.phase_id() == &"mini.sdm.time_grid_service", scenario_id, "did not reach Time Grid")
	var time_grid := slice.active_child_mode() as TimeGridServiceMode
	if int(scenario.preset) == AccessibilityState.Preset.STORY:
		_expect(time_grid != null and time_grid.assist_settings.no_timer, scenario_id, "Story did not inject Time Grid assists")
	else:
		_expect(time_grid != null and time_grid.resolved_profile_id() != &"", scenario_id, "Low Motion did not build Time Grid")
	_expect(slice.submit_mode_result_for_test(&"loss"), scenario_id, "could not submit Time Grid loss")
	_press(slice, GameInput.CONFIRM, scenario)
	_expect(slice.phase_id() == &"danmaku.sdm.missing_minute_knives", scenario_id, "did not reach knife escalation")
	var knives := slice.active_child_mode() as BoundaryStainMode
	if int(scenario.preset) == AccessibilityState.Preset.LOW_MOTION:
		_expect(knives != null and bool(knives.capture_debug_state().get("no_flash", false)), scenario_id, "Low Motion did not retain no-flash knives")
	else:
		_expect(knives != null and knives.assist_settings.safe_lane_preview, scenario_id, "Story did not retain knife assists")
	_expect(slice.submit_mode_result_for_test(&"assist_clear"), scenario_id, "could not submit knife assist clear")
	_press(slice, GameInput.CONFIRM, scenario)
	_expect(slice.phase_id() == &"afterbeat", scenario_id, "did not reach missing-minute afterbeat")
	for _afterbeat_index: int in range(2):
		slice.arm_input_for_test()
		_press(slice, GameInput.CONFIRM, scenario)
	for _followup_index: int in range(3):
		_press(slice, GameInput.CONFIRM, scenario)
	_expect(slice.phase_id() == &"reward", scenario_id, "did not reach checklist reward")
	_press(slice, GameInput.CONFIRM, scenario)
	_press(slice, GameInput.CONFIRM, scenario)
	_expect(slice.phase_id() == &"journal", scenario_id, "did not reach missing-minute Journal")
	_press(slice, GameInput.CANCEL, scenario)
	_expect(slice.phase_id() == &"complete", scenario_id, "did not reach explicit completion")
	_press(slice, GameInput.CONFIRM, scenario)
	var state := _kernel.state_snapshot() as GameState
	_expect(completions.size() == 1, scenario_id, "did not emit exactly one completion")
	_expect(state != null and &"evt.sdm.late_by_three_minutes" in state.completed_event_ids, scenario_id, "did not persist SDM completion")
	slice.queue_free()
	await process_frame


func _prepare_scenario(scenario: Dictionary, profile_id: StringName) -> void:
	_kernel.clear_state()
	var accessibility := root.get_node("AccessibilityState")
	accessibility.apply_preset(int(scenario.preset) as AccessibilityState.Preset, false)
	accessibility.set_one_handed_preset(int(scenario.hand), false)
	root.get_node("LocalizationService").set_locale(StringName(scenario.locale), false)
	var created: CommandResult = _kernel.create_new_profile(profile_id, accessibility.save_profile_id())
	if not created.is_success():
		_failures.append("%s: could not create profile" % scenario.id)
	_save_service.configure_for_test(_kernel, "%s/%s" % [TEST_ROOT, scenario.id])
	var glyph_service := root.get_node("InputGlyphService")
	if bool(scenario.controller):
		var button := InputEventJoypadButton.new()
		button.button_index = JOY_BUTTON_A
		glyph_service.observe_event(button)
	else:
		var key := InputEventKey.new()
		key.physical_keycode = _keyboard_key(GameInput.CONFIRM)
		glyph_service.observe_event(key)


func _press(slice: VerticalSliceMode, requested_action: StringName, scenario: Dictionary) -> void:
	var event: InputEvent
	if bool(scenario.controller):
		var button := InputEventJoypadButton.new()
		button.button_index = JOY_BUTTON_A if requested_action == GameInput.CONFIRM else JOY_BUTTON_B
		button.pressed = true
		event = button
	else:
		var key := InputEventKey.new()
		key.physical_keycode = _keyboard_key(requested_action)
		key.pressed = true
		event = key
	_router.set_action_candidate_resolver(slice.resolve_input_candidates)
	var resolved := _router.resolve_event_actions_for_test(event)
	if resolved.size() != 1:
		_failures.append("%s: %s resolved to %s" % [scenario.id, requested_action, resolved])
		return
	slice.handle_semantic_action(resolved[0])


func _keyboard_key(action: StringName) -> Key:
	var preferred := InputMapInstaller.preferred_one_handed_keycode(action)
	if preferred != KEY_NONE:
		return preferred
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			return (event as InputEventKey).physical_keycode
	return KEY_NONE


func _validate_device_contract(controller: bool, scenario_id: String) -> void:
	for action: StringName in GameInput.ALL_ACTIONS:
		if action == GameInput.ACCESSIBILITY:
			continue
		var has_binding := false
		for event: InputEvent in InputMap.action_get_events(action):
			has_binding = has_binding or (event is InputEventJoypadButton if controller else event is InputEventKey)
		if not has_binding:
			_failures.append("%s: %s has no mapped binding" % [scenario_id, action])


func _expect(condition: bool, scenario_id: String, message: String) -> void:
	if not condition:
		_failures.append("%s: %s" % [scenario_id, message])


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
