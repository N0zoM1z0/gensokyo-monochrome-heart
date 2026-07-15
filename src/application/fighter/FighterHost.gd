class_name FighterHost
extends RefCounted
## Shared story-duel lifecycle, AI handoff, training step, retry, and result emission.

signal result_ready(result: ModeResult)
signal spell_break(checkpoint: String)

var runtime: FighterDuelSimulation
var ai := FighterStoryAI.new()
var attempt_count: int = 0
var defeat_count: int = 0
var _result_emitted: bool = false


func load_duel(
	next_runtime: FighterDuelSimulation,
	definition: FighterDuelDefinition,
	context: ModeContext,
	assists: FighterAssistSettings = null,
	ai_band: StringName = &"story"
) -> bool:
	if next_runtime == null or not next_runtime.configure(definition, context, assists):
		return false
	runtime = next_runtime
	attempt_count = 1
	defeat_count = 0
	_result_emitted = false
	runtime.attempt_count = attempt_count
	runtime.spell_break.connect(_on_spell_break)
	return ai.configure(ai_band, 1, context.deterministic_seed ^ 0x5f3759df)


func step(player_input: FighterInputFrame) -> ModeResult:
	if runtime == null:
		return null
	var result := runtime.step(player_input, ai.next_input(runtime))
	_emit_once(result)
	return result


func step_with_inputs(player_input: FighterInputFrame, opponent_input: FighterInputFrame) -> ModeResult:
	if runtime == null:
		return null
	var result := runtime.step(player_input, opponent_input)
	_emit_once(result)
	return result


func training_frame_step(player_input: FighterInputFrame, opponent_input: FighterInputFrame) -> ModeResult:
	if runtime == null or not runtime.is_paused:
		return null
	var result := runtime.frame_step(player_input, opponent_input)
	_emit_once(result)
	return result


func toggle_pause() -> void:
	if runtime != null:
		runtime.toggle_pause()


func retry_match() -> void:
	if runtime == null:
		return
	attempt_count += 1
	_result_emitted = false
	runtime.reset_match()
	runtime.attempt_count = attempt_count


func accept_loss() -> ModeResult:
	if runtime == null:
		return null
	var result := runtime.accept_loss()
	_emit_once(result)
	return result


func _emit_once(result: ModeResult) -> void:
	if result == null or _result_emitted:
		return
	_result_emitted = true
	if result.result_tag == &"loss":
		defeat_count += 1
	if result.telemetry != null:
		result.telemetry.attempt_count = attempt_count
	result_ready.emit(result)


func _on_spell_break(checkpoint: String) -> void:
	spell_break.emit(checkpoint)
