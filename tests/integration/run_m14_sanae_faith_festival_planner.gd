extends SceneTree
## Proves Sanae balances festival obligations across clear, assist, and stopped-plan outcomes.

const EVENT_ID: StringName = &"evt.sne.faith_festival_planner"
const SANAE: StringName = &"char.sanae_kochiya"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Faith Festival Planner content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	_run(graph, &"direct", &"clear", 0)
	_run(graph, &"playful", &"assist_clear", 1)
	_run(graph, &"patient", &"loss", 2)
	_run(graph, &"defiant", &"clear", 3)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, mode_tag: StringName, index: int) -> void:
	var state := _state(StringName("p209%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the festival-planning responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE and result.mode_context.mode_id == &"mini.sne.faith_festival_planner", "%s did not reach the festival planner" % tone)
	result = interpreter.resume_mode(ModeResult.new(mode_tag))
	var expected_node := StringName("n_%s" % (&"assist" if mode_tag == &"assist_clear" else mode_tag))
	_expect(result.node_id == expected_node, "%s did not reach its %s planning response" % [tone, mode_tag])
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"festival_planned_as_three_obligations_not_one_score", "%s/%s did not complete the bounded plan" % [tone, mode_tag])
	_expect(state.characters[SANAE].route_stage == 1 and state.journal.entries.has(&"journal.sne.faith_festival_planner"), "%s/%s did not preserve route evidence" % [tone, mode_tag])
	_expect(state.flags.has(&"flag.route.sanae.festival.plan_authored_by_sanae") and state.flags.has(&"flag.route.sanae.festival.safety_and_sincerity_non_negotiable"), "%s/%s reduced the plan to an audience score" % [tone, mode_tag])
	if mode_tag == &"loss": _expect(state.characters[SANAE].relationship.strain == 0, "stopping an unfit plan added route strain")


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2091)
	state.chapter_id = &"chapter.1"
	GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.moriya_shrine"))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Sanae Faith Festival Planner integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
