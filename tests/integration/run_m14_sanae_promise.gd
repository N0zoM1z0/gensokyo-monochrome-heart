extends SceneTree
## Proves all Sanae futures and a declined photograph complete after semantic boundary repair.

const EVENT_ID: StringName = &"evt.sne.promise"
const SANAE: StringName = &"char.sanae_kochiya"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["A Miracle With Witnesses content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	_run(graph, &"friendship", &"direct", &"recipes_and_shrine_duties_exchanged_as_friendship", 0)
	_run(graph, &"romance", &"playful", &"one_private_photograph_taken_after_consent", 1)
	_run(graph, &"postponed", &"patient", &"relationship_postponed_ordinary_exchange_continues", 2)
	_run(graph, &"undecided", &"defiant", &"future_unclaimed_duties_continue_without_photo", 3)
	_run_romance_declined(graph)
	_test_semantic_gate(graph)
	_finish(_failures)


func _run(graph: EventGraphRecord, intent: StringName, tone: StringName, outcome: StringName, index: int) -> void:
	var state := _state(StringName("p215%d" % index), true)
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.choice_id == &"choice.sne.promise.intent" and result.choice.options.size() == 4, "%s did not show four explicit futures" % intent)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line()
	if intent == &"romance":
		_expect(result.choice != null and result.choice.choice_id == &"choice.sne.promise.romance_consent" and result.choice.options.size() == 2, "romance did not wait for separate photo consent")
		result = interpreter.choose_tone(&"direct"); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == outcome, "%s did not complete Sanae's authored future" % intent)
	_expect(state.characters[SANAE].route_stage == 7 and state.characters[SANAE].route_intent == intent, "%s did not persist stage seven and intent" % intent)
	_expect(state.journal.entries.has(StringName("journal.sne.promise.%s" % intent)), "%s did not preserve promise journal evidence" % intent)


func _run_romance_declined(graph: EventGraphRecord) -> void:
	var state := _state(&"p215_declined", true)
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line(); result = interpreter.choose_tone(&"playful"); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.choice_id == &"choice.sne.promise.romance_consent", "declined romance did not reach photo consent")
	result = interpreter.choose_tone(&"defiant"); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"romance_chosen_without_photograph_camera_packed", "declined photo did not complete as romance without a photograph")
	_expect(state.characters[SANAE].route_stage == 7 and state.characters[SANAE].route_intent == &"romance", "declined photo revoked the separately chosen romance")
	_expect(state.characters[SANAE].relationship.strain == 0 and state.flags.has(&"flag.route.sanae.promise.photo_declined_without_penalty"), "declined photo added strain or omitted no-penalty evidence")
	_expect(state.journal.entries.has(&"journal.sne.promise.romance_declined"), "declined photo omitted journal evidence")


func _test_semantic_gate(graph: EventGraphRecord) -> void:
	var evaluator := EventPredicateEvaluator.new()
	_expect(not evaluator.all_pass(evaluator.evaluate_all(graph.availability, _state(&"p215_missing", false))), "promise ignored semantic boundary repair")
	_expect(evaluator.all_pass(evaluator.evaluate_all(graph.availability, _state(&"p215_ready", true))), "promise remained locked after semantic boundary repair")


func _state(profile_id: StringName, semantic_flags: bool) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2151)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.moriya_shrine"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.sne.guaranteed_faith", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.sne.guaranteed_faith", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(SANAE, 6))
	if semantic_flags:
		for flag_id: StringName in [&"flag.route.sanae.publicity.future_image_use_requires_asking", &"flag.route.sanae.publicity.boundary_repaired_by_practice", &"flag.route.sanae.guarantee.doubt_departure_change_protected"]:
			dispatcher.dispatch(state, SetFlagCommand.new(FlagState.from_value(flag_id, true)))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Sanae Promise integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
