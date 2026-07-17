extends SceneTree
## Proves Kaguya's reception remains a chosen responsibility through every tone.

const EVENT_ID: StringName = &"evt.ein.elegance_and_boredom"
const KAGUYA: StringName = &"char.kaguya_houraisan"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Elegance and Boredom content could not load"])
		return
	_expect_predecessor_gate(_content.graph(EVENT_ID))
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _expect_predecessor_gate(graph: EventGraphRecord) -> void:
	var locked := EventInterpreter.new().start(graph, _state(&"p1824", false), _content)
	_expect(locked.is_error(), "Elegance and Boredom started before Five Impossible Errands completed")


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p182%d" % index), true)
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach reception choices" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"hospitality_chosen_without_performing_a_persona", "%s did not finish Kaguya's chosen hospitality" % tone)
	_expect(state.characters[KAGUYA].route_stage == 2 and state.journal.entries.has(&"journal.ein.elegance_and_boredom"), "%s did not preserve stage-two reception evidence" % tone)
	_expect(state.flags.has(&"flag.route.kaguya.hospitality_chosen"), "%s did not preserve Kaguya's chosen duty" % tone)
	if tone == &"defiant":
		_expect(state.flags.has(&"flag.route.kaguya.performance_not_owed"), "defiant did not reject compulsory princess performance")


func _state(profile_id: StringName, predecessor_complete: bool) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1821)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.eientei"))
	if predecessor_complete:
		dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.ein.five_impossibilities", &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.ein.five_impossibilities", &"complete"))
		dispatcher.dispatch(state, AdvanceRouteStageCommand.new(KAGUYA, 1))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Kaguya Elegance and Boredom integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
