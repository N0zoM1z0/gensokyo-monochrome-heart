class_name ExplorationMotor
extends RefCounted
## Fixed-step, low-precision side-view locomotion with stable floor/prop collision.

const FIXED_DELTA := 1.0 / 60.0
const WALK_SPEED := 54.0
const FOCUS_SPEED := 28.0
const GRAVITY := 480.0
const HOP_SPEED := -145.0
const COYOTE_SECONDS := 0.08
const AVATAR_HALF_WIDTH := 6.0
const AVATAR_HEIGHT := 20.0

var world_bounds := Rect2(8, 16, 624, 124)
var floor_y: float = 140.0
var solid_obstacles: Array[Rect2] = []


func step(state: ExplorationMotorState, input: ExplorationMotorInput) -> void:
	if state == null or input == null:
		return
	var speed := FOCUS_SPEED if input.focus_held else WALK_SPEED
	var horizontal := clampf(input.horizontal_axis, -1.0, 1.0)
	state.velocity.x = horizontal * speed
	if absf(horizontal) > 0.01:
		state.facing = Vector2(signf(horizontal), 0)
	if state.is_grounded:
		state.coyote_seconds = COYOTE_SECONDS
	else:
		state.coyote_seconds = maxf(0.0, state.coyote_seconds - FIXED_DELTA)
	if input.hop_pressed and state.coyote_seconds > 0.0:
		state.velocity.y = HOP_SPEED
		state.is_grounded = false
		state.coyote_seconds = 0.0
	if input.float_held and state.velocity.y > 20.0:
		state.velocity.y = 20.0
	else:
		state.velocity.y += GRAVITY * FIXED_DELTA
	var opening_x := state.position.x
	_move_horizontal(state)
	_move_vertical(state)
	if state.is_grounded:
		state.footstep_distance += absf(state.position.x - opening_x)


func consume_footstep(state: ExplorationMotorState, spacing: float = 18.0) -> bool:
	if state.footstep_distance < spacing:
		return false
	state.footstep_distance = fmod(state.footstep_distance, spacing)
	return true


func _move_horizontal(state: ExplorationMotorState) -> void:
	var next_x := state.position.x + state.velocity.x * FIXED_DELTA
	next_x = clampf(next_x, world_bounds.position.x + AVATAR_HALF_WIDTH, world_bounds.end.x - AVATAR_HALF_WIDTH)
	var body_top := state.position.y - AVATAR_HEIGHT
	for obstacle: Rect2 in solid_obstacles:
		if state.position.y <= obstacle.position.y or body_top >= obstacle.end.y:
			continue
		if state.velocity.x > 0.0 and state.position.x + AVATAR_HALF_WIDTH <= obstacle.position.x and next_x + AVATAR_HALF_WIDTH > obstacle.position.x:
			next_x = obstacle.position.x - AVATAR_HALF_WIDTH
		elif state.velocity.x < 0.0 and state.position.x - AVATAR_HALF_WIDTH >= obstacle.end.x and next_x - AVATAR_HALF_WIDTH < obstacle.end.x:
			next_x = obstacle.end.x + AVATAR_HALF_WIDTH
	state.position.x = next_x


func _move_vertical(state: ExplorationMotorState) -> void:
	var next_y := state.position.y + state.velocity.y * FIXED_DELTA
	var landing_y := floor_y
	for obstacle: Rect2 in solid_obstacles:
		if state.position.x + AVATAR_HALF_WIDTH <= obstacle.position.x or state.position.x - AVATAR_HALF_WIDTH >= obstacle.end.x:
			continue
		if state.velocity.y >= 0.0 and state.position.y <= obstacle.position.y and next_y >= obstacle.position.y:
			landing_y = minf(landing_y, obstacle.position.y)
	if next_y >= landing_y:
		state.position.y = landing_y
		state.velocity.y = 0.0
		state.is_grounded = true
	else:
		state.position.y = maxf(world_bounds.position.y + AVATAR_HEIGHT, next_y)
		state.is_grounded = false
