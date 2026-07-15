class_name SetRouteIntentCommand
extends GameCommand

var character_id: StringName
var route_intent: StringName


func _init(p_character_id: StringName, p_route_intent: StringName) -> void:
	super(&"state.set_route_intent")
	character_id = p_character_id
	route_intent = p_route_intent
