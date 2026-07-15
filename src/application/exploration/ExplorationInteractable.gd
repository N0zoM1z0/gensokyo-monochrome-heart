class_name ExplorationInteractable
extends RefCounted
## Passive spatial record; it never polls the player or owns story state.

var interactable_id: StringName
var world_position: Vector2
var interaction_radius: float = 20.0
var required_for_objective: bool = false
var action: ExplorationAction


func _init(
	p_id: StringName = &"",
	p_position: Vector2 = Vector2.ZERO,
	p_action: ExplorationAction = null,
	p_radius: float = 20.0
) -> void:
	interactable_id = p_id
	world_position = p_position
	action = p_action
	interaction_radius = p_radius
