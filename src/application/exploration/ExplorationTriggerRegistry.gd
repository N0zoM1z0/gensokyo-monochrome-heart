class_name ExplorationTriggerRegistry
extends RefCounted
## Resolves authored volumes without embedding event IDs in the player controller.

var _triggers: Array[ExplorationEventTrigger] = []
var _consumed: Dictionary[StringName, bool] = {}


func register(trigger: ExplorationEventTrigger) -> bool:
	if trigger == null or trigger.trigger_id == &"" or trigger.event_id == &"":
		return false
	for existing: ExplorationEventTrigger in _triggers:
		if existing.trigger_id == trigger.trigger_id:
			return false
	_triggers.append(trigger)
	return true


func resolve(position: Vector2, completed_objective_id: StringName = &"") -> ExplorationEventTrigger:
	for trigger: ExplorationEventTrigger in _triggers:
		if _consumed.has(trigger.trigger_id) or not trigger.bounds.has_point(position):
			continue
		if trigger.required_objective_id != &"" and trigger.required_objective_id != completed_objective_id:
			continue
		_consumed[trigger.trigger_id] = true
		return trigger
	return null


func reset() -> void:
	_consumed.clear()
