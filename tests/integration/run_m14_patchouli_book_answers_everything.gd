extends SceneTree
## Proves Patchouli leaves predictive pages blank by her own editorial decision.

const EVENT_ID: StringName = &"evt.pch.book_answers_everything"
const PATCHOULI: StringName = &"char.patchouli_knowledge"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["The Book That Answers Everything content could not load"])
		return
	_expect_predecessor_gate(_content.graph(EVENT_ID))
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _expect_predecessor_gate(graph: EventGraphRecord) -> void:
	var result := EventInterpreter.new().start(graph, _state(&"p1944", false), _content)
	_expect(result.is_error(), "predictive book started before the two-reader spell")


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p194%d" % index), true)
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach predictive-book responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"last_pages_left_blank_by_patchouli", "%s did not leave Patchouli's final pages blank" % tone)
	_expect(state.characters[PATCHOULI].route_stage == 6 and state.journal.entries.has(&"journal.pch.book_answers_everything"), "%s did not preserve blank-page evidence" % tone)
	_expect(state.flags.has(&"flag.route.patchouli.last_pages_blank"), "%s did not preserve Patchouli's editorial choice" % tone)
	var expected_flag: StringName = &"flag.route.patchouli.answer_after_question"
	if tone == &"playful":
		expected_flag = &"flag.route.patchouli.unwritten_question_kept"
	elif tone == &"patient":
		expected_flag = &"flag.route.patchouli.blank_pages_self_chosen"
	elif tone == &"defiant":
		expected_flag = &"flag.route.patchouli.future_conversations_not_consented"
	_expect(state.flags.has(expected_flag), "%s did not preserve its future-authorship boundary" % tone)


func _state(profile_id: StringName, predecessor_complete: bool) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1941)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.scarlet_devil_mansion"))
	if predecessor_complete:
		dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.pch.spell_for_two_readers", &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.pch.spell_for_two_readers", &"complete"))
		dispatcher.dispatch(state, AdvanceRouteStageCommand.new(PATCHOULI, 5))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Patchouli Book Answers Everything integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
