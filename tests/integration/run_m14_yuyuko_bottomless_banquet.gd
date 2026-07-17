extends SceneTree
## Proves Bottomless Banquet reads hosting cues across clear, assist, and reset outcomes.

const EVENT_ID: StringName = &"evt.yyk.bottomless_banquet"
const YUYUKO: StringName = &"char.yuyuko_saigyouji"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Bottomless Banquet content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	_run(graph, &"direct", &"clear", 0)
	_run(graph, &"playful", &"assist_clear", 1)
	_run(graph, &"patient", &"loss", 2)
	_run(graph, &"defiant", &"clear", 3)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, mode_tag: StringName, index: int) -> void:
	var state := _state(StringName("p201%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the banquet responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE and result.mode_context.mode_id == &"mini.yyk.bottomless_banquet", "%s did not reach the banquet handoff" % tone)
	result = interpreter.resume_mode(ModeResult.new(mode_tag))
	var expected_node := StringName("n_%s" % (&"assist" if mode_tag == &"assist_clear" else mode_tag))
	_expect(result.node_id == expected_node, "%s did not reach its %s banquet response" % [tone, mode_tag])
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"banquet_balanced_by_hosting_cues_not_appetite_score", "%s/%s did not complete the hosted banquet" % [tone, mode_tag])
	_expect(state.characters[YUYUKO].route_stage == 1 and state.journal.entries.has(&"journal.yyk.bottomless_banquet"), "%s/%s did not preserve banquet evidence" % [tone, mode_tag])
	_expect(state.flags.has(&"flag.route.yuyuko.banquet.hosting_skill_visible") and state.flags.has(&"flag.route.yuyuko.banquet.conversation_cues_read"), "%s/%s reduced Yuyuko to an appetite score" % [tone, mode_tag])
	if tone == &"defiant": _expect(state.flags.has(&"flag.route.yuyuko.banquet.youmu_labor_bounded"), "defiant did not bound Youmu's kitchen labor")


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2011)
	state.chapter_id = &"chapter.1"
	GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.hakugyokurou"))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Yuyuko Bottomless Banquet integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
