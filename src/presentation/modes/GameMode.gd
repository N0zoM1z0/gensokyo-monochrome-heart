class_name GameMode
extends Control
## Shared lifecycle contract for independently bootable gameplay modes.

signal ready_for_input
signal mode_completed(result: ModeResult)
signal checkpoint_requested(reason: StringName)

var mode_context: ModeContext
var is_suspended: bool = false


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


func input_binding(action: StringName) -> String:
	var glyph_service := get_node_or_null("/root/InputGlyphService")
	if glyph_service != null:
		return glyph_service.binding_text(action)
	return "[?]"


func input_axis_binding(negative_action: StringName, positive_action: StringName) -> String:
	return "%s/%s" % [input_binding(negative_action), input_binding(positive_action)]


func input_hint(action: StringName, verb: String) -> String:
	return "%s %s" % [input_binding(action), verb]
