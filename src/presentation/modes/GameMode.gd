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
