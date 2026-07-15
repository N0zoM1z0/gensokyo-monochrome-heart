class_name InputRouter
extends Node
## Converts raw device events into semantic action facts for the active UI or mode.

signal semantic_action_pressed(action: StringName)
signal semantic_action_released(action: StringName)

var _accessibility_chord_was_pressed := false
var _action_candidate_resolver: Callable


func _ready() -> void:
	InputMapInstaller.install_defaults()


func _unhandled_input(event: InputEvent) -> void:
	var glyph_service := get_node_or_null("/root/InputGlyphService")
	if glyph_service != null:
		glyph_service.observe_event(event)
	for action: StringName in _resolved_actions(event, true):
		semantic_action_pressed.emit(action)
	for action: StringName in _resolved_actions(event, false):
		semantic_action_released.emit(action)
	_check_accessibility_chord()


func set_action_candidate_resolver(resolver: Callable) -> void:
	_action_candidate_resolver = resolver


func resolve_event_actions_for_test(event: InputEvent, is_pressed: bool = true) -> Array[StringName]:
	return _resolved_actions(event, is_pressed)


func _resolved_actions(event: InputEvent, is_pressed: bool) -> Array[StringName]:
	var candidates: Array[StringName] = []
	for action: StringName in GameInput.ALL_ACTIONS:
		var matches := event.is_action_pressed(action) if is_pressed else event.is_action_released(action)
		if matches:
			candidates.append(action)
	if candidates.size() <= 1 or not _action_candidate_resolver.is_valid():
		return candidates
	var resolved := StringName(_action_candidate_resolver.call(candidates))
	var result: Array[StringName] = []
	if resolved in candidates:
		result.append(resolved)
	return result


func _check_accessibility_chord() -> void:
	var is_pressed := Input.is_action_pressed(GameInput.PAGE_LEFT) and Input.is_action_pressed(GameInput.PAGE_RIGHT)
	if is_pressed and not _accessibility_chord_was_pressed:
		semantic_action_pressed.emit(GameInput.ACCESSIBILITY)
	_accessibility_chord_was_pressed = is_pressed
