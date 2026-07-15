class_name CharacterState
extends RefCounted
## Per-profile route, memory, availability, and hidden relationship state.

const ROUTE_INTENTS: Array[StringName] = [&"undecided", &"friendship", &"romance", &"postponed"]

var character_id: StringName
var relationship := RelationshipState.new()
var route_stage: int = 0
var route_intent: StringName = &"undecided"
var memory_tags: Array[StringName] = []
var completed_event_ids: Array[StringName] = []
var is_available: bool = true


func _init(p_character_id: StringName = &"") -> void:
	character_id = p_character_id


func duplicate_state() -> CharacterState:
	var copy := CharacterState.new(character_id)
	copy.relationship = relationship.duplicate_state()
	copy.route_stage = route_stage
	copy.route_intent = route_intent
	copy.memory_tags = memory_tags.duplicate()
	copy.completed_event_ids = completed_event_ids.duplicate()
	copy.is_available = is_available
	return copy
