class_name ExplorationMotorState
extends RefCounted
## Feet-position locomotion state independent of the scene tree.

var position: Vector2 = Vector2(40, 140)
var velocity: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.RIGHT
var is_grounded: bool = true
var coyote_seconds: float = 0.0
var footstep_distance: float = 0.0


func duplicate_state() -> ExplorationMotorState:
	var copy := ExplorationMotorState.new()
	copy.position = position
	copy.velocity = velocity
	copy.facing = facing
	copy.is_grounded = is_grounded
	copy.coyote_seconds = coyote_seconds
	copy.footstep_distance = footstep_distance
	return copy
