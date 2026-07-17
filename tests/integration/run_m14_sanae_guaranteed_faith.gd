extends SceneTree
## Proves the Archive crisis is gated by prior practice and repairs boundary strain by protecting doubt.

const EVENT_ID: StringName = &"evt.sne.guaranteed_faith"
const SANAE: StringName = &"char.sanae_kochiya"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Guaranteed Faith content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	for index: int in range(4): _run(graph, [&"direct", &"playful", &"patient", &"defiant"][index], index)
	_test_semantic_gate(graph)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p214%d" % index), true)
	state.characters[SANAE].relationship.strain = 1
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the guaranteed-faith responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"guaranteed_faith_disconnected_so_belief_can_change", "%s did not disconnect the guarantee" % tone)
	_expect(state.characters[SANAE].route_stage == 6 and state.characters[SANAE].relationship.strain == 0, "%s did not repair prior boundary strain through practice" % tone)
	_expect(state.flags.has(&"flag.route.sanae.guarantee.archive_disconnected") and state.flags.has(&"flag.route.sanae.guarantee.doubt_departure_change_protected") and state.flags.has(&"flag.route.sanae.publicity.boundary_repaired_by_practice"), "%s omitted crisis evidence" % tone)
	_expect(state.journal.entries.has(&"journal.sne.guaranteed_faith"), "%s omitted guaranteed-faith journal evidence" % tone)


func _test_semantic_gate(graph: EventGraphRecord) -> void:
	var evaluator := EventPredicateEvaluator.new()
	var missing := _state(&"p2144", false)
	_expect(not evaluator.all_pass(evaluator.evaluate_all(graph.availability, missing)), "Archive crisis ignored consent and ordinary-care prerequisites")
	var ready := _state(&"p2145", true)
	_expect(evaluator.all_pass(evaluator.evaluate_all(graph.availability, ready)), "Archive crisis remained locked after semantic prerequisites")


func _state(profile_id: StringName, semantic_flags: bool) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2141)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.moriya_shrine"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.sne.ordinary_miracle", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.sne.ordinary_miracle", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(SANAE, 5))
	if semantic_flags:
		dispatcher.dispatch(state, SetFlagCommand.new(FlagState.from_value(&"flag.route.sanae.publicity.future_image_use_requires_asking", true)))
		dispatcher.dispatch(state, SetFlagCommand.new(FlagState.from_value(&"flag.route.sanae.ordinary.power_not_required_for_care", true)))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Sanae Guaranteed Faith integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
