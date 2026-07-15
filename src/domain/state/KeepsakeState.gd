class_name KeepsakeState
extends RefCounted
## Contextual affordance earned from an authored event, never a raw stat boost.

var keepsake_id: StringName
var source_event_id: StringName
var owner_character_id: StringName
var acquired_day: int = 1
var is_returnable: bool = false
var dialogue_tags: Array[StringName] = []


func _init(p_keepsake_id: StringName = &"") -> void:
	keepsake_id = p_keepsake_id


func duplicate_state() -> KeepsakeState:
	var copy := KeepsakeState.new(keepsake_id)
	copy.source_event_id = source_event_id
	copy.owner_character_id = owner_character_id
	copy.acquired_day = acquired_day
	copy.is_returnable = is_returnable
	copy.dialogue_tags = dialogue_tags.duplicate()
	return copy
