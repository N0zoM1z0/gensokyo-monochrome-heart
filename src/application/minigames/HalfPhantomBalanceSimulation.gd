class_name HalfPhantomBalanceSimulation
extends MinigameRuntime
## Move the human and phantom halves independently; switching is the lesson, not a punishment.

const COLUMN_COUNT := 5
const YOUMU_TARGET := 4
const PHANTOM_TARGET := 0
const DEFINITION := preload("res://src/application/minigames/HalfPhantomBalanceDefinition.gd")
const STATE := preload("res://src/application/minigames/HalfPhantomBalanceState.gd")

var state = STATE.new()
var final_result: ModeResult
var deterministic_seed: int = 1


func _init() -> void:
	definition = DEFINITION.new()


func configure(context: ModeContext, assist_settings: MinigameAssistSettings) -> void:
	super.configure(context, assist_settings)
	deterministic_seed = maxi(1, context.deterministic_seed)
	reset_attempt()


func reset_attempt() -> void:
	super.reset_attempt()
	state = STATE.new()
	final_result = null


func step(input: MinigameInputFrame) -> ModeResult:
	if input == null or is_paused:
		return final_result
	if state.phase == STATE.Phase.TUTORIAL:
		if input.confirm_pressed:
			state.phase = STATE.Phase.ACTIVE
		return null
	if state.phase == STATE.Phase.RESULT:
		return final_result
	if input.confirm_pressed:
		state.selected_body = STATE.Body.PHANTOM if state.selected_body == STATE.Body.YOUMU else STATE.Body.YOUMU
	var direction := clampi(input.grid_direction.x, -1, 1)
	if direction != 0:
		state.steps += 1
		if state.selected_body == STATE.Body.YOUMU:
			state.youmu_column = clampi(state.youmu_column + direction, 0, COLUMN_COUNT - 1)
		else:
			state.phantom_column = clampi(state.phantom_column + direction, 0, COLUMN_COUNT - 1)
	if state.youmu_column == YOUMU_TARGET and state.phantom_column == PHANTOM_TARGET:
		_finish(&"clear")
	return final_result


func accept_loss() -> ModeResult:
	if final_result == null:
		_finish(&"withdrawn")
	return final_result


func selected_label() -> StringName:
	return &"youmu" if state.selected_body == STATE.Body.YOUMU else &"phantom"


func _finish(result_tag: StringName) -> void:
	state.phase = STATE.Phase.RESULT
	state.result_tag = result_tag
	final_result = ModeResult.new(result_tag)
	final_result.performance_band = &"steady" if result_tag == &"clear" else &"continued"
	final_result.used_assist = assists.any_enabled()
	final_result.outcome_tags = [&"half_phantom.balance", StringName("half_phantom.result.%s" % result_tag)]
	var telemetry := ModeTelemetry.new()
	telemetry.deterministic_seed = deterministic_seed
	telemetry.elapsed_ticks = state.steps
	telemetry.final_state_hash = JSON.stringify(state.canonical_snapshot()).sha256_text()
	final_result.telemetry = telemetry
