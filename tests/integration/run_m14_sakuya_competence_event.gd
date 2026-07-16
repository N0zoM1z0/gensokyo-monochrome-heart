extends SceneTree
## Proves all four Competence Is Not Consent replies keep Sakuya's boundary explicit and route-continuing.

const EVENT_ID: StringName = &"evt.sdm.competence_not_consent"
const SAKUYA: StringName = &"char.sakuya_izayoi"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Sakuya competence-boundary content could not load"])
		return
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p160%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	_expect(result.node_id == &"n003", "%s did not reach Sakuya's presumed task" % tone)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach four boundary responses" % tone)
	result = interpreter.choose_tone(tone)
	_expect(result.node_id == StringName("n_%s_line" % tone), "%s did not reach its boundary response" % tone)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"task_not_assumed", "%s did not finish the competence event" % tone)
	_expect(state.characters[SAKUYA].route_stage == 4, "%s did not advance Sakuya to stage four" % tone)
	_expect(state.journal.entries.has(&"journal.sdm.competence_not_consent"), "%s omitted boundary Journal evidence" % tone)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1591)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.scarlet_devil_mansion"))
	for event_id: StringName in [&"evt.sdm.late_by_three_minutes", &"evt.sdm.corridor_no_dust", &"evt.sdm.kitchen_after_midnight"]:
		dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(SAKUYA, 3))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Sakuya competence boundary event integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
