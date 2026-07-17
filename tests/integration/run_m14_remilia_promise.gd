extends SceneTree
## Proves all explicit Remilia futures and a declined romance complete without coercion.

const EVENT_ID: StringName = &"evt.rml.promise"
const REMILIA: StringName = &"char.remilia_scarlet"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Remilia Promise content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	_run(graph, &"friendship", &"direct", &"standing_midnight_tea_friendship", 0)
	_run(graph, &"romance", &"playful", &"fallible_fate_chosen_together", 1)
	_run(graph, &"postponed", &"patient", &"answer_postponed_without_deadline", 2)
	_run(graph, &"undecided", &"defiant", &"midnight_future_left_unclaimed", 3)
	_run_romance_declined(graph)
	_finish(_failures)


func _run(graph: EventGraphRecord, intent: StringName, tone: StringName, outcome: StringName, index: int) -> void:
	var state := _state(StringName("p199%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.choice_id == &"choice.rml.promise.intent" and result.choice.options.size() == 4, "%s did not show four explicit futures" % intent)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line()
	if intent == &"romance":
		_expect(result.status == EventInterpreterResult.Status.WAIT_INPUT and result.node_id == &"n_romance_private", "romance did not lower the staging before consent")
		result = interpreter.advance_line()
		_expect(result.choice != null and result.choice.choice_id == &"choice.rml.promise.romance_consent" and result.choice.options.size() == 2, "romance did not wait for explicit private consent")
		result = interpreter.choose_tone(&"direct"); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == outcome, "%s did not complete Remilia's authored future" % intent)
	_expect(state.characters[REMILIA].route_stage == 7 and state.characters[REMILIA].route_intent == intent, "%s did not persist stage seven and intent" % intent)
	_expect(state.journal.entries.has(StringName("journal.rml.promise.%s" % intent)), "%s did not preserve Promise journal evidence" % intent)


func _run_romance_declined(graph: EventGraphRecord) -> void:
	var state := _state(&"p199_declined")
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line(); result = interpreter.choose_tone(&"playful")
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.choice_id == &"choice.rml.promise.romance_consent", "declined romance did not reach the explicit consent choice")
	result = interpreter.choose_tone(&"defiant"); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"romance_declined_future_unclaimed", "declined romance did not complete as an unclaimed future")
	_expect(state.characters[REMILIA].route_stage == 7 and state.characters[REMILIA].route_intent == &"undecided", "declined romance persisted a romantic intent")
	_expect(state.characters[REMILIA].relationship.strain == 0 and state.flags.has(&"flag.route.remilia.promise.consent_declined_without_penalty"), "declined romance added strain or omitted the no-penalty evidence")
	_expect(state.journal.entries.has(&"journal.rml.promise.romance_declined"), "declined romance omitted its consent-respecting journal evidence")


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1991)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.scarlet_devil_mansion"))
	for event_id: StringName in [&"evt.rml.the_audience", &"evt.rml.red_mist_etiquette", &"evt.sdm.small_chair", &"evt.rml.do_not_laugh_wrong_thing", &"evt.rml.fate_she_does_not_announce", &"evt.rml.predestination_exhibit"]:
		dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(REMILIA, 6))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Remilia Promise integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
