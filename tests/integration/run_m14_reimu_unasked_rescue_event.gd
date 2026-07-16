extends SceneTree
## Covers Reimu's unasked protection, every tone, all Boundary Stain outcomes, and shared repair.

const EVENT_ID: StringName = &"evt.hkr.unasked_rescue"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["unasked rescue content could not be loaded"])
		return
	var graph := _content.graph(EVENT_ID)
	var tones: Array[StringName] = [&"direct", &"playful", &"patient", &"defiant"]
	var results: Array[StringName] = [&"clear", &"assist_clear", &"loss", &"clear"]
	for index: int in range(tones.size()):
		_run(graph, tones[index], results[index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, result_tag: StringName, index: int) -> void:
	var state := _state(StringName("p146%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	_expect(result.node_id == &"n003", "%s did not reach collapse" % tone)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	result = interpreter.choose_tone(tone)
	_expect(result.node_id == StringName("n_%s_line" % tone), "%s did not receive rescue response" % tone)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE and result.mode_context.mode_id == &"danmaku.hkr.boundary_stain", "%s did not reach Reimu's protection handoff" % tone)
	result = interpreter.resume_mode(ModeResult.new(result_tag))
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE and result.mode_context.mode_id == &"mini.hkr.quiet_chore", "%s did not reach accepted repair" % tone)
	result = interpreter.resume_mode(ModeResult.new(&"clear"))
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"protection_received_without_debt", "%s did not complete rescue without debt" % tone)
	_expect(state.characters[&"char.reimu_hakurei"].route_stage == 4, "%s did not advance Reimu to stage 4" % tone)
	_expect(state.journal.entries.has(&"journal.hkr.unasked_rescue") and &"flag.route.reimu.repair_accepted" in state.flags, "%s omitted repair evidence" % tone)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1465)
	state.chapter_id = &"chapter.1"
	state.time_slot = &"night"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakurei_shrine"))
	for event_id: StringName in [&"evt.hkr.empty_cushion", &"evt.hkr.offerings_without_owners", &"evt.hkr.day_nothing_happens", &"evt.hkr.shrine_not_guesthouse"]:
		dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(&"char.reimu_hakurei", 3))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Reimu unasked rescue integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
