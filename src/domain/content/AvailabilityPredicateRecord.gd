class_name AvailabilityPredicateRecord
extends RefCounted
## Typed availability predicate used by the starter event graph.

var predicate: StringName
var value: StringName
var key: StringName
var values: Array[StringName]


func _init(
	p_predicate: StringName,
	p_value: StringName,
	p_key: StringName,
	p_values: Array[StringName]
) -> void:
	predicate = p_predicate
	value = p_value
	key = p_key
	values = p_values.duplicate()
