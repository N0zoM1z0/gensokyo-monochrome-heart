extends SceneTree
## Completes the slice through real keyboard/controller mappings under Story and Low Motion.

const SLICE_SCENE := preload("res://src/presentation/slice/VerticalSliceMode.tscn")
const TEST_ROOT := "user://tests/m09_accessibility_matrix"

var _failures: Array[String] = []
var _kernel: Node
var _save_service: Node
var _router := InputRouter.new()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_remove_tree(TEST_ROOT)
	_kernel = root.get_node_or_null("GameKernel")
	_save_service = root.get_node_or_null("SaveService")
	var scenarios := [
		{"id": "keyboard_story", "controller": false, "preset": AccessibilityState.Preset.STORY, "hand": InputMapInstaller.OneHandedPreset.NONE, "locale": &"en"},
		{"id": "controller_story", "controller": true, "preset": AccessibilityState.Preset.STORY, "hand": InputMapInstaller.OneHandedPreset.NONE, "locale": &"ja"},
		{"id": "keyboard_low_left", "controller": false, "preset": AccessibilityState.Preset.LOW_MOTION, "hand": InputMapInstaller.OneHandedPreset.LEFT_HAND, "locale": &"en"},
		{"id": "controller_low_right", "controller": true, "preset": AccessibilityState.Preset.LOW_MOTION, "hand": InputMapInstaller.OneHandedPreset.RIGHT_HAND, "locale": &"ja", "comfort_all": true},
	]
	for index: int in range(scenarios.size()):
		await _run_scenario(scenarios[index], index)
	_remove_tree(TEST_ROOT)
	_router.free()
	print("M09 accessibility route matrix: scenarios=%d failures=%d" % [scenarios.size(), _failures.size()])
	for failure: String in _failures:
		printerr("FAIL: %s" % failure)
	quit(0 if _failures.is_empty() else 1)


func _run_scenario(scenario: Dictionary, index: int) -> void:
	var scenario_id := String(scenario.id)
	var profile_id := StringName("p%d" % (70 + index))
	_prepare_scenario(scenario, profile_id)
	_validate_device_contract(bool(scenario.controller), scenario_id)
	var slice := SLICE_SCENE.instantiate() as VerticalSliceMode
	var completions: Array[ModeResult] = []
	slice.mode_completed.connect(func(result: ModeResult) -> void: completions.append(result))
	root.add_child(slice)
	await process_frame
	slice.set_instant_text_for_test(true)
	_press(slice, GameInput.CONFIRM, scenario)
	_press(slice, GameInput.CONFIRM, scenario)
	_expect(slice.phase_id() == &"exploration", scenario_id, "did not reach exploration")
	_expect(slice.complete_exploration_for_test(), scenario_id, "could not complete exploration")
	_press(slice, GameInput.CONFIRM, scenario)
	_press(slice, GameInput.CONFIRM, scenario)
	_press(slice, GameInput.CONFIRM, scenario)
	_expect(slice.phase_id() == &"mini.shrine.tea_temperature", scenario_id, "did not reach Tea Temperature")
	_expect(slice.submit_mode_result_for_test(&"loss"), scenario_id, "could not submit Tea loss")
	_press(slice, GameInput.CONFIRM, scenario)
	_press(slice, GameInput.CONFIRM, scenario)
	_expect(slice.phase_id() == &"danmaku.hkr.boundary_stain", scenario_id, "did not reach Boundary Stain")
	var danmaku := slice.active_child_mode() as BoundaryStainMode
	if int(scenario.preset) == AccessibilityState.Preset.LOW_MOTION:
		_expect(danmaku != null and bool(danmaku.capture_debug_state().get("no_flash", false)), scenario_id, "Low Motion did not reach danmaku no-flash presentation")
	else:
		_expect(danmaku != null and danmaku.assist_settings.safe_lane_preview, scenario_id, "Story did not retain danmaku assists")
	_expect(slice.submit_mode_result_for_test(&"assist_clear"), scenario_id, "could not submit Assist Clear")
	_press(slice, GameInput.CONFIRM, scenario)
	_press(slice, GameInput.CONFIRM, scenario)
	_expect(slice.phase_id() == &"duel.hkr.spell_card_terms", scenario_id, "did not reach the compact duel")
	var fighter := slice.active_child_mode() as CompactFighterMode
	if int(scenario.preset) == AccessibilityState.Preset.LOW_MOTION:
		_expect(fighter != null and bool(fighter.capture_debug_state().get("no_flash", false)), scenario_id, "Low Motion did not reach fighter no-flash presentation")
	else:
		_expect(fighter != null and fighter.assist_settings.simple_inputs, scenario_id, "Story did not retain fighter assists")
	_expect(slice.submit_mode_result_for_test(&"loss"), scenario_id, "could not submit fighter loss")
	_press(slice, GameInput.CONFIRM, scenario)
	_expect(slice.phase_id() == &"afterbeat", scenario_id, "did not reach the quiet afterbeat")
	for _line: int in range(4):
		slice.arm_input_for_test()
		_press(slice, GameInput.CONFIRM, scenario)
	_expect(slice.phase_id() == &"reward", scenario_id, "did not reach reward presentation")
	_press(slice, GameInput.CONFIRM, scenario)
	_press(slice, GameInput.CONFIRM, scenario)
	_expect(slice.phase_id() == &"journal", scenario_id, "did not reach Journal")
	_press(slice, GameInput.CANCEL, scenario)
	_expect(slice.phase_id() == &"complete", scenario_id, "did not reach explicit completion")
	_press(slice, GameInput.CONFIRM, scenario)
	var state := _kernel.state_snapshot() as GameState
	_expect(completions.size() == 1, scenario_id, "did not emit exactly one completion")
	_expect(state != null and &"evt.hkr.empty_cushion" in state.completed_event_ids, scenario_id, "did not persist event completion")
	slice.queue_free()
	await process_frame


func _prepare_scenario(scenario: Dictionary, profile_id: StringName) -> void:
	_kernel.clear_state()
	var accessibility := root.get_node_or_null("AccessibilityState")
	accessibility.apply_preset(int(scenario.preset) as AccessibilityState.Preset, false)
	accessibility.set_one_handed_preset(int(scenario.hand), false)
	for filter_id: StringName in AccessibilityState.COMFORT_FILTER_IDS:
		accessibility.set_comfort_filter(filter_id, bool(scenario.get("comfort_all", false)), false)
	var localization := root.get_node_or_null("LocalizationService")
	localization.set_locale(StringName(scenario.locale), false)
	var created: CommandResult = _kernel.create_new_profile(profile_id, accessibility.save_profile_id())
	if not created.is_success():
		_failures.append("%s: could not create test profile" % String(scenario.id))
	_save_service.configure_for_test(_kernel, "%s/%s" % [TEST_ROOT, scenario.id])
	var glyph_service := root.get_node_or_null("InputGlyphService")
	if bool(scenario.controller):
		var event := InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_A
		glyph_service.observe_event(event)
	else:
		var event := InputEventKey.new()
		event.physical_keycode = _keyboard_key(GameInput.CONFIRM)
		glyph_service.observe_event(event)


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
		_failures.append("%s: %s mapping resolved to %s" % [scenario.id, requested_action, resolved])
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
			_failures.append("%s: %s has no %s binding" % [scenario_id, action, "controller" if controller else "keyboard"])


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
