extends Node
## Tracks the active input family and resolves semantic actions to localized glyph keys.

signal active_device_changed(device: Device)

enum Device {
	KEYBOARD,
	CONTROLLER,
	POINTER,
}

var active_device: Device = Device.KEYBOARD


func observe_event(event: InputEvent) -> void:
	var next_device := _device_for_event(event)
	if next_device == active_device:
		return
	active_device = next_device
	active_device_changed.emit(active_device)


func glyph_key(action: StringName) -> StringName:
	var action_family := _action_family(action)
	match active_device:
		Device.CONTROLLER:
			return StringName("input.glyph.pad.%s" % action_family)
		Device.POINTER:
			return StringName("input.glyph.pointer.%s" % action_family)
		_:
			return StringName("input.glyph.keyboard.%s" % action_family)


func binding_text(action: StringName, _locale: StringName = &"en") -> String:
	var candidates: Array[InputEvent] = []
	for event: InputEvent in InputMap.action_get_events(action):
		if active_device == Device.KEYBOARD and event is InputEventKey:
			candidates.append(event)
		elif active_device == Device.CONTROLLER and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
			candidates.append(event)
	if candidates.is_empty():
		return "[MOUSE]" if active_device == Device.POINTER else "[?]"
	var prefer_last := (
		active_device == Device.KEYBOARD
		and InputMapInstaller.active_one_handed_preset != InputMapInstaller.OneHandedPreset.NONE
	)
	var selected: InputEvent = candidates.back() if prefer_last else candidates.front()
	if selected is InputEventKey:
		var label: String = OS.get_keycode_string((selected as InputEventKey).physical_keycode).to_upper()
		return "[%s]" % (label if not label.is_empty() else "KEY")
	if selected is InputEventJoypadButton:
		return "[%s]" % _joy_button_label((selected as InputEventJoypadButton).button_index)
	return "[STICK]"


func _device_for_event(event: InputEvent) -> Device:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return Device.CONTROLLER
	if event is InputEventMouseButton:
		return Device.POINTER
	return Device.KEYBOARD


func _action_family(action: StringName) -> StringName:
	if action in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		return &"move"
	if action in [&"pause", &"menu"]:
		return &"menu"
	if action in [&"cancel", &"focus"]:
		return &"cancel"
	return &"confirm"


func _joy_button_label(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A:
			return "A"
		JOY_BUTTON_B:
			return "B"
		JOY_BUTTON_X:
			return "X"
		JOY_BUTTON_Y:
			return "Y"
		JOY_BUTTON_LEFT_SHOULDER:
			return "LB"
		JOY_BUTTON_RIGHT_SHOULDER:
			return "RB"
		JOY_BUTTON_BACK:
			return "BACK"
		JOY_BUTTON_START:
			return "START"
		JOY_BUTTON_DPAD_UP:
			return "D-UP"
		JOY_BUTTON_DPAD_DOWN:
			return "D-DOWN"
		JOY_BUTTON_DPAD_LEFT:
			return "D-LEFT"
		JOY_BUTTON_DPAD_RIGHT:
			return "D-RIGHT"
		_:
			return "PAD%d" % button_index
