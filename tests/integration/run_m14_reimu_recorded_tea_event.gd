extends SceneTree
## Proves Reimu rejects the Archive copy through every tone and every tea result.

const EVENT_ID: StringName = &"evt.hkr.perfectly_recorded_tea"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["recorded tea content could not be loaded"])
		return
	var graph := _content.graph(EVENT_ID)
	var tones: Array[StringName] = [&"direct", &"playful", &"patient", &"defiant"]
	var results: Array[StringName] = [&"excellent", &"clear", &"loss", &"clear"]
	for index: int in range(tones.size()):
		_run(graph, tones[index], results[index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, result_tag: StringName, index: int) -> void:
	var state := _state(StringName("p147%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	_expect(result.node_id == &"n003", "%s did not reach Archive offer" % tone)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	result = interpreter.choose_tone(tone)
	_expect(result.node_id == StringName("n_%s_line" % tone), "%s did not reach recorded-tea response" % tone)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE and result.mode_context.mode_id == &"mini.shrine.tea_temperature", "%s did not reach finite-tea handoff" % tone)
	result = interpreter.resume_mode(ModeResult.new(result_tag))
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"afternoon_left_to_change", "%s did not complete finite afternoon" % tone)
	_expect(state.characters[&"char.reimu_hakurei"].route_stage == 5, "%s did not advance stage five" % tone)
	_expect(state.journal.entries.has(&"journal.hkr.perfectly_recorded_tea"), "%s omitted Archive-refusal Journal entry" % tone)
	var completion := state.flags.get(&"flag.route.reimu.archive.finite_afternoon_chosen") as FlagState
	_expect(completion != null and completion.value() == true, "%s did not persist finite-afternoon choice" % tone)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1476)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakurei_shrine"))
	for event_id: StringName in [&"evt.hkr.empty_cushion", &"evt.hkr.offerings_without_owners", &"evt.hkr.day_nothing_happens", &"evt.hkr.shrine_not_guesthouse", &"evt.hkr.unasked_rescue"]:
		dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(&"char.reimu_hakurei", 4))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Reimu recorded tea integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
