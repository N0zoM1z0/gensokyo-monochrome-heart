extends SceneTree
## Proves Patchouli's Promise preserves every explicit future without turning open-ended access into ownership.

const EVENT_ID: StringName = &"evt.pch.promise"
const PATCHOULI: StringName = &"char.patchouli_knowledge"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Patchouli Promise content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	_run(graph, &"friendship", &"direct", &"reserved_reading_desk_kept", 0)
	_run(graph, &"romance", &"playful", &"borrowing_card_named_with_rules", 1)
	_run(graph, &"postponed", &"patient", &"desk_left_unassigned_without_penalty", 2)
	_run(graph, &"undecided", &"defiant", &"future_left_unindexed", 3)
	_finish(_failures)


func _run(graph: EventGraphRecord, intent: StringName, tone: StringName, outcome: StringName, index: int) -> void:
	var state := _state(StringName("p195%d" % index))
	if intent == &"undecided": GameCommandDispatcher.new().dispatch(state, SetRouteIntentCommand.new(PATCHOULI, &"romance"))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not show four complete futures" % intent)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == outcome, "%s did not complete Patchouli's authored future" % intent)
	_expect(state.characters[PATCHOULI].route_stage == 7 and state.characters[PATCHOULI].route_intent == intent, "%s did not persist stage seven and intent" % intent)
	_expect(state.journal.entries.has(StringName("journal.pch.promise.%s" % intent)), "%s omitted Promise journal evidence" % intent)
	if intent == &"romance": _expect(state.flags.has(&"flag.route.patchouli.no_due_date_has_rules"), "romance omitted the no-ownership rules")


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1951)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.scarlet_devil_mansion"))
	for event_id: StringName in [&"evt.pch.library_breathing_room", &"evt.pch.question_worth_asking", &"evt.pch.shared_silence_different_books", &"evt.pch.borrowing_argument", &"evt.pch.spell_for_two_readers", &"evt.pch.book_answers_everything"]:
		dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(PATCHOULI, 6))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Patchouli Promise integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
