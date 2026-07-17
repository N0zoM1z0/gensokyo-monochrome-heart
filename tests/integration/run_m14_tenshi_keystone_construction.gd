extends SceneTree
## Proves Keystone Construction treats both insufficient and excessive building as safe resets rather than rewards.

const EVENT_ID: StringName = &"evt.tsh.keystone_construction"
const TENSHI: StringName = &"char.tenshi_hinanawi"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Tenshi Keystone Construction content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	_run(graph, &"direct", &"clear", 0)
	_run(graph, &"playful", &"assist_clear", 1)
	_run(graph, &"patient", &"loss", 2)
	_run(graph, &"defiant", &"clear", 3)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, result_tag: StringName, index: int) -> void:
	var state := _state(StringName("p226%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the construction response" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE and result.mode_context.mode_id == &"mini.tsh.keystone_construction", "%s did not reach Keystone Construction" % tone)
	result = interpreter.resume_mode(ModeResult.new(result_tag)); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"keystone_span_stable_without_monument_or_bottleneck", "%s/%s did not complete a safe construction reset" % [tone, result_tag])
	_expect(state.characters[TENSHI].route_stage == 2 and state.journal.entries.has(&"journal.tsh.keystone_construction"), "%s/%s omitted construction evidence" % [tone, result_tag])
	_expect(state.flags.has(&"flag.route.tenshi.keystone.safe_span_completed") and state.flags.has(&"flag.route.tenshi.keystone.open_lane_preserved") and state.flags.has(&"flag.route.tenshi.keystone.competence_not_audience_score"), "%s/%s rewarded a monument or blocked lane" % [tone, result_tag])


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2261)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.heaven"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.tsh.entrance_tremor", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.tsh.entrance_tremor", &"complete"))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Tenshi Keystone Construction integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
