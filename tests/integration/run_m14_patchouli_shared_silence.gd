extends SceneTree
## Proves Patchouli's shared reading hour preserves silence as an authored, non-rejecting boundary.

const EVENT_ID: StringName = &"evt.pch.shared_silence_different_books"
const PATCHOULI: StringName = &"char.patchouli_knowledge"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Shared Silence content could not load"])
		return
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(StringName("p190%d" % index), characters, locations, 1901)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.scarlet_devil_mansion"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.pch.question_worth_asking", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.pch.question_worth_asking", &"complete"))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line(); result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"shared_reading_left_uninterrupted", "%s did not preserve shared reading" % tone)
	_expect(state.characters[PATCHOULI].route_stage == 3 and state.journal.entries.has(&"journal.pch.shared_silence_different_books"), "%s did not preserve silence evidence" % tone)
	if tone == &"patient": _expect(state.flags.has(&"flag.route.patchouli.companion_comments_disabled"), "patient did not leave companion comments disabled")
	if tone == &"defiant": _expect(state.flags.has(&"flag.route.patchouli.silence_not_coldness"), "defiant did not reject reading silence as coldness")


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Patchouli Shared Silence integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
