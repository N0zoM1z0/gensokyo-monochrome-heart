class_name CompleteEventCommand
extends GameCommand
## Commits one active event completion and clears its persisted cursor.

var event_id: StringName
var outcome: StringName


func _init(p_event_id: StringName = &"", p_outcome: StringName = &"") -> void:
	super(&"event.complete")
	event_id = p_event_id
	outcome = p_outcome
