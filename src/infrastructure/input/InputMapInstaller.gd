class_name InputMapInstaller
extends RefCounted
## Installs and remaps the reviewed keyboard/controller defaults behind semantic actions.

enum OneHandedPreset {
	NONE,
	LEFT_HAND,
	RIGHT_HAND,
}

const DEADZONE := 0.35


static func install_defaults(should_reset: bool = false) -> void:
	for action: StringName in GameInput.ALL_ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, DEADZONE)
		elif should_reset:
			InputMap.action_erase_events(action)
	_add_direction(GameInput.MOVE_UP, [KEY_UP, KEY_W], JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0)
	_add_direction(GameInput.MOVE_DOWN, [KEY_DOWN, KEY_S], JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0)
	_add_direction(GameInput.MOVE_LEFT, [KEY_LEFT, KEY_A], JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_add_direction(GameInput.MOVE_RIGHT, [KEY_RIGHT, KEY_D], JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_add_keys_and_button(GameInput.CONFIRM, [KEY_Z, KEY_J, KEY_ENTER], JOY_BUTTON_A)
	_add_keys_and_button(GameInput.SHOT, [KEY_Z, KEY_J, KEY_ENTER], JOY_BUTTON_A)
	_add_keys_and_button(GameInput.LIGHT, [KEY_Z, KEY_J], JOY_BUTTON_A)
	_add_keys_and_button(GameInput.CANCEL, [KEY_X, KEY_K, KEY_ESCAPE], JOY_BUTTON_B)
	_add_keys_and_button(GameInput.FOCUS, [KEY_X, KEY_K], JOY_BUTTON_B)
	_add_keys_and_button(GameInput.GUARD, [KEY_SHIFT], JOY_BUTTON_LEFT_SHOULDER)
	_add_keys_and_button(GameInput.HEAVY, [KEY_X, KEY_K], JOY_BUTTON_B)
	_add_keys_and_button(GameInput.COMPANION, [KEY_C, KEY_L], JOY_BUTTON_X)
	_add_keys_and_button(GameInput.SKILL, [KEY_C, KEY_L], JOY_BUTTON_X)
	_add_keys_and_button(GameInput.BOMB, [KEY_V, KEY_I], JOY_BUTTON_Y)
	_add_keys_and_button(GameInput.SPELL, [KEY_V, KEY_I], JOY_BUTTON_Y)
	_add_keys_and_button(GameInput.JOURNAL, [KEY_TAB], JOY_BUTTON_BACK)
	_add_keys_and_button(GameInput.MAP, [KEY_M], JOY_BUTTON_DPAD_UP)
	_add_keys_and_button(GameInput.PAGE_LEFT, [KEY_Q], JOY_BUTTON_LEFT_SHOULDER)
	_add_keys_and_button(GameInput.PAGE_RIGHT, [KEY_E], JOY_BUTTON_RIGHT_SHOULDER)
	_add_keys_and_button(GameInput.PAUSE, [KEY_ESCAPE, KEY_P], JOY_BUTTON_START)
	_add_keys_and_button(GameInput.MENU, [KEY_ESCAPE, KEY_P], JOY_BUTTON_START)
	_add_keys_and_button(GameInput.ACCESSIBILITY, [KEY_F1], -1)


static func replace_binding(action: StringName, event: InputEvent) -> bool:
	if action not in GameInput.ALL_ACTIONS:
		return false
	if not InputMap.has_action(action):
		InputMap.add_action(action, DEADZONE)
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	return true


static func apply_one_handed_preset(preset: OneHandedPreset) -> void:
	install_defaults(true)
	match preset:
		OneHandedPreset.LEFT_HAND:
			_add_key(GameInput.CONFIRM, KEY_SPACE)
			_add_key(GameInput.CANCEL, KEY_SHIFT)
			_add_key(GameInput.COMPANION, KEY_Q)
			_add_key(GameInput.BOMB, KEY_E)
		OneHandedPreset.RIGHT_HAND:
			_add_key(GameInput.CONFIRM, KEY_KP_0)
			_add_key(GameInput.CANCEL, KEY_SHIFT)
			_add_key(GameInput.COMPANION, KEY_KP_1)
			_add_key(GameInput.BOMB, KEY_KP_2)
		_:
			pass


static func _add_direction(
	action: StringName,
	keycodes: Array,
	button_index: int,
	axis: int,
	axis_value: float
) -> void:
	_add_keys_and_button(action, keycodes, button_index)
	var motion := InputEventJoypadMotion.new()
	motion.axis = axis
	motion.axis_value = axis_value
	_add_event_once(action, motion)


static func _add_keys_and_button(action: StringName, keycodes: Array, button_index: int) -> void:
	for keycode: int in keycodes:
		_add_key(action, keycode)
	if button_index >= 0:
		var button := InputEventJoypadButton.new()
		button.button_index = button_index
		_add_event_once(action, button)


static func _add_key(action: StringName, keycode: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	_add_event_once(action, event)


static func _add_event_once(action: StringName, event: InputEvent) -> void:
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
