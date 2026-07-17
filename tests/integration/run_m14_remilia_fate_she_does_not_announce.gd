extends SceneTree
## Proves observable protection preserves Sakuya's labor and a future consultation boundary.

const EVENT_ID: StringName = &"evt.rml.fate_she_does_not_announce"
const REMILIA: StringName = &"char.remilia_scarlet"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["The Fate She Does Not Announce content could not load"])
		return
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p197%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the protection responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"protection_chosen_credit_refused_consultation_preserved", "%s did not complete the unannounced protection" % tone)
	_expect(state.characters[REMILIA].route_stage == 5 and state.journal.entries.has(&"journal.rml.fate_she_does_not_announce"), "%s did not preserve protection evidence" % tone)
	_expect(state.flags.has(&"flag.route.remilia.unannounced_fate.protection_observed") and state.flags.has(&"flag.route.remilia.unannounced_fate.credit_refused"), "%s replaced observable care with a public fate claim" % tone)
	_expect(state.flags.has(&"flag.route.remilia.unannounced_fate.sakuya_agency_preserved"), "%s erased Sakuya's planning labor" % tone)
	if tone == &"defiant": _expect(state.flags.has(&"flag.route.remilia.unannounced_fate.consultation_required"), "defiant did not preserve consultation before future protection")


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1971)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.scarlet_devil_mansion"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.rml.do_not_laugh_wrong_thing", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.rml.do_not_laugh_wrong_thing", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(REMILIA, 4))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Remilia Fate She Does Not Announce integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
