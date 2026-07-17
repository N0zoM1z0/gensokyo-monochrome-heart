extends SceneTree
## Proves Kaguya's mortality conversation offers finite presence without an impossible promise.

const EVENT_ID: StringName = &"evt.ein.short_lived_guest"
const KAGUYA: StringName = &"char.kaguya_houraisan"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["The Short-Lived Guest content could not load"])
		return
	_expect_predecessor_gate(_content.graph(EVENT_ID))
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _expect_predecessor_gate(graph: EventGraphRecord) -> void:
	var result := EventInterpreter.new().start(graph, _state(&"p1854", false), _content)
	_expect(result.is_error(), "mortality conversation started before Kaguya accepted a finite loss")


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p185%d" % index), true)
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach finite-presence responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"finite_meeting_chosen_without_an_eternal_promise", "%s did not retain Kaguya's finite meeting" % tone)
	_expect(state.characters[KAGUYA].route_stage == 4 and state.journal.entries.has(&"journal.ein.short_lived_guest"), "%s did not preserve the mortality discussion" % tone)
	_expect(state.flags.has(&"flag.route.kaguya.short_lived_guest_heard"), "%s did not preserve Kaguya's honest answer" % tone)
	var expected_flag: StringName = &"flag.route.kaguya.mortality_named_without_promise"
	if tone == &"playful":
		expected_flag = &"flag.route.kaguya.next_evening_chosen"
	elif tone == &"patient":
		expected_flag = &"flag.route.kaguya.silence_not_filled_with_forever"
	elif tone == &"defiant":
		expected_flag = &"flag.route.kaguya.mortal_life_not_a_debt"
	_expect(state.flags.has(expected_flag), "%s did not preserve its finite-presence boundary" % tone)


func _state(profile_id: StringName, predecessor_complete: bool) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1851)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.eientei"))
	if predecessor_complete:
		dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.ein.game_with_no_continue", &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.ein.game_with_no_continue", &"complete"))
		dispatcher.dispatch(state, AdvanceRouteStageCommand.new(KAGUYA, 3))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Kaguya Short-Lived Guest integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
