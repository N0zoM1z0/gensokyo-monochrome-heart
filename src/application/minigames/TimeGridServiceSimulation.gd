class_name TimeGridServiceSimulation
extends MinigameRuntime
## Queue service orders in stopped time, then resolve them on the moving clock.

const TICKS_PER_SECOND := 60
const TIME_LIMIT_TICKS := 45 * TICKS_PER_SECOND
const MAX_STOP_STOCK := 300
const TASK_STATIONS: Array[int] = [0, 4, 8, 2, 6, 4]
const TASK_DUE_TICKS: Array[int] = [120, 240, 360, 480, 600, 720]
const BASE_LATE_WINDOW := 75

var state := TimeGridServiceState.new()
var final_result: ModeResult
var deterministic_seed: int = 1


func _init() -> void:
	definition = TimeGridServiceDefinition.new()


func configure(context: ModeContext, assist_settings: MinigameAssistSettings) -> void:
	super.configure(context, assist_settings)
	deterministic_seed = maxi(1, context.deterministic_seed)
	reset_attempt()


func reset_attempt() -> void:
	super.reset_attempt()
	state = TimeGridServiceState.new()
	state.remaining_ticks = TIME_LIMIT_TICKS
	final_result = null


func step(input: MinigameInputFrame) -> ModeResult:
	if input == null or is_paused:
		return final_result
	if state.phase == TimeGridServiceState.Phase.TUTORIAL:
		if input.confirm_pressed:
			state.phase = TimeGridServiceState.Phase.ACTIVE
		return null
	if state.phase == TimeGridServiceState.Phase.RESULT:
		return final_result
	state.elapsed_ticks += 1
	if not assists.no_timer:
		state.remaining_ticks = maxi(0, state.remaining_ticks - 1)
	state.time_stopped = input.patience_held and state.stop_stock > 0
	if state.time_stopped:
		state.stop_stock -= 1
		state.stop_ticks_used += 1
	else:
		if not assists.slower_pace or state.elapsed_ticks % 2 == 0:
			state.service_tick += 1
		if state.elapsed_ticks % 3 == 0:
			state.stop_stock = mini(MAX_STOP_STOCK, state.stop_stock + 1)
	_move_cursor(input.grid_direction)
	if input.pour_pressed and state.time_stopped and state.queued_station < 0:
		state.queued_station = state.cursor.y * 3 + state.cursor.x
	_resolve_current_task()
	if state.task_index >= TASK_STATIONS.size():
		return _finish(_score_result())
	if not assists.no_timer and state.remaining_ticks <= 0:
		return _finish(&"loss")
	return null


func current_station() -> int:
	return TASK_STATIONS[state.task_index] if state.task_index < TASK_STATIONS.size() else -1


func current_due_tick() -> int:
	return TASK_DUE_TICKS[state.task_index] if state.task_index < TASK_DUE_TICKS.size() else -1


func accept_loss() -> ModeResult:
	return final_result if final_result != null else _finish(&"loss")


func _move_cursor(direction: Vector2i) -> void:
	state.cursor.x = clampi(state.cursor.x + clampi(direction.x, -1, 1), 0, 2)
	state.cursor.y = clampi(state.cursor.y + clampi(direction.y, -1, 1), 0, 2)


func _resolve_current_task() -> void:
	if state.task_index >= TASK_STATIONS.size():
		return
	var due := current_due_tick()
	var late_window := BASE_LATE_WINDOW + (60 if assists.wider_timing_window else 0)
	if state.queued_station >= 0 and state.service_tick >= due:
		if state.queued_station == current_station():
			state.completed_tasks += 1
			state.total_timing_error += absi(state.service_tick - due)
		else:
			state.missed_tasks += 1
		_advance_task()
	elif state.queued_station < 0 and state.service_tick > due + late_window:
		state.missed_tasks += 1
		_advance_task()


func _advance_task() -> void:
	state.task_index += 1
	state.queued_station = -1


func _score_result() -> StringName:
	if state.missed_tasks == 0 and state.completed_tasks == TASK_STATIONS.size() and state.total_timing_error <= 30:
		return &"excellent"
	if state.missed_tasks <= 1 and state.completed_tasks >= TASK_STATIONS.size() - 1:
		return &"clear"
	return &"loss"


func _finish(result_tag: StringName) -> ModeResult:
	state.phase = TimeGridServiceState.Phase.RESULT
	state.result_tag = result_tag
	final_result = ModeResult.new(result_tag)
	final_result.performance_band = result_tag
	final_result.used_assist = assists.any_enabled()
	final_result.outcome_tags = [&"service.time_grid", StringName("service.result.%s" % result_tag)]
	var telemetry := ModeTelemetry.new()
	telemetry.deterministic_seed = deterministic_seed
	telemetry.elapsed_ticks = state.elapsed_ticks
	telemetry.final_state_hash = state.canonical_snapshot().sha256_text()
	final_result.telemetry = telemetry
	return final_result
