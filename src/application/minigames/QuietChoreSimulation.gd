class_name QuietChoreSimulation
extends MinigameRuntime
## Complete two ordinary chores, then advance only by leaving the controls alone.

const REQUIRED_SWEEP_STROKES := 6
const REQUIRED_MENDED_SEAMS := 3
const STANDARD_SILENCE_TICKS := 180
const STORY_SILENCE_TICKS := 120

var state := QuietChoreState.new()
var final_result: ModeResult
var deterministic_seed: int = 1


func _init() -> void:
	definition = QuietChoreDefinition.new()


func configure(context: ModeContext, assist_settings: MinigameAssistSettings) -> void:
	super.configure(context, assist_settings)
	deterministic_seed = maxi(1, context.deterministic_seed)
	reset_attempt()


func reset_attempt() -> void:
	super.reset_attempt()
	state = QuietChoreState.new()
	final_result = null


func step(input: MinigameInputFrame) -> ModeResult:
	if input == null or is_paused:
		return final_result
	if state.phase == QuietChoreState.Phase.TUTORIAL:
		if input.confirm_pressed:
			state.phase = QuietChoreState.Phase.SWEEP
		return null
	if state.phase == QuietChoreState.Phase.RESULT:
		return final_result
	state.elapsed_ticks += 1
	match state.phase:
		QuietChoreState.Phase.SWEEP:
			_step_sweep(input)
		QuietChoreState.Phase.MEND:
			_step_mend(input)
		QuietChoreState.Phase.SIT:
			_step_silence(input)
	return final_result


func _step_sweep(input: MinigameInputFrame) -> void:
	var direction := clampi(input.grid_direction.x, -1, 1)
	if direction == 0 or direction == state.last_sweep_direction:
		return
	state.last_sweep_direction = direction
	state.sweep_strokes += 1
	if state.sweep_strokes >= REQUIRED_SWEEP_STROKES:
		state.phase = QuietChoreState.Phase.MEND


func _step_mend(input: MinigameInputFrame) -> void:
	if not input.confirm_pressed:
		return
	state.mended_seams += 1
	if state.mended_seams >= REQUIRED_MENDED_SEAMS:
		state.phase = QuietChoreState.Phase.SIT


func _step_silence(input: MinigameInputFrame) -> void:
	var interrupted := input.confirm_pressed or input.grid_direction != Vector2i.ZERO or input.choice_direction != 0
	if interrupted:
		state.interruptions += 1
		if not assists.slower_pace:
			state.silence_ticks = 0
		return
	state.silence_ticks += 1
	var required := STORY_SILENCE_TICKS if assists.slower_pace else STANDARD_SILENCE_TICKS
	if state.silence_ticks >= required:
		_finish(&"clear")


func accept_loss() -> ModeResult:
	# Silence is not graded and cannot be failed; accessibility never changes the story result.
	return final_result


func _finish(result_tag: StringName) -> ModeResult:
	state.phase = QuietChoreState.Phase.RESULT
	state.result_tag = result_tag
	final_result = ModeResult.new(result_tag)
	final_result.performance_band = &"quiet"
	final_result.used_assist = assists.any_enabled()
	final_result.outcome_tags = [
		&"quiet_chore.swept",
		&"quiet_chore.mended",
		&"quiet_chore.silence_tolerated",
		StringName("quiet_chore.interruptions.%d" % state.interruptions),
	]
	var telemetry := ModeTelemetry.new()
	telemetry.deterministic_seed = deterministic_seed
	telemetry.elapsed_ticks = state.elapsed_ticks
	telemetry.final_state_hash = state.canonical_snapshot().sha256_text()
	final_result.telemetry = telemetry
	return final_result
