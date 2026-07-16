extends SceneTree
## Covers every response tone for Marisa's recorded-failure competence beat.

const EVENT_ID: StringName = &"evt.mrs.field_notes"
var _content := ContentRepository.new()
var _failures: Array[String] = []

func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Field Notes content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(graph, EventGraphValidator.TONES[index], index)
	_finish(_failures)

func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p152%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	_expect(result.node_id == &"n003", "%s did not reach the field marks" % tone)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the four Field Notes answers" % tone)
	result = interpreter.choose_tone(tone)
	_expect(result.node_id == StringName("n_%s_line" % tone), "%s did not reach its authored response" % tone)
	result = interpreter.advance_line()
	_expect(result.node_id == &"n_after", "%s omitted Marisa's next-attempt afterbeat" % tone)
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"failure_recorded_for_next_attempt", "%s did not complete Field Notes" % tone)
	_expect(state.characters[&"char.marisa_kirisame"].route_stage == 2, "%s did not advance Marisa to stage two" % tone)
	_expect(state.journal.entries.has(&"journal.mrs.field_notes"), "%s omitted Field Notes Journal evidence" % tone)

func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1521)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.forest_of_magic"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.mrs.crash_landing", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.mrs.crash_landing", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(&"char.marisa_kirisame", 1))
	return state

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)

func _finish(failures: Array[String]) -> void:
	print("M14 Marisa Field Notes integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
