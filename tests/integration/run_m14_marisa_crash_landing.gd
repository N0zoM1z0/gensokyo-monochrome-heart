extends SceneTree
## Traverses every Marisa response and both Broom Backseat outcomes.

const EVENT_ID: StringName = &"evt.mrs.crash_landing"
var _content := ContentRepository.new()
var _failures: Array[String] = []

func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Crash Landing content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	var tones: Array[StringName] = [&"direct", &"playful", &"patient", &"defiant"]
	for index: int in range(tones.size()):
		_run(graph, tones[index], &"clear" if index % 2 == 0 else &"assist_clear", index)
	_finish(_failures)

func _run(graph: EventGraphRecord, tone: StringName, mode_tag: StringName, index: int) -> void:
	var state := _state(StringName("p151%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach four crash responses" % tone)
	result = interpreter.choose_tone(tone)
	_expect(result.node_id == StringName("n_%s_line" % tone), "%s did not reach its cargo response" % tone)
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE and result.mode_context.mode_id == &"mini.mrs.broom_backseat", "%s did not reach Broom Backseat" % tone)
	result = interpreter.resume_mode(ModeResult.new(mode_tag))
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END, "%s did not complete Crash Landing" % tone)
	_expect(state.characters[&"char.marisa_kirisame"].route_stage == 1, "%s did not advance Marisa stage one" % tone)
	_expect(state.journal.entries.has(&"journal.mrs.crash_landing"), "%s omitted Marisa's Journal evidence" % tone)

func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1511)
	state.chapter_id = &"chapter.1"
	GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.forest_of_magic"))
	return state

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)

func _finish(failures: Array[String]) -> void:
	print("M14 Marisa Crash Landing integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
