class_name TestInputFoundation
extends RefCounted

const ACCESSIBILITY_STATE_SCRIPT := preload("res://src/autoload/AccessibilityState.gd")
const FOCUS_ROUTER_SCRIPT := preload("res://src/autoload/FocusRouter.gd")
const INPUT_GLYPH_SERVICE_SCRIPT := preload("res://src/autoload/InputGlyphService.gd")
const UI_SCALE_POLICY := preload("res://src/presentation/ui/UiScalePolicy.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_validate_input_map(failures)
	_validate_fighter_keyboard_controller_bindings(failures)
	_validate_glyph_hot_swap(failures)
	_validate_contextual_action_arbitration(failures)
	_validate_focus_stack(failures)
	_validate_accessibility_presets(failures)
	return failures


func _validate_input_map(failures: Array[String]) -> void:
	InputMapInstaller.install_defaults(true)
	for action: StringName in GameInput.ALL_ACTIONS:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			failures.append("semantic action lacks a default binding: %s" % action)
	var replacement := InputEventKey.new()
	replacement.physical_keycode = KEY_SPACE
	if not InputMapInstaller.replace_binding(GameInput.CONFIRM, replacement):
		failures.append("confirm action could not be remapped")
	elif InputMap.action_get_events(GameInput.CONFIRM).size() != 1:
		failures.append("confirm remap did not replace prior bindings")
	InputMapInstaller.install_defaults(true)


func _validate_fighter_keyboard_controller_bindings(failures: Array[String]) -> void:
	InputMapInstaller.install_defaults(true)
	for action: StringName in [
		GameInput.LIGHT,
		GameInput.HEAVY,
		GameInput.SKILL,
		GameInput.SPELL,
		GameInput.GUARD,
	]:
		var has_keyboard := false
		var has_controller := false
		for event: InputEvent in InputMap.action_get_events(action):
			has_keyboard = has_keyboard or event is InputEventKey
			has_controller = has_controller or event is InputEventJoypadButton
		if not has_keyboard:
			failures.append("fighter action lacks a keyboard binding: %s" % action)
		if not has_controller:
			failures.append("fighter action lacks a controller binding: %s" % action)


func _validate_glyph_hot_swap(failures: Array[String]) -> void:
	var service := INPUT_GLYPH_SERVICE_SCRIPT.new()
	var controller_event := InputEventJoypadButton.new()
	controller_event.button_index = JOY_BUTTON_A
	service.observe_event(controller_event)
	if service.active_device != service.Device.CONTROLLER:
		failures.append("controller event did not hot-swap the active glyph family")
	if service.glyph_key(GameInput.CONFIRM) != &"input.glyph.pad.confirm":
		failures.append("controller confirm glyph key is incorrect")
	if service.binding_text(GameInput.CONFIRM) != "[A]":
		failures.append("controller hint did not show the current Confirm binding")
	var keyboard_event := InputEventKey.new()
	keyboard_event.physical_keycode = KEY_Z
	service.observe_event(keyboard_event)
	if service.glyph_key(GameInput.CANCEL) != &"input.glyph.keyboard.cancel":
		failures.append("keyboard cancel glyph key is incorrect after hot-swap")
	if service.binding_text(GameInput.CANCEL) != "[X]":
		failures.append("keyboard hint did not show the current Cancel binding")
	InputMapInstaller.apply_one_handed_preset(InputMapInstaller.OneHandedPreset.LEFT_HAND)
	if service.binding_text(GameInput.CONFIRM) != "[SPACE]" or service.binding_text(GameInput.SPELL) != "[R]":
		failures.append("one-handed hint did not follow the active remapped binding")
	if service.binding_text(GameInput.PAUSE) != "[ESCAPE]" or service.binding_text(GameInput.MOVE_LEFT) != "[A]":
		failures.append("one-handed hint did not prefer the preset contract over duplicate defaults")
	InputMapInstaller.install_defaults(true)
	service.free()


func _validate_contextual_action_arbitration(failures: Array[String]) -> void:
	InputMapInstaller.install_defaults(true)
	var router := InputRouter.new()
	var priorities: Array = [GameInput.FOCUS, GameInput.CANCEL, GameInput.HEAVY]
	router.set_action_candidate_resolver(func(candidates: Array[StringName]) -> StringName:
		return GameInput.first_matching(candidates, priorities)
	)
	var x_key := InputEventKey.new()
	x_key.physical_keycode = KEY_X
	x_key.pressed = true
	var focus_actions := router.resolve_event_actions_for_test(x_key)
	if focus_actions != [GameInput.FOCUS]:
		failures.append("shared X binding emitted more than contextual Focus: %s" % [focus_actions])
	priorities = [GameInput.HEAVY, GameInput.CANCEL, GameInput.FOCUS]
	router.set_action_candidate_resolver(func(candidates: Array[StringName]) -> StringName:
		return GameInput.first_matching(candidates, priorities)
	)
	var b_button := InputEventJoypadButton.new()
	b_button.button_index = JOY_BUTTON_B
	b_button.pressed = true
	var heavy_actions := router.resolve_event_actions_for_test(b_button)
	if heavy_actions != [GameInput.HEAVY]:
		failures.append("shared controller B binding emitted more than contextual Heavy: %s" % [heavy_actions])
	priorities = [GameInput.PAUSE, GameInput.CANCEL, GameInput.MENU]
	router.set_action_candidate_resolver(func(candidates: Array[StringName]) -> StringName:
		return GameInput.first_matching(candidates, priorities)
	)
	var escape_key := InputEventKey.new()
	escape_key.physical_keycode = KEY_ESCAPE
	escape_key.pressed = true
	var pause_actions := router.resolve_event_actions_for_test(escape_key)
	if pause_actions != [GameInput.PAUSE]:
		failures.append("shared Escape binding emitted more than contextual Pause: %s" % [pause_actions])
	router.free()


func _validate_focus_stack(failures: Array[String]) -> void:
	var router := FOCUS_ROUTER_SCRIPT.new()
	router.push_prior_focus(&"title.options")
	router.push_prior_focus(&"pause.resume")
	if router.pop_prior_focus() != &"pause.resume" or router.pop_prior_focus() != &"title.options":
		failures.append("nested modal focus was not restored in LIFO order")
	if router.pop_prior_focus() != &"":
		failures.append("empty focus stack did not return an empty stable ID")
	router.free()


func _validate_accessibility_presets(failures: Array[String]) -> void:
	var state := ACCESSIBILITY_STATE_SCRIPT.new()
	state.apply_preset(state.Preset.STORY, false)
	if not state.has_simple_fighter_input or not state.has_unlimited_story_retries or state.bullet_density_percent != 70:
		failures.append("Story accessibility preset does not apply its reviewed assists")
	state.set_ui_scale_percent(150, false)
	if state.preset != state.Preset.STORY or not state.has_simple_fighter_input:
		failures.append("UI scale changed the active gameplay accessibility preset")
	state.apply_preset(state.Preset.LOW_MOTION, false)
	if not state.is_reduced_motion or not state.is_safe_flash:
		failures.append("Low Motion preset does not enable reduced motion and safe flash")
	state.apply_preset(state.Preset.ORIGINAL, false)
	if state.is_reduced_motion or state.has_simple_fighter_input or state.game_speed_percent != 100:
		failures.append("Original preset did not restore authored defaults")
	state.set_ui_scale_percent(149, false)
	if state.ui_scale_percent != 150 or UI_SCALE_POLICY.pixels(8, state.ui_scale_percent) != 12:
		failures.append("150% UI scale did not normalize or produce integer pixel sizes")
	if UI_SCALE_POLICY.next(150, 1) != 100 or UI_SCALE_POLICY.next(100, -1) != 150:
		failures.append("UI scale choices did not wrap across the reviewed discrete values")
	state.is_first_run = true
	state.restore_presentation(false, false, state.Preset.ORIGINAL, true, false, 125)
	if not state.is_first_run or state.ui_scale_percent != 125:
		failures.append("cancel-style accessibility restore consumed the first-run preset")
	state.free()
