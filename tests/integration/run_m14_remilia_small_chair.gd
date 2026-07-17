extends SceneTree
## Proves the reserved Small Chair event becomes invited private rest without infantilization.

const EVENT_ID: StringName = &"evt.sdm.small_chair"
const REMILIA: StringName = &"char.remilia_scarlet"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["The Small Chair Behind the Throne content could not load"])
		return
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p195%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the private-chair responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"private_rest_shared_without_becoming_exhibit", "%s did not complete invited private rest" % tone)
	_expect(state.characters[REMILIA].route_stage == 3 and state.journal.entries.has(&"journal.sdm.small_chair"), "%s did not preserve the private-chair evidence" % tone)
	_expect(state.flags.has(&"flag.route.remilia.small_chair.private_access_invited"), "%s treated access as accidental or uninvited" % tone)
	if tone == &"patient": _expect(state.flags.has(&"flag.route.remilia.small_chair.waited_for_invitation"), "patient sat without waiting for Remilia's invitation")
	if tone == &"defiant": _expect(state.flags.has(&"flag.route.remilia.small_chair.office_not_body"), "defiant did not distinguish office from body")


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1951)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.scarlet_devil_mansion"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.rml.red_mist_etiquette", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.rml.red_mist_etiquette", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(REMILIA, 2))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Remilia Small Chair integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
