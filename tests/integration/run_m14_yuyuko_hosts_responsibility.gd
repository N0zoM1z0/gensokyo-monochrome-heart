extends SceneTree
## Proves Yuyuko changes the festival across clear, assist, and delayed procession outcomes.

const EVENT_ID: StringName = &"evt.yyk.hosts_responsibility"
const YUYUKO: StringName = &"char.yuyuko_saigyouji"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["A Host's Responsibility content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	_run(graph, &"direct", &"clear", 0)
	_run(graph, &"playful", &"assist_clear", 1)
	_run(graph, &"patient", &"loss", 2)
	_run(graph, &"defiant", &"clear", 3)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, mode_tag: StringName, index: int) -> void:
	var state := _state(StringName("p205%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the procession responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE and result.mode_context.mode_id == &"mini.yyk.spirit_procession_redirect", "%s did not reach the procession handoff" % tone)
	result = interpreter.resume_mode(ModeResult.new(mode_tag))
	var expected_node := StringName("n_%s" % (&"assist" if mode_tag == &"assist_clear" else mode_tag))
	_expect(result.node_id == expected_node, "%s did not reach its %s procession response" % [tone, mode_tag])
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"festival_changed_to_protect_guests_youmu_and_procession", "%s/%s did not complete host responsibility" % [tone, mode_tag])
	_expect(state.characters[YUYUKO].route_stage == 5 and state.journal.entries.has(&"journal.yyk.hosts_responsibility"), "%s/%s did not preserve host evidence" % [tone, mode_tag])
	_expect(state.flags.has(&"flag.route.yuyuko.host.procession_redirected") and state.flags.has(&"flag.route.yuyuko.host.guests_and_youmu_protected"), "%s/%s preserved appearance over people" % [tone, mode_tag])
	if tone == &"defiant": _expect(state.flags.has(&"flag.route.yuyuko.host.youmu_not_expendable"), "defiant left Youmu expendable at the choke point")


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2051)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakugyokurou"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.yyk.lightness_not_shallowness", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.yyk.lightness_not_shallowness", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(YUYUKO, 4))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Yuyuko Host's Responsibility integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
