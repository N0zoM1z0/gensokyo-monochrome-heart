extends SceneTree
## Proves every repair returns the floor and lets Remilia reclaim public dignity herself.

const EVENT_ID: StringName = &"evt.rml.do_not_laugh_wrong_thing"
const REMILIA: StringName = &"char.remilia_scarlet"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Do Not Laugh at the Wrong Thing content could not load"])
		return
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p196%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach public-repair responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"remilia_reclaimed_the_room_in_her_own_voice", "%s did not return Remilia's floor" % tone)
	_expect(state.characters[REMILIA].route_stage == 4 and state.journal.entries.has(&"journal.rml.do_not_laugh_wrong_thing"), "%s did not preserve rupture-and-repair evidence" % tone)
	_expect(state.flags.has(&"flag.route.remilia.laughter.floor_returned"), "%s spoke over Remilia instead of returning the floor" % tone)
	if tone == &"defiant":
		_expect(state.characters[REMILIA].relationship.respect == 1, "defiant did not earn respect for stopping the crowd")
		_expect(state.characters[REMILIA].relationship.strain == 1, "defiant omitted the public strain consequence")


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1961)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.scarlet_devil_mansion"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.sdm.small_chair", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.sdm.small_chair", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(REMILIA, 3))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Remilia Do Not Laugh at the Wrong Thing integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
