extends SceneTree
## Proves Tenshi's unseen repair is the only route action that repairs the boundary strain.

const EVENT_ID: StringName = &"evt.tsh.repair_she_finishes"
const TENSHI: StringName = &"char.tenshi_hinanawi"
var _content := ContentRepository.new()
var _failures: Array[String] = []

func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Tenshi Repair She Finishes content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	var evaluator := EventPredicateEvaluator.new()
	var locked := _state(&"p229_locked", false)
	_expect(not evaluator.all_pass(evaluator.evaluate_all(graph.availability, locked)), "unwitnessed repair ignored the clear-no boundary evidence")
	_run(graph, &"direct", 0); _run(graph, &"playful", 1); _run(graph, &"patient", 2); _run(graph, &"defiant", 3)
	_finish(_failures)

func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p229_%d" % index), true)
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	_expect(result.status == EventInterpreterResult.Status.WAIT_INPUT and result.node_id == &"n_discovery", "%s did not show repair evidence before any character spoke" % tone)
	_expect(state.flags.has(&"flag.route.tenshi.repair.completed_without_audience") and state.flags.has(&"flag.route.tenshi.repair.no_credit_requested"), "%s did not persist the completed repair before any response was possible" % tone)
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_INPUT and result.node_id == &"n_tenshi", "%s did not reach Tenshi only after the independent repair evidence" % tone)
	result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the repair response" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"unwitnessed_repair_completed_and_strain_repaired_through_practice", "%s did not complete unwitnessed repair" % tone)
	_expect(state.characters[TENSHI].route_stage == 5 and state.characters[TENSHI].relationship.strain == 0, "%s did not repair strain through practice" % tone)
	_expect(state.flags.has(&"flag.route.tenshi.repair.completed_without_audience") and state.flags.has(&"flag.route.tenshi.repair.no_credit_requested") and state.flags.has(&"flag.route.tenshi.repair.boundary_strain_repaired_through_practice"), "%s omitted repair evidence" % tone)

func _state(profile_id: StringName, include_boundary: bool) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2291)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.heaven"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.tsh.attention_not_permission", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.tsh.attention_not_permission", &"complete"))
	if include_boundary:
		for flag_id: StringName in [&"flag.route.tenshi.boundary.clear_no_spoken", &"flag.route.tenshi.boundary.player_left_engagement", &"flag.route.tenshi.boundary.tenshi_stopped_without_escalation"]:
			dispatcher.dispatch(state, SetFlagCommand.new(FlagState.from_value(flag_id, true)))
		dispatcher.dispatch(state, AdjustRelationshipCommand.new(TENSHI, &"strain", 1))
	return state

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)

func _finish(failures: Array[String]) -> void:
	print("M14 Tenshi Repair She Finishes integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
