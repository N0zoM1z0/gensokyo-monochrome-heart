extends SceneTree
## Proves Patchouli's logistics scene respects her stated pace across every authored response.

const EVENT_ID: StringName = &"evt.pch.library_breathing_room"
const PATCHOULI: StringName = &"char.patchouli_knowledge"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Library Breathing Room content could not load"])
		return
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(StringName("p189%d" % index), characters, locations, 1891)
	state.chapter_id = &"chapter.1"
	GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.scarlet_devil_mansion"))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach library logistics responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"library_air_restored_at_patchoulis_pace", "%s did not complete the library safely" % tone)
	_expect(state.characters[PATCHOULI].route_stage == 1 and state.journal.entries.has(&"journal.pch.library_breathing_room"), "%s did not preserve the library-care evidence" % tone)
	if tone == &"defiant": _expect(state.flags.has(&"flag.route.patchouli.pace_not_owed"), "defiant did not reject treating Patchouli's pace as owed")


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Patchouli Library Breathing Room integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
