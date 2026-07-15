class_name TeaTemperatureSimulation
extends MinigameRuntime
## Fixed-step kettle, steeping, and two-cup matching simulation.

const TICKS_PER_SECOND := 60
const TIME_LIMIT_TICKS := 45 * TICKS_PER_SECOND
const TARGET_HEAT := 620
const TARGET_STEEP_TICKS := 180
const POUR_LOCK_TICKS := 30
const MIN_HEAT := 250
const MAX_HEAT := 850

var state := TeaTemperatureState.new()
var final_result: ModeResult
var deterministic_seed: int = 1


func _init() -> void:
	definition = TeaTemperatureDefinition.new()


func configure(context: ModeContext, assist_settings: MinigameAssistSettings) -> void:
	super.configure(context, assist_settings)
	deterministic_seed = maxi(1, context.deterministic_seed)
	reset_attempt()


func reset_attempt() -> void:
	super.reset_attempt()
	state = TeaTemperatureState.new()
	state.remaining_ticks = TIME_LIMIT_TICKS
	final_result = null


func start_play() -> void:
	if state.phase == TeaTemperatureState.Phase.TUTORIAL:
		state.phase = TeaTemperatureState.Phase.ACTIVE


func step(input: MinigameInputFrame) -> ModeResult:
	if input == null or is_paused:
		return final_result
	if state.phase == TeaTemperatureState.Phase.TUTORIAL:
		if input.confirm_pressed:
			start_play()
		return null
	if state.phase == TeaTemperatureState.Phase.RESULT:
		return final_result
	state.elapsed_ticks += 1
	state.ticks_since_pour += 1
	state.steam_phase = posmod(state.elapsed_ticks + deterministic_seed, 12)
	if not assists.no_timer:
		state.remaining_ticks = maxi(0, state.remaining_ticks - 1)
	var heat_rate := 1 if assists.slower_heat_change else 2
	state.kettle_heat = clampi(
		state.kettle_heat + clampi(input.heat_direction, -1, 1) * heat_rate,
		MIN_HEAT,
		MAX_HEAT
	)
	if input.patience_held:
		state.steep_ticks = mini(360, state.steep_ticks + 1)
	if input.pour_pressed and can_pour():
		_pour_next_cup()
	if state.poured_cups >= 2:
		return _finish(_score_result())
	if not assists.no_timer and state.remaining_ticks <= 0:
		return _finish(&"loss")
	return null


func can_pour() -> bool:
	return state.phase == TeaTemperatureState.Phase.ACTIVE and state.poured_cups < 2 and state.ticks_since_pour >= POUR_LOCK_TICKS


func accept_loss() -> ModeResult:
	if final_result != null:
		return final_result
	return _finish(&"loss")


func _pour_next_cup() -> void:
	var cup_index := state.poured_cups
	var cooling := 6 + ((deterministic_seed >> (cup_index * 3)) & 7)
	state.cup_temperatures[cup_index] = state.kettle_heat - cooling
	state.poured_cups += 1
	state.ticks_since_pour = 0


func _score_result() -> StringName:
	var first_delta := absi(state.cup_temperatures[0] - TARGET_HEAT)
	var second_delta := absi(state.cup_temperatures[1] - TARGET_HEAT)
	var cup_difference := absi(state.cup_temperatures[0] - state.cup_temperatures[1])
	var steep_delta := absi(state.steep_ticks - TARGET_STEEP_TICKS)
	var excellent_heat_band := 22 + (12 if assists.wider_target_band else 0)
	var clear_heat_band := 100 + (50 if assists.wider_target_band else 0)
	var clear_steep_band := 90 + (45 if assists.wider_target_band else 0)
	if first_delta <= excellent_heat_band and second_delta <= excellent_heat_band and cup_difference <= 12 and steep_delta <= 18:
		return &"excellent"
	if first_delta <= clear_heat_band and second_delta <= clear_heat_band and cup_difference <= 40 and steep_delta <= clear_steep_band:
		return &"clear"
	return &"loss"


func _finish(result_tag: StringName) -> ModeResult:
	state.phase = TeaTemperatureState.Phase.RESULT
	state.result_tag = result_tag
	final_result = ModeResult.new(result_tag)
	final_result.performance_band = result_tag
	final_result.used_assist = assists.any_enabled()
	final_result.outcome_tags = [
		&"tea.two_cups",
		StringName("tea.result.%s" % result_tag),
	]
	var telemetry := ModeTelemetry.new()
	telemetry.deterministic_seed = deterministic_seed
	telemetry.elapsed_ticks = state.elapsed_ticks
	telemetry.final_state_hash = state.canonical_snapshot().sha256_text()
	final_result.telemetry = telemetry
	return final_result
