extends SceneTree
## Proves Red Mist Etiquette protects each guest path across clear, assist, and loss.

const EVENT_ID: StringName = &"evt.rml.red_mist_etiquette"
const REMILIA: StringName = &"char.remilia_scarlet"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Red Mist Etiquette content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	_run(graph, &"direct", &"clear", 0)
	_run(graph, &"playful", &"assist_clear", 1)
	_run(graph, &"patient", &"loss", 2)
	_run(graph, &"defiant", &"clear", 3)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, mode_tag: StringName, index: int) -> void:
	var state := _state(StringName("p194%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the escort responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE and result.mode_context.mode_id == &"mini.rml.red_mist_etiquette", "%s did not reach the mist escort" % tone)
	result = interpreter.resume_mode(ModeResult.new(mode_tag))
	var expected_node := StringName("n_%s" % (&"assist" if mode_tag == &"assist_clear" else mode_tag))
	_expect(result.node_id == expected_node, "%s did not reach its %s escort response" % [tone, mode_tag])
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"three_guest_paths_held_without_ranking_worth", "%s/%s did not complete the procession" % [tone, mode_tag])
	_expect(state.characters[REMILIA].route_stage == 2 and state.journal.entries.has(&"journal.rml.red_mist_etiquette"), "%s/%s did not preserve etiquette evidence" % [tone, mode_tag])
	_expect(state.flags.has(&"flag.route.remilia.etiquette.guest_paths_preserved"), "%s/%s did not preserve the three passage needs" % [tone, mode_tag])
	if tone == &"defiant": _expect(state.flags.has(&"flag.route.remilia.etiquette.rule_revised"), "defiant did not revise the unsafe ceremonial lane")


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1941)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.scarlet_devil_mansion"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.rml.the_audience", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.rml.the_audience", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(REMILIA, 1))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Remilia Red Mist Etiquette integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
