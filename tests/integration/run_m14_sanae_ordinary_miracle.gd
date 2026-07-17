extends SceneTree
## Proves Sanae's ordinary repair matters without power, spectacle, or transferred agency.

const EVENT_ID: StringName = &"evt.sne.ordinary_miracle"
const SANAE: StringName = &"char.sanae_kochiya"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["The Ordinary Miracle content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	for index: int in range(4): _run(graph, [&"direct", &"playful", &"patient", &"defiant"][index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p213%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the ordinary-repair responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"ordinary_repair_supports_what_the_protagonist_carries_next", "%s did not complete the repair" % tone)
	_expect(state.characters[SANAE].route_stage == 5 and state.characters[SANAE].relationship.strain == 0, "%s did not continue stage five without strain" % tone)
	_expect(state.flags.has(&"flag.route.sanae.ordinary.journal_strap_repaired") and state.flags.has(&"flag.route.sanae.ordinary.power_not_required_for_care"), "%s replaced repair with a miracle shortcut" % tone)
	_expect(state.journal.entries.has(&"journal.sne.ordinary_miracle"), "%s omitted ordinary-care journal evidence" % tone)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2131)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.moriya_shrine"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.mtn.measurable_faith", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.mtn.measurable_faith", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(SANAE, 4))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Sanae Ordinary Miracle integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
