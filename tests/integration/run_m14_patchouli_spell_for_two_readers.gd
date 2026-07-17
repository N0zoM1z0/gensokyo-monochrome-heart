extends SceneTree
## Proves Patchouli's conceptual-margin spell preserves bounded roles across clear, assist, and loss.

const EVENT_ID: StringName = &"evt.pch.spell_for_two_readers"
const PATCHOULI: StringName = &"char.patchouli_knowledge"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["A Spell Written for Two Readers content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	_run(graph, &"direct", &"clear", 0)
	_run(graph, &"playful", &"assist_clear", 1)
	_run(graph, &"patient", &"loss", 2)
	_run(graph, &"defiant", &"clear", 3)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, mode_tag: StringName, index: int) -> void:
	var state := _state(StringName("p193%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach margin terms" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE and result.mode_context.mode_id == &"mini.pch.conceptual_margin", "%s did not reach the conceptual-margin minigame" % tone)
	result = interpreter.resume_mode(ModeResult.new(mode_tag))
	_expect(result.node_id == StringName("n_%s" % (&"assist" if mode_tag == &"assist_clear" else mode_tag)), "%s did not reach its %s result line" % [tone, mode_tag])
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"spell_read_by_two_without_takeover", "%s/%s did not complete the bounded spell" % [tone, mode_tag])
	_expect(state.characters[PATCHOULI].route_stage == 5 and state.journal.entries.has(&"journal.pch.spell_for_two_readers"), "%s/%s did not preserve spell evidence" % [tone, mode_tag])
	if tone == &"defiant": _expect(state.flags.has(&"flag.route.patchouli.margin_not_takeover"), "defiant did not preserve the no-takeover boundary")


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1931)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.scarlet_devil_mansion"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.pch.borrowing_argument", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.pch.borrowing_argument", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(PATCHOULI, 4))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Patchouli Spell for Two Readers integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
