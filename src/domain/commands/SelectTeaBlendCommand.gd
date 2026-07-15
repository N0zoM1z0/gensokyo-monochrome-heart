class_name SelectTeaBlendCommand
extends GameCommand

var blend_id: StringName


func _init(p_blend_id: StringName) -> void:
	super(&"state.select_tea_blend")
	blend_id = p_blend_id
