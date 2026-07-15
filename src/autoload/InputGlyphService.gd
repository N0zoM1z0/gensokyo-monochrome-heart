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
