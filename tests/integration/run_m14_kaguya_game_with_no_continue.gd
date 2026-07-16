extends SceneTree
## Proves Kaguya's one-life game advances without replaying or converting loss into a test.

const EVENT_ID: StringName = &"evt.ein.game_with_no_continue"
const KAGUYA: StringName = &"char.kaguya_houraisan"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["A Game With No Continue content could not load"])
		return
	_expect_predecessor_gate(_content.graph(EVENT_ID))
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _expect_predecessor_gate(graph: EventGraphRecord) -> void:
	var result := EventInterpreter.new().start(graph, _state(&"p183_locked", false), _content)
	_expect(result.is_error(), "one-life game started before Kaguya chose the reception")


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p183%d" % index), true)
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach finite-loss responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"one_life_game_lost_without_replacing_the_evening", "%s did not let the one-life game remain finished" % tone)
	_expect(state.characters[KAGUYA].route_stage == 3 and state.journal.entries.has(&"journal.ein.game_with_no_continue"), "%s did not preserve finite-loss evidence" % tone)
	_expect(state.flags.has(&"flag.route.kaguya.one_life_loss_accepted"), "%s did not preserve Kaguya's acceptance of the loss" % tone)
	if tone == &"defiant":
		_expect(state.flags.has(&"flag.route.kaguya.loss_not_a_test"), "defiant did not reject treating loss as a test")


func _state(profile_id: StringName, predecessor_complete: bool) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1831)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.eientei"))
	if predecessor_complete:
		dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.ein.elegance_and_boredom", &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.ein.elegance_and_boredom", &"complete"))
		dispatcher.dispatch(state, AdvanceRouteStageCommand.new(KAGUYA, 2))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Kaguya Game With No Continue integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
