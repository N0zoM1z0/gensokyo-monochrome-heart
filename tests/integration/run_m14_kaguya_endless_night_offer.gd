extends SceneTree
## Proves Kaguya can refuse the Archive's perfect night and choose an unrepeatable dawn.

const EVENT_ID: StringName = &"evt.ein.endless_night_offer"
const KAGUYA: StringName = &"char.kaguya_houraisan"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["The Endless Night Offer content could not load"])
		return
	_expect_predecessor_gate(_content.graph(EVENT_ID))
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _expect_predecessor_gate(graph: EventGraphRecord) -> void:
	var result := EventInterpreter.new().start(graph, _state(&"p1874", false), _content)
	_expect(result.is_error(), "Archive offer started before Mokou's warning")


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p187%d" % index), true)
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach Archive-offer responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"dawn_arrived_by_kaguyas_choice", "%s did not let Kaguya choose dawn" % tone)
	_expect(state.characters[KAGUYA].route_stage == 6 and state.journal.entries.has(&"journal.ein.endless_night_offer"), "%s did not preserve Kaguya's self-chosen dawn" % tone)
	_expect(state.flags.has(&"flag.route.kaguya.endless_night_declined"), "%s did not decline the preserved night" % tone)
	var expected_flag: StringName = &"flag.route.kaguya.shared_night_not_copy"
	if tone == &"playful":
		expected_flag = &"flag.route.kaguya.next_night_may_surprise"
	elif tone == &"patient":
		expected_flag = &"flag.route.kaguya.dawn_chosen_without_prompt"
	elif tone == &"defiant":
		expected_flag = &"flag.route.kaguya.archive_cannot_fix_us"
	_expect(state.flags.has(expected_flag), "%s did not preserve its Archive boundary" % tone)


func _state(profile_id: StringName, predecessor_complete: bool) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1871)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.eientei"))
	if predecessor_complete:
		dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.ein.mokou_uninvited_honesty", &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.ein.mokou_uninvited_honesty", &"complete"))
		dispatcher.dispatch(state, AdvanceRouteStageCommand.new(KAGUYA, 5))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Kaguya Endless Night Offer integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
