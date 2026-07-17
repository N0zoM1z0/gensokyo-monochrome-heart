extends SceneTree
## Proves Eirin gives small human care exact attention without abandoning cosmic work or punishing a planning loss.

const EVENT_ID: StringName = &"evt.eir.practical_care"
const EIRIN: StringName = &"char.eirin_yagokoro"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["An Immortal's Practical Care content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	var index := 0
	for tone: StringName in [&"direct", &"playful", &"patient", &"defiant"]:
		for mode_tag: StringName in [&"clear", &"assist_clear", &"loss"]:
			_run(graph, tone, mode_tag, index); index += 1
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, mode_tag: StringName, index: int) -> void:
	var state := _state(StringName("p219%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	for _step: int in range(5): result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach practical-care responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE and result.mode_context.mode_id == &"mini.eir.practical_care_attention", "%s did not reach the attention plan" % tone)
	result = interpreter.resume_mode(ModeResult.new(mode_tag))
	var expected_node := StringName("n_%s" % (&"assist" if mode_tag == &"assist_clear" else mode_tag))
	_expect(result.node_id == expected_node, "%s/%s reached the wrong care-plan response" % [tone, mode_tag])
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"small_human_care_and_cosmic_review_both_receive_exact_attention", "%s/%s did not complete both obligations" % [tone, mode_tag])
	_expect(state.characters[EIRIN].route_stage == 3 and state.journal.entries.has(&"journal.eir.practical_care"), "%s/%s omitted route evidence" % [tone, mode_tag])
	_expect(state.flags.has(&"flag.route.eirin.practical_care.kosuzu_consent_preserved") and state.flags.has(&"flag.route.eirin.practical_care.kosuzu_care_scope_confirmed") and state.flags.has(&"flag.route.eirin.practical_care.scale_not_worth") and state.flags.has(&"flag.route.eirin.practical_care.cosmic_problem_still_reviewed"), "%s/%s skipped consent, ranked scale as worth, or dropped an obligation" % [tone, mode_tag])
	if mode_tag == &"loss": _expect(state.characters[EIRIN].relationship.strain == 0, "planning loss punished ordinary care")


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2191)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.eientei"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.ein.patient_refuses", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.ein.patient_refuses", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(EIRIN, 2))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Eirin Practical Care integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
