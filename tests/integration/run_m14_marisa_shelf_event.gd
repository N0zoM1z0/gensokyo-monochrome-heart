extends SceneTree
## Covers Marisa's ask-before-reorganizing boundary test through all four tones.

const EVENT_ID: StringName = &"evt.mrs.shelf_marked_later"
var _content := ContentRepository.new()
var _failures: Array[String] = []

func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Shelf Marked Later content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(graph, EventGraphValidator.TONES[index], index)
	_finish(_failures)

func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p153%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the shelf boundary choice" % tone)
	result = interpreter.choose_tone(tone)
	_expect(result.node_id == StringName("n_%s_line" % tone), "%s did not reach its boundary response" % tone)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"shelf_left_with_its_history", "%s did not complete the shelf boundary" % tone)
	_expect(state.characters[&"char.marisa_kirisame"].route_stage == 3, "%s did not advance Marisa to stage three" % tone)
	_expect(state.journal.entries.has(&"journal.mrs.shelf_marked_later"), "%s omitted shelf Journal evidence" % tone)

func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1531)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.forest_of_magic"))
	for event_id: StringName in [&"evt.mrs.crash_landing", &"evt.mrs.field_notes"]:
		dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(&"char.marisa_kirisame", 2))
	return state

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)

func _finish(failures: Array[String]) -> void:
	print("M14 Marisa shelf boundary integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
