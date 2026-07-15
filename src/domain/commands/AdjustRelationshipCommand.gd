class_name AdjustRelationshipCommand
extends GameCommand

var character_id: StringName
var facet: StringName
var delta: int


func _init(p_character_id: StringName, p_facet: StringName, p_delta: int) -> void:
	super(&"state.adjust_relationship")
	character_id = p_character_id
	facet = p_facet
	delta = p_delta
