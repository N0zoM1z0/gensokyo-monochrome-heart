class_name SetEventPositionCommand
extends GameCommand
## Moves the persisted event cursor, or clears both cursor fields together.

var event_id: StringName
var node_id: StringName


func _init(p_event_id: StringName = &"", p_node_id: StringName = &"") -> void:
	super(&"event.set_position")
	event_id = p_event_id
	node_id = p_node_id
