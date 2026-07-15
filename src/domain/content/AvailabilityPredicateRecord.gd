class_name AvailabilityPredicateRecord
extends RefCounted
## Typed availability predicate used by the starter event graph.

var predicate: StringName
var value: StringName
var key: StringName
var values: Array[StringName]
var character_id: StringName
var facet: StringName
var band: StringName


func _init(
	p_predicate: StringName,
	p_value: StringName,
	p_key: StringName,
	p_values: Array[StringName],
	p_character_id: StringName = &"",
	p_facet: StringName = &"",
	p_band: StringName = &""
) -> void:
	predicate = p_predicate
	value = p_value
	key = p_key
	values = p_values.duplicate()
	character_id = p_character_id
	facet = p_facet
	band = p_band
