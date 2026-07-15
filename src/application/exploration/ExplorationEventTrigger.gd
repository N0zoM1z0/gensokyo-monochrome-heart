class_name ExplorationEventTrigger
extends RefCounted
## Data-owned event volume; generic player code sees only the trigger record.

var trigger_id: StringName
var event_id: StringName
var bounds: Rect2
var required_objective_id: StringName


func _init(
	p_trigger_id: StringName = &"",
	p_event_id: StringName = &"",
	p_bounds: Rect2 = Rect2(),
	p_required_objective_id: StringName = &""
) -> void:
	trigger_id = p_trigger_id
	event_id = p_event_id
	bounds = p_bounds
	required_objective_id = p_required_objective_id
