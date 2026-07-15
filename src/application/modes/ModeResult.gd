class_name ModeResult
extends RefCounted
## Stable mechanical outcome returned to an event without mutating story state.

var result_tag: StringName
var outcome_tags: Array[StringName] = []
var used_assist: bool = false


func _init(p_result_tag: StringName = &"") -> void:
	result_tag = p_result_tag
