class_name InputRouter
extends Node
## Converts raw device events into semantic action facts for the active UI or mode.

signal semantic_action_pressed(action: StringName)
signal semantic_action_released(action: StringName)

var _accessibility_chord_was_pressed := false


func _ready() -> void:
	InputMapInstaller.install_defaults()


func _unhandled_input(event: InputEvent) -> void:
	var glyph_service := get_node_or_null("/root/InputGlyphService")
	if glyph_service != null:
		glyph_service.observe_event(event)
	for action: StringName in GameInput.ALL_ACTIONS:
		if event.is_action_pressed(action):
			semantic_action_pressed.emit(action)
		elif event.is_action_released(action):
			semantic_action_released.emit(action)
	_check_accessibility_chord()


func _check_accessibility_chord() -> void:
	var is_pressed := Input.is_action_pressed(GameInput.PAGE_LEFT) and Input.is_action_pressed(GameInput.PAGE_RIGHT)
	if is_pressed and not _accessibility_chord_was_pressed:
		semantic_action_pressed.emit(GameInput.ACCESSIBILITY)
	_accessibility_chord_was_pressed = is_pressed
