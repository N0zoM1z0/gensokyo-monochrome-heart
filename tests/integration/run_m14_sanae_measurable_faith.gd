extends SceneTree
## Proves publicity succeeds numerically, fails spiritually, and cannot bypass an image-consent breach.

const EVENT_ID: StringName = &"evt.mtn.measurable_faith"
const SANAE: StringName = &"char.sanae_kochiya"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Measurable Faith content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	for index: int in range(4): _run(graph, [&"direct", &"playful", &"patient", &"defiant"][index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p212%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the publicity boundary" % tone)
	_expect(state.characters[SANAE].relationship.strain == 1 and state.flags.has(&"flag.route.sanae.publicity.image_used_before_consent"), "%s bypassed authored boundary strain" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"successful_campaign_withdrawn_until_belief_and_consent_are_separate", "%s did not complete the campaign audit" % tone)
	_expect(state.characters[SANAE].route_stage == 4 and state.characters[SANAE].relationship.strain == 1, "%s flattered away or amplified the boundary conflict" % tone)
	_expect(state.flags.has(&"flag.route.sanae.publicity.image_withdrawn") and state.flags.has(&"flag.route.sanae.publicity.numerical_success_spiritual_failure") and state.flags.has(&"flag.route.sanae.publicity.future_image_use_requires_asking"), "%s omitted consent or belief evidence" % tone)
	_expect(state.journal.entries.has(&"journal.mtn.measurable_faith"), "%s omitted the campaign audit journal" % tone)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2121)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.moriya_shrine"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.sne.shrine_between_homes", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.sne.shrine_between_homes", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(SANAE, 3))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Sanae Measurable Faith integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
