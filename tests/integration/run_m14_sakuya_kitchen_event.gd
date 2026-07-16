extends SceneTree
## Proves all four Kitchen After Midnight replies preserve Sakuya's consent boundary.

const EVENT_ID: StringName = &"evt.sdm.kitchen_after_midnight"
const SAKUYA: StringName = &"char.sakuya_izayoi"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Sakuya kitchen content could not load"])
		return
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p159%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	_expect(result.node_id == &"n003", "%s did not reach Sakuya's kitchen work" % tone)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach four permission-aware replies" % tone)
	result = interpreter.choose_tone(tone)
	_expect(result.node_id == StringName("n_%s_line" % tone), "%s did not reach its kitchen response" % tone)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"service_left_by_permission", "%s did not finish the kitchen event" % tone)
	_expect(state.characters[SAKUYA].route_stage == 3, "%s did not advance Sakuya to stage three" % tone)
	_expect(state.journal.entries.has(&"journal.sdm.kitchen_after_midnight"), "%s omitted kitchen Journal evidence" % tone)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1591)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.scarlet_devil_mansion"))
	for event_id: StringName in [&"evt.sdm.late_by_three_minutes", &"evt.sdm.corridor_no_dust"]:
		dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(SAKUYA, 2))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Sakuya kitchen event integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
