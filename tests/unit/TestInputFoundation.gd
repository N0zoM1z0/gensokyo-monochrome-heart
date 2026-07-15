class_name TestInputFoundation
extends RefCounted

const ACCESSIBILITY_STATE_SCRIPT := preload("res://src/autoload/AccessibilityState.gd")
const FOCUS_ROUTER_SCRIPT := preload("res://src/autoload/FocusRouter.gd")
const INPUT_GLYPH_SERVICE_SCRIPT := preload("res://src/autoload/InputGlyphService.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_validate_input_map(failures)
	_validate_glyph_hot_swap(failures)
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


func _validate_glyph_hot_swap(failures: Array[String]) -> void:
	var service := INPUT_GLYPH_SERVICE_SCRIPT.new()
	var controller_event := InputEventJoypadButton.new()
	controller_event.button_index = JOY_BUTTON_A
	service.observe_event(controller_event)
	if service.active_device != service.Device.CONTROLLER:
		failures.append("controller event did not hot-swap the active glyph family")
	if service.glyph_key(GameInput.CONFIRM) != &"input.glyph.pad.confirm":
		failures.append("controller confirm glyph key is incorrect")
	var keyboard_event := InputEventKey.new()
	keyboard_event.physical_keycode = KEY_Z
	service.observe_event(keyboard_event)
	if service.glyph_key(GameInput.CANCEL) != &"input.glyph.keyboard.cancel":
		failures.append("keyboard cancel glyph key is incorrect after hot-swap")
	service.free()


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
	state.apply_preset(state.Preset.LOW_MOTION, false)
	if not state.is_reduced_motion or not state.is_safe_flash:
		failures.append("Low Motion preset does not enable reduced motion and safe flash")
	state.apply_preset(state.Preset.ORIGINAL, false)
	if state.is_reduced_motion or state.has_simple_fighter_input or state.game_speed_percent != 100:
		failures.append("Original preset did not restore authored defaults")
	state.free()
