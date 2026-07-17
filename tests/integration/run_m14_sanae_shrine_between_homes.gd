extends SceneTree
## Proves homesickness preserves two homes while Sanae repairs the one she lives in now.

const EVENT_ID: StringName = &"evt.sne.shrine_between_homes"
const SANAE: StringName = &"char.sanae_kochiya"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["A Shrine Between Homes content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	for index: int in range(4): _run(graph, [&"direct", &"playful", &"patient", &"defiant"][index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p211%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the two-homes responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"two_homes_remain_true_while_the_present_room_is_repaired", "%s did not complete the threshold repair" % tone)
	_expect(state.characters[SANAE].route_stage == 3 and state.characters[SANAE].relationship.strain == 0, "%s did not continue stage three without strain" % tone)
	_expect(state.flags.has(&"flag.route.sanae.homes.two_truths_kept") and state.flags.has(&"flag.route.sanae.homes.present_threshold_repaired"), "%s erased a home or left the present room temporary" % tone)
	_expect(state.journal.entries.has(&"journal.sne.shrine_between_homes"), "%s omitted the homes journal" % tone)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2111)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.moriya_shrine"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.sne.outside_world_shorthand", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.sne.outside_world_shorthand", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(SANAE, 2))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Sanae Shrine Between Homes integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
