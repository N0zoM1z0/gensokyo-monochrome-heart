extends SceneTree
## Proves all Yuyuko futures and a declined final sweet complete without food debt or coercion.

const EVENT_ID: StringName = &"evt.hgy.last_sweet"
const YUYUKO: StringName = &"char.yuyuko_saigyouji"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["The Last Sweet content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	_run(graph, &"friendship", &"direct", &"hungry_guest_with_story_friendship", 0)
	_run(graph, &"romance", &"playful", &"final_sweet_accepted_as_finite_romance", 1)
	_run(graph, &"postponed", &"patient", &"relationship_postponed_sweet_finished_without_debt", 2)
	_run(graph, &"undecided", &"defiant", &"future_unclaimed_last_bite_shared", 3)
	_run_romance_declined(graph)
	_finish(_failures)


func _run(graph: EventGraphRecord, intent: StringName, tone: StringName, outcome: StringName, index: int) -> void:
	var state := _state(StringName("p207%d" % index))
	if intent == &"undecided":
		GameCommandDispatcher.new().dispatch(state, SetRouteIntentCommand.new(YUYUKO, &"romance"))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.choice_id == &"choice.hgy.last_sweet.promise.intent" and result.choice.options.size() == 4, "%s did not show four explicit futures" % intent)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line()
	if intent == &"romance":
		_expect(result.choice != null and result.choice.choice_id == &"choice.hgy.last_sweet.promise.romance_consent" and result.choice.options.size() == 2, "romance did not wait for separate final-sweet consent")
		result = interpreter.choose_tone(&"direct"); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == outcome, "%s did not complete Yuyuko's authored future" % intent)
	_expect(state.characters[YUYUKO].route_stage == 7 and state.characters[YUYUKO].route_intent == intent, "%s did not persist stage seven and intent" % intent)
	_expect(state.journal.entries.has(StringName("journal.hgy.last_sweet.promise.%s" % intent)), "%s did not preserve Last Sweet journal evidence" % intent)


func _run_romance_declined(graph: EventGraphRecord) -> void:
	var state := _state(&"p2074")
	GameCommandDispatcher.new().dispatch(state, SetRouteIntentCommand.new(YUYUKO, &"romance"))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line(); result = interpreter.choose_tone(&"playful"); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.choice_id == &"choice.hgy.last_sweet.promise.romance_consent", "declined romance did not reach the explicit consent choice")
	result = interpreter.choose_tone(&"defiant"); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"final_sweet_declined_future_unclaimed", "declined sweet did not complete as an unclaimed future")
	_expect(state.characters[YUYUKO].route_stage == 7 and state.characters[YUYUKO].route_intent == &"undecided", "declined sweet persisted romance")
	_expect(state.characters[YUYUKO].relationship.strain == 0 and state.flags.has(&"flag.route.yuyuko.promise.final_sweet_declined_without_penalty"), "declined sweet added strain or omitted no-penalty evidence")
	_expect(state.journal.entries.has(&"journal.hgy.last_sweet.promise.romance_declined"), "declined sweet omitted journal evidence")


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2071)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakugyokurou"))
	for event_id: StringName in [&"evt.yyk.bottomless_banquet", &"evt.yyk.joke_about_death", &"evt.yyk.empty_plate", &"evt.yyk.lightness_not_shallowness", &"evt.yyk.hosts_responsibility", &"evt.yyk.feast_without_ending"]:
		dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(YUYUKO, 6))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Yuyuko Last Sweet integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
