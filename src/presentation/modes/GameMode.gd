class_name GameMode
extends Control
## Shared lifecycle contract for independently bootable gameplay modes.

const UI_SCALE_POLICY := preload("res://src/presentation/ui/UiScalePolicy.gd")

signal ready_for_input
signal mode_completed(result: ModeResult)
signal checkpoint_requested(reason: StringName)

var mode_context: ModeContext
var is_suspended: bool = false
var _fixture_ui_scale_percent: int = 0


func configure(context: ModeContext) -> void:
	mode_context = context


func suspend() -> void:
	is_suspended = true
	process_mode = Node.PROCESS_MODE_DISABLED


func resume() -> void:
	is_suspended = false
	process_mode = Node.PROCESS_MODE_INHERIT


func capture_debug_state() -> Dictionary:
	return {
		"mode_id": String(mode_context.mode_id) if mode_context != null else "",
		"suspended": is_suspended,
	}


func set_ui_scale_fixture(percent: int) -> void:
	_fixture_ui_scale_percent = UI_SCALE_POLICY.normalize(percent)
	_propagate_ui_scale(self)
	queue_redraw()


func ui_scale_percent() -> int:
	if _fixture_ui_scale_percent > 0:
		return _fixture_ui_scale_percent
	var accessibility := get_node_or_null("/root/AccessibilityState")
	return UI_SCALE_POLICY.normalize(accessibility.ui_scale_percent) if accessibility != null else 100


func scaled_ui_pixels(base_size: int) -> int:
	return UI_SCALE_POLICY.pixels(base_size, ui_scale_percent())


func _propagate_ui_scale(node: Node) -> void:
	for child: Node in node.get_children():
		if child is GameMode:
			(child as GameMode)._fixture_ui_scale_percent = _fixture_ui_scale_percent
			child.queue_redraw()
		_propagate_ui_scale(child)


func input_binding(action: StringName) -> String:
	var glyph_service := get_node_or_null("/root/InputGlyphService")
	if glyph_service != null:
		return glyph_service.binding_text(action)
	return "[?]"


func input_axis_binding(negative_action: StringName, positive_action: StringName) -> String:
	return "%s/%s" % [input_binding(negative_action), input_binding(positive_action)]


func input_hint(action: StringName, verb: String) -> String:
	return "%s %s" % [input_binding(action), verb]
