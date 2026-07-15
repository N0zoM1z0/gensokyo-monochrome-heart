class_name EventEffectRecord
extends RefCounted
## Typed effect payload for relationship and flag operations in the starter graph.

var operation: StringName
var character_id: StringName
var facet: StringName
var delta: int
var key: StringName
var boolean_value: bool


func _init(p_operation: StringName) -> void:
	operation = p_operation
