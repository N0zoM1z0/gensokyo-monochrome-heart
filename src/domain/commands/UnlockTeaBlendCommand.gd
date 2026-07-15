class_name UnlockTeaBlendCommand
extends GameCommand

var blend: TeaBlendState


func _init(p_blend: TeaBlendState) -> void:
	super(&"state.unlock_tea_blend")
	blend = p_blend.duplicate_state() if p_blend != null else null
