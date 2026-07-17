extends SceneTree
## Proves every tone recognizes Sanae's adapted shorthand without reducing her past to a gag.

const EVENT_ID: StringName = &"evt.sne.outside_world_shorthand"
const SANAE: StringName = &"char.sanae_kochiya"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Outside World Shorthand content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	for index: int in range(4): _run(graph, [&"direct", &"playful", &"patient", &"defiant"][index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p210%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach shorthand responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"outside_shorthand_kept_as_an_adapted_language", "%s did not complete the relabeling" % tone)
	_expect(state.characters[SANAE].route_stage == 2 and state.characters[SANAE].relationship.strain == 0, "%s did not continue stage two without strain" % tone)
	_expect(state.flags.has(&"flag.route.sanae.shorthand.adaptation_not_erasure") and state.flags.has(&"flag.route.sanae.shorthand.crates_relabelled_for_present_workers"), "%s erased either Sanae's past or present workers" % tone)
	_expect(state.journal.entries.has(&"journal.sne.outside_world_shorthand"), "%s omitted shorthand journal evidence" % tone)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2101)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.moriya_shrine"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.sne.faith_festival_planner", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.sne.faith_festival_planner", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(SANAE, 1))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Sanae Outside World Shorthand integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
