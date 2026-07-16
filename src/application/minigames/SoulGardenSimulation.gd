class_name SoulGardenSimulation
extends MinigameRuntime
## Collect a marked spirit, carry it deliberately, then release it at its memorial tree.

const COLUMN_COUNT := 5
const STANDARD_DRIFT_TICKS := 45
const ASSIST_DRIFT_TICKS := 90
const TREE_COLUMNS: Array[int] = [0, 2, 4]
const SIGNATURE_IDS: Array[StringName] = [&"fan", &"cup", &"bell"]

var state := SoulGardenState.new()
var final_result: ModeResult
var deterministic_seed: int = 1


func _init() -> void:
	definition = SoulGardenDefinition.new()


func configure(context: ModeContext, assist_settings: MinigameAssistSettings) -> void:
	super.configure(context, assist_settings)
	deterministic_seed = maxi(1, context.deterministic_seed)
	reset_attempt()


func reset_attempt() -> void:
	super.reset_attempt()
	state = SoulGardenState.new()
	final_result = null


func step(input: MinigameInputFrame) -> ModeResult:
	if input == null or is_paused:
		return final_result
	if state.phase == SoulGardenState.Phase.TUTORIAL:
		if input.confirm_pressed:
			state.phase = SoulGardenState.Phase.ACTIVE
		return null
	if state.phase == SoulGardenState.Phase.RESULT:
		return final_result
	state.elapsed_ticks += 1
	state.cursor_column = clampi(state.cursor_column + clampi(input.grid_direction.x, -1, 1), 0, COLUMN_COUNT - 1)
	if input.confirm_pressed:
		if state.carried_spirit >= 0:
			_try_release()
		else:
			_try_collect()
	_drift_spirits()
	return final_result


func spirit_at_cursor() -> int:
	for index: int in range(state.spirit_columns.size()):
		if not state.released[index] and index != state.carried_spirit and state.spirit_columns[index] == state.cursor_column:
			return index
	return -1


func expected_tree_column() -> int:
	return TREE_COLUMNS[state.carried_spirit] if state.carried_spirit >= 0 else -1


func accept_loss() -> ModeResult:
	return final_result if final_result != null else _finish(&"withdrawn")


func _try_collect() -> void:
	state.carried_spirit = spirit_at_cursor()


func _try_release() -> void:
	if state.cursor_column not in TREE_COLUMNS:
		return
	if state.cursor_column != expected_tree_column():
		state.mismatch_count += 1
		return
	state.released[state.carried_spirit] = true
	state.released_count += 1
	state.carried_spirit = -1
	if state.released_count >= SIGNATURE_IDS.size():
		_finish(&"clear")


func _drift_spirits() -> void:
	var interval := ASSIST_DRIFT_TICKS if assists.slower_pace else STANDARD_DRIFT_TICKS
	if state.elapsed_ticks % interval != 0:
		return
	for index: int in range(state.spirit_columns.size()):
		if not state.released[index] and index != state.carried_spirit:
			state.spirit_columns[index] = posmod(state.spirit_columns[index] + 1, COLUMN_COUNT)


func _finish(result_tag: StringName) -> ModeResult:
	state.phase = SoulGardenState.Phase.RESULT
	state.result_tag = result_tag
	final_result = ModeResult.new(result_tag)
	final_result.performance_band = &"excellent" if result_tag == &"clear" and state.mismatch_count == 0 else result_tag
	final_result.used_assist = assists.any_enabled()
	final_result.outcome_tags = [
		&"soul_garden.release",
		StringName("soul_garden.released.%d" % state.released_count),
		StringName("soul_garden.result.%s" % result_tag),
	]
	var telemetry := ModeTelemetry.new()
	telemetry.deterministic_seed = deterministic_seed
	telemetry.elapsed_ticks = state.elapsed_ticks
	telemetry.final_state_hash = state.canonical_snapshot().sha256_text()
	final_result.telemetry = telemetry
	return final_result
