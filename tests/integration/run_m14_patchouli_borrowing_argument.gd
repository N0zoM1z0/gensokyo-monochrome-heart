extends SceneTree
## Proves Patchouli and Marisa negotiate responsible access without either becoming a caricature.

const EVENT_ID: StringName = &"evt.pch.borrowing_argument"
const PATCHOULI: StringName = &"char.patchouli_knowledge"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["The Borrowing Argument content could not load"])
		return
	_expect_predecessor_gate(_content.graph(EVENT_ID))
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _expect_predecessor_gate(graph: EventGraphRecord) -> void:
	var result := EventInterpreter.new().start(graph, _state(&"p191_locked", false), _content)
	_expect(result.is_error(), "borrowing argument started before the shared reading hour")


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p191%d" % index), true)
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach responsible-access responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"research_access_recorded_without_caricature", "%s did not complete a reviewable borrowing rule" % tone)
	_expect(state.characters[PATCHOULI].route_stage == 4 and state.journal.entries.has(&"journal.pch.borrowing_argument"), "%s did not preserve borrowing evidence" % tone)
	_expect(state.flags.has(&"flag.route.patchouli.borrowing_rule_chosen"), "%s did not preserve the shared rule" % tone)
	var expected_flag: StringName = &"flag.route.patchouli.renewable_ledger_rule"
	if tone == &"playful":
		expected_flag = &"flag.route.patchouli.annotations_count_as_return"
	elif tone == &"patient":
		expected_flag = &"flag.route.patchouli.both_terms_heard"
	elif tone == &"defiant":
		expected_flag = &"flag.route.patchouli.no_thief_or_hoarder_caricature"
	_expect(state.flags.has(expected_flag), "%s did not preserve its responsible-access term" % tone)


func _state(profile_id: StringName, predecessor_complete: bool) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1911)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.scarlet_devil_mansion"))
	if predecessor_complete:
		dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.pch.shared_silence_different_books", &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.pch.shared_silence_different_books", &"complete"))
		dispatcher.dispatch(state, AdvanceRouteStageCommand.new(PATCHOULI, 3))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Patchouli Borrowing Argument integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
