class_name EventEffectRecord
extends RefCounted
## Typed effect payload for relationship, route, flag, and rumor operations.

var operation: StringName
var character_id: StringName
var facet: StringName
var delta: int
var stage: int
var route_intent: StringName
var key: StringName
var boolean_value: bool
var rumor_id: StringName
var claim_key: StringName
var source_character_id: StringName
var reliability_milli: int
var privacy: StringName = &"private"
var status: StringName = &"unresolved"


func _init(p_operation: StringName) -> void:
	operation = p_operation
