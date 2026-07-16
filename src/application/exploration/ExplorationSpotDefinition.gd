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
var environment_style: StringName = &"shrine_veranda"
var footstep_sfx_id: StringName = &"sfx.step.wood"
var header_primary_key: StringName = &"ui.exploration.location.veranda"
var header_secondary_key: StringName = &"ui.exploration.location.room"
var complete_key: StringName = &"ui.exploration.objective.complete"
var hint_key: StringName = &"ui.exploration.hint.second_cup"
var companion_key: StringName = &"ui.exploration.companion.float"
var counter_label_key: StringName = &""
var mode_id: StringName = &"explore.hakurei_shrine.veranda"
var companion_id: StringName = &"char.reimu_hakurei"
