class_name FiveImpossibleErrandsSimulation
extends MinigameRuntime
## Deterministic sequence host: all three philosophies are valid, visible answers.

var errands: Array[ImpossibleErrandDefinition] = []
var state := FiveImpossibleErrandsState.new()
var final_result: ModeResult
var deterministic_seed: int = 1


func _init() -> void:
	definition = FiveImpossibleErrandsDefinition.new()
	errands = FiveImpossibleErrandsCatalog.build()


func configure(context: ModeContext, assist_settings: MinigameAssistSettings) -> void:
	super.configure(context, assist_settings)
	deterministic_seed = maxi(1, context.deterministic_seed)
	reset_attempt()


func reset_attempt() -> void:
	super.reset_attempt()
	state = FiveImpossibleErrandsState.new()
	final_result = null


func step(input: MinigameInputFrame) -> ModeResult:
	if input == null or is_paused:
		return final_result
	if state.phase == FiveImpossibleErrandsState.Phase.TUTORIAL:
		if input.confirm_pressed:
			state.phase = FiveImpossibleErrandsState.Phase.ACTIVE
		return null
	if state.phase == FiveImpossibleErrandsState.Phase.RESULT:
		return final_result
	state.elapsed_ticks += 1
	state.option_cursor = clampi(
		state.option_cursor + clampi(input.choice_direction, -1, 1),
		0,
		FiveImpossibleErrandsCatalog.APPROACHES.size() - 1
	)
	if input.confirm_pressed:
		_commit_choice()
	return final_result


func current_errand() -> ImpossibleErrandDefinition:
	return errands[state.errand_index] if state.errand_index < errands.size() else null


func current_option() -> ImpossibleErrandOption:
	var errand := current_errand()
	return errand.options[state.option_cursor] if errand != null else null


func accept_loss() -> ModeResult:
	return final_result if final_result != null else _finish(&"withdrawn")


func _commit_choice() -> void:
	var option := current_option()
	if option == null:
		return
	state.choices.append(option.approach_id)
	state.errand_index += 1
	state.option_cursor = 0
	if state.errand_index >= errands.size():
		_finish(&"clear")


func _finish(result_tag: StringName) -> ModeResult:
	state.phase = FiveImpossibleErrandsState.Phase.RESULT
	state.result_tag = result_tag
	final_result = ModeResult.new(result_tag)
	final_result.performance_band = _response_shape() if result_tag == &"clear" else &"withdrawn"
	final_result.used_assist = assists.any_enabled()
	final_result.outcome_tags = [&"errands.five_possible", StringName("errands.result.%s" % result_tag)]
	for index: int in range(state.choices.size()):
		final_result.outcome_tags.append(StringName("errands.choice.%d.%s" % [index + 1, state.choices[index]]))
	var telemetry := ModeTelemetry.new()
	telemetry.deterministic_seed = deterministic_seed
	telemetry.elapsed_ticks = state.elapsed_ticks
	telemetry.final_state_hash = state.canonical_snapshot().sha256_text()
	final_result.telemetry = telemetry
	return final_result


func _response_shape() -> StringName:
	var unique := {}
	for choice: StringName in state.choices:
		unique[choice] = true
	return &"varied" if unique.size() >= 3 else &"committed"
