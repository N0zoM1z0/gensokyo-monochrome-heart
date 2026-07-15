class_name ExplorationSpotDefinition
extends RefCounted
## Authored spot setup consumed by the generic exploration mode/controller.

var location_id: StringName
var spot_id: StringName
var objective_id: StringName
var required_sequence: Array[StringName] = []
var start_position: Vector2 = Vector2(40, 140)
var world_bounds: Rect2 = Rect2(8, 16, 624, 124)
var floor_y: float = 140.0
var solid_obstacles: Array[Rect2] = []
var interactables: Array[ExplorationInteractable] = []
var event_triggers: Array[ExplorationEventTrigger] = []
