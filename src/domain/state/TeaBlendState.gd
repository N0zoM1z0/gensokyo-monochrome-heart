class_name TeaBlendState
extends RefCounted
## Unlocked daily texture modifier; selection resets through time rules.

var blend_id: StringName
var unlocked_day: int = 1
var times_prepared: int = 0


func _init(p_blend_id: StringName = &"") -> void:
	blend_id = p_blend_id


func duplicate_state() -> TeaBlendState:
	var copy := TeaBlendState.new(blend_id)
	copy.unlocked_day = unlocked_day
	copy.times_prepared = times_prepared
	return copy
