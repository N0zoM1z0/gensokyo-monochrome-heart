extends SceneTree
## Proves Remilia destroys predestination proof herself without rewriting prior choices.

const EVENT_ID: StringName = &"evt.rml.predestination_exhibit"
const REMILIA: StringName = &"char.remilia_scarlet"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Predestination Exhibit content could not load"])
		return
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p198%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the proof responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"predestination_proof_destroyed_uncertainty_kept", "%s did not complete the Archive refusal" % tone)
	_expect(state.characters[REMILIA].route_stage == 6 and state.journal.entries.has(&"journal.rml.predestination_exhibit"), "%s did not preserve refusal evidence" % tone)
	_expect(state.flags.has(&"flag.route.remilia.predestination.proof_destroyed_by_remilia"), "%s made the protagonist destroy Remilia's proof" % tone)
	_expect(state.flags.has(&"flag.route.remilia.predestination.past_choices_preserved") and state.flags.has(&"flag.route.remilia.predestination.ability_remains_ambiguous"), "%s let Archive certainty rewrite choice or canonize the ability" % tone)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1981)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.scarlet_devil_mansion"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.rml.fate_she_does_not_announce", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.rml.fate_she_does_not_announce", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(REMILIA, 5))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Remilia Predestination Exhibit integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
