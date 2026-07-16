class_name BroomBackseatSimulation
extends MinigameRuntime
## A calm cargo-balance tutorial: imperfect landings continue instead of failing the route.

const TARGET_LANES: Array[int] = [-1, 1, 0, -1]

var state := BroomBackseatState.new()
var final_result: ModeResult
var deterministic_seed: int = 1


func _init() -> void:
	definition = BroomBackseatDefinition.new()


func configure(context: ModeContext, assist_settings: MinigameAssistSettings) -> void:
	super.configure(context, assist_settings)
	deterministic_seed = maxi(1, context.deterministic_seed)
	reset_attempt()


func reset_attempt() -> void:
	super.reset_attempt()
	state = BroomBackseatState.new()
	final_result = null


func step(input: MinigameInputFrame) -> ModeResult:
	if input == null or is_paused:
		return final_result
	if state.phase == BroomBackseatState.Phase.TUTORIAL:
		if input.confirm_pressed:
			state.phase = BroomBackseatState.Phase.ACTIVE
		return null
	if state.phase == BroomBackseatState.Phase.RESULT:
		return final_result
	state.elapsed_ticks += 1
	state.cargo_lane = clampi(state.cargo_lane + clampi(input.grid_direction.x, -1, 1), -1, 1)
	if input.confirm_pressed:
		_land_checkpoint()
	return final_result


func accept_loss() -> ModeResult:
	# A rough landing is feedback, not a story failure.
	return final_result


func target_lane() -> int:
	return TARGET_LANES[state.checkpoint_index] if state.checkpoint_index < TARGET_LANES.size() else 0


func _land_checkpoint() -> void:
	if state.cargo_lane == target_lane() or assists.wider_timing_window:
		state.safe_landings += 1
		state.last_landing = &"safe"
	else:
		state.rough_landings += 1
		state.last_landing = &"rough"
	state.checkpoint_index += 1
	if state.checkpoint_index >= TARGET_LANES.size():
		_finish(&"clear" if state.rough_landings == 0 else &"assist_clear")


func _finish(result_tag: StringName) -> void:
	state.phase = BroomBackseatState.Phase.RESULT
	state.result_tag = result_tag
	final_result = ModeResult.new(result_tag)
	final_result.performance_band = &"steady" if result_tag == &"clear" else &"continued"
	final_result.used_assist = assists.any_enabled()
	final_result.outcome_tags = [
		&"broom_backseat.cargo_delivered",
		StringName("broom_backseat.safe_landings.%d" % state.safe_landings),
		StringName("broom_backseat.rough_landings.%d" % state.rough_landings),
	]
	var telemetry := ModeTelemetry.new()
	telemetry.deterministic_seed = deterministic_seed
	telemetry.elapsed_ticks = state.elapsed_ticks
	telemetry.final_state_hash = state.canonical_snapshot().sha256_text()
	final_result.telemetry = telemetry
