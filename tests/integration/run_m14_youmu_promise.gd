extends SceneTree
## Proves Youmu's Promise persists every explicit future, including an undecided reset.
const EVENT_ID: StringName = &"evt.hgy.promise"
const YOUMU: StringName = &"char.youmu_konpaku"
var _content := ContentRepository.new(); var _failures: Array[String] = []
func _initialize() -> void:
	if not _content.load_sources().is_success(): _finish(["Youmu Promise content could not load"]); return
	var graph := _content.graph(EVENT_ID)
	_run(graph, &"friendship", &"direct", &"morning_training_invitation", 0); _run(graph, &"romance", &"playful", &"feeling_not_called_failure", 1); _run(graph, &"postponed", &"patient", &"morning_left_open", 2); _run(graph, &"undecided", &"defiant", &"future_not_ordered", 3)
	_finish(_failures)
func _run(graph: EventGraphRecord, intent: StringName, tone: StringName, outcome: StringName, index: int) -> void:
	var state := _state(StringName("p170%d" % index)); if intent == &"undecided": GameCommandDispatcher.new().dispatch(state, SetRouteIntentCommand.new(YOUMU, &"romance"))
	var interpreter := EventInterpreter.new(); var result := interpreter.start(graph, state, _content); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not see four explicit futures" % intent); result = interpreter.choose_tone(tone); _expect(result.node_id == StringName("n_%s" % intent), "%s did not reach its future line" % intent)
	result = interpreter.advance_line(); _expect(result.status == EventInterpreterResult.Status.END and result.outcome == outcome, "%s did not complete its authored Promise" % intent)
	_expect(state.characters[YOUMU].route_stage == 7 and state.characters[YOUMU].route_intent == intent, "%s did not persist stage seven and intent" % intent); _expect(state.journal.entries.has(StringName("journal.hgy.promise.%s" % intent)), "%s omitted Promise Journal evidence" % intent)
func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []; for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []; for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1701); state.chapter_id = &"chapter.1"; var dispatcher := GameCommandDispatcher.new(); dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakugyokurou"))
	for event_id: StringName in [&"evt.hgy.garden_shift", &"evt.hgy.two_bodies_one_embarrassment", &"evt.hgy.duty_delegated", &"evt.hgy.cutting_wrong_problem", &"evt.hgy.meal_she_finishes", &"evt.hgy.farewell_will_not_fall"]: dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor")); dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(YOUMU, 6)); return state
func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
func _finish(failures: Array[String]) -> void:
	print("M14 Youmu Promise integration: failures=%d" % failures.size()); for failure: String in failures: printerr("FAIL: %s" % failure); quit(0 if failures.is_empty() else 1)
