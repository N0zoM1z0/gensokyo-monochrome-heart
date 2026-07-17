extends SceneTree
## Proves every response withdraws reckless self-sacrifice while Eirin's authored anger remains and the route continues.

const EVENT_ID: StringName = &"evt.eir.do_not_volunteer"
const EIRIN: StringName = &"char.eirin_yagokoro"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Do Not Volunteer as an Experiment content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	var index := 0
	for tone: StringName in [&"direct", &"playful", &"patient", &"defiant"]:
		_run(graph, tone, index); index += 1
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p220%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach withdrawal responses" % tone)
	_expect(state.characters[EIRIN].relationship.strain == 1 and state.flags.has(&"flag.route.eirin.experiment.reckless_offer_made"), "%s bypassed the authored self-sacrifice conflict" % tone)
	result = interpreter.choose_tone(tone)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.node_id == &"n004", "%s closed the protocol before the player withdrew" % tone)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"reckless_experiment_offer_withdrawn_anger_and_unknown_remain", "%s did not complete the boundary conflict" % tone)
	_expect(state.characters[EIRIN].route_stage == 4 and state.characters[EIRIN].relationship.strain == 1, "%s erased or amplified Eirin's authored anger" % tone)
	_expect(state.flags.has(&"flag.route.eirin.experiment.offer_withdrawn") and state.flags.has(&"flag.route.eirin.experiment.self_sacrifice_rejected") and state.flags.has(&"flag.route.eirin.experiment.missing_result_accepted"), "%s failed to withdraw sacrifice or keep the result unknown" % tone)
	_expect(state.journal.entries.has(&"journal.eir.do_not_volunteer"), "%s omitted the anger evidence" % tone)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2201)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.eientei"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.eir.practical_care", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.eir.practical_care", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(EIRIN, 3))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Eirin Do Not Volunteer integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
