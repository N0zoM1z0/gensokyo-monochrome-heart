class_name InputMapInstaller
extends RefCounted
## Installs and remaps the reviewed keyboard/controller defaults behind semantic actions.

enum OneHandedPreset {
	NONE,
	LEFT_HAND,
	RIGHT_HAND,
}

const DEADZONE := 0.35
static var active_one_handed_preset: OneHandedPreset = OneHandedPreset.NONE


static func install_defaults(should_reset: bool = false) -> void:
	if should_reset:
		active_one_handed_preset = OneHandedPreset.NONE
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
	active_one_handed_preset = preset
	match preset:
		OneHandedPreset.LEFT_HAND:
			_add_key(GameInput.CONFIRM, KEY_SPACE)
			_add_key(GameInput.SHOT, KEY_SPACE)
			_add_key(GameInput.LIGHT, KEY_SPACE)
			_add_key(GameInput.CANCEL, KEY_QUOTELEFT)
			_add_key(GameInput.FOCUS, KEY_Q)
			_add_key(GameInput.HEAVY, KEY_Q)
			_add_key(GameInput.COMPANION, KEY_E)
			_add_key(GameInput.SKILL, KEY_E)
			_add_key(GameInput.BOMB, KEY_R)
			_add_key(GameInput.SPELL, KEY_R)
			_add_key(GameInput.GUARD, KEY_SHIFT)
			_add_key(GameInput.JOURNAL, KEY_TAB)
			_add_key(GameInput.MAP, KEY_F)
			_add_key(GameInput.PAGE_LEFT, KEY_1)
			_add_key(GameInput.PAGE_RIGHT, KEY_2)
			_add_key(GameInput.PAUSE, KEY_ESCAPE)
			_add_key(GameInput.MENU, KEY_ESCAPE)
		OneHandedPreset.RIGHT_HAND:
			_add_key(GameInput.CONFIRM, KEY_KP_0)
			_add_key(GameInput.SHOT, KEY_KP_0)
			_add_key(GameInput.LIGHT, KEY_KP_0)
			_add_key(GameInput.CANCEL, KEY_KP_PERIOD)
			_add_key(GameInput.FOCUS, KEY_KP_1)
			_add_key(GameInput.HEAVY, KEY_KP_1)
			_add_key(GameInput.COMPANION, KEY_KP_2)
			_add_key(GameInput.SKILL, KEY_KP_2)
			_add_key(GameInput.BOMB, KEY_KP_3)
			_add_key(GameInput.SPELL, KEY_KP_3)
			_add_key(GameInput.GUARD, KEY_KP_ADD)
			_add_key(GameInput.JOURNAL, KEY_KP_7)
			_add_key(GameInput.MAP, KEY_KP_9)
			_add_key(GameInput.PAGE_LEFT, KEY_KP_4)
			_add_key(GameInput.PAGE_RIGHT, KEY_KP_6)
			_add_key(GameInput.PAUSE, KEY_KP_SUBTRACT)
			_add_key(GameInput.MENU, KEY_KP_SUBTRACT)
		_:
			pass


static func preferred_one_handed_keycode(action: StringName) -> Key:
	match active_one_handed_preset:
		OneHandedPreset.LEFT_HAND:
			var left_bindings: Dictionary[StringName, Key] = {
				GameInput.MOVE_UP: KEY_W, GameInput.MOVE_DOWN: KEY_S,
				GameInput.MOVE_LEFT: KEY_A, GameInput.MOVE_RIGHT: KEY_D,
				GameInput.CONFIRM: KEY_SPACE, GameInput.SHOT: KEY_SPACE, GameInput.LIGHT: KEY_SPACE,
				GameInput.CANCEL: KEY_QUOTELEFT, GameInput.FOCUS: KEY_Q, GameInput.HEAVY: KEY_Q,
				GameInput.COMPANION: KEY_E, GameInput.SKILL: KEY_E,
				GameInput.BOMB: KEY_R, GameInput.SPELL: KEY_R,
				GameInput.GUARD: KEY_SHIFT, GameInput.JOURNAL: KEY_TAB,
				GameInput.MAP: KEY_F, GameInput.PAGE_LEFT: KEY_1, GameInput.PAGE_RIGHT: KEY_2,
				GameInput.PAUSE: KEY_ESCAPE, GameInput.MENU: KEY_ESCAPE,
			}
			return left_bindings.get(action, KEY_NONE)
		OneHandedPreset.RIGHT_HAND:
			var right_bindings: Dictionary[StringName, Key] = {
				GameInput.MOVE_UP: KEY_UP, GameInput.MOVE_DOWN: KEY_DOWN,
				GameInput.MOVE_LEFT: KEY_LEFT, GameInput.MOVE_RIGHT: KEY_RIGHT,
				GameInput.CONFIRM: KEY_KP_0, GameInput.SHOT: KEY_KP_0, GameInput.LIGHT: KEY_KP_0,
				GameInput.CANCEL: KEY_KP_PERIOD, GameInput.FOCUS: KEY_KP_1, GameInput.HEAVY: KEY_KP_1,
				GameInput.COMPANION: KEY_KP_2, GameInput.SKILL: KEY_KP_2,
				GameInput.BOMB: KEY_KP_3, GameInput.SPELL: KEY_KP_3,
				GameInput.GUARD: KEY_KP_ADD, GameInput.JOURNAL: KEY_KP_7,
				GameInput.MAP: KEY_KP_9, GameInput.PAGE_LEFT: KEY_KP_4, GameInput.PAGE_RIGHT: KEY_KP_6,
				GameInput.PAUSE: KEY_KP_SUBTRACT, GameInput.MENU: KEY_KP_SUBTRACT,
			}
			return right_bindings.get(action, KEY_NONE)
	return KEY_NONE


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
