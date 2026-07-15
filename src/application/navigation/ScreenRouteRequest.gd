class_name ScreenRouteRequest
extends RefCounted
## Typed navigation intent. Scene paths and hosts remain presentation-owned registry data.

var screen_id: StringName
var parameters: Dictionary
var restore_focus_id: StringName


func _init(
	p_screen_id: StringName,
	p_parameters: Dictionary = {},
	p_restore_focus_id: StringName = &""
) -> void:
	screen_id = p_screen_id
	parameters = p_parameters.duplicate(true)
	restore_focus_id = p_restore_focus_id
