extends SceneTree
## Proves every reply lets Youmu reject the Archive's stopped farewell and reach stage six.
const EVENT_ID: StringName = &"evt.hgy.farewell_will_not_fall"
const YOUMU: StringName = &"char.youmu_konpaku"
var _content := ContentRepository.new(); var _failures: Array[String] = []
func _initialize() -> void:
	if not _content.load_sources().is_success(): _finish(["Farewell content could not load"]); return
	var tones: Array[StringName] = [&"direct", &"playful", &"patient", &"defiant"]
	for index: int in range(tones.size()): _run(_content.graph(EVENT_ID), tones[index], index)
	_finish(_failures)
func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p169%d" % index)); var interpreter := EventInterpreter.new(); var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line(); _expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach four farewell responses" % tone)
	result = interpreter.choose_tone(tone); _expect(result.node_id == StringName("n_%s_line" % tone), "%s did not reach its farewell response" % tone)
	result = interpreter.advance_line(); result = interpreter.advance_line(); _expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"farewell_allowed_to_fall", "%s did not complete Archive refusal" % tone)
	_expect(state.characters[YOUMU].route_stage == 6, "%s did not advance Youmu to stage six" % tone); _expect(state.journal.entries.has(&"journal.hgy.farewell_will_not_fall"), "%s omitted farewell Journal evidence" % tone)
func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []; for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []; for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1691); state.chapter_id = &"chapter.1"; var dispatcher := GameCommandDispatcher.new(); dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakugyokurou"))
	for event_id: StringName in [&"evt.hgy.garden_shift", &"evt.hgy.two_bodies_one_embarrassment", &"evt.hgy.duty_delegated", &"evt.hgy.cutting_wrong_problem", &"evt.hgy.meal_she_finishes"]: dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor")); dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(YOUMU, 5)); return state
func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
func _finish(failures: Array[String]) -> void:
	print("M14 Youmu Farewell integration: failures=%d" % failures.size()); for failure: String in failures: printerr("FAIL: %s" % failure); quit(0 if failures.is_empty() else 1)
