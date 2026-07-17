extends SceneTree
## Proves Mokou's warning preserves third-party agency in Kaguya's immortal rivalry.

const EVENT_ID: StringName = &"evt.ein.mokou_uninvited_honesty"
const KAGUYA: StringName = &"char.kaguya_houraisan"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Mokou's Uninvited Honesty content could not load"])
		return
	_expect_predecessor_gate(_content.graph(EVENT_ID))
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _expect_predecessor_gate(graph: EventGraphRecord) -> void:
	var result := EventInterpreter.new().start(graph, _state(&"p1864", false), _content)
	_expect(result.is_error(), "Mokou's warning started before the mortality conversation")


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p186%d" % index), true)
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach Mokou's agency responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"immortal_rivalry_named_without_claiming_anyone", "%s did not avoid treating the rivalry as ownership" % tone)
	_expect(state.characters[KAGUYA].route_stage == 5 and state.journal.entries.has(&"journal.ein.mokou_uninvited_honesty"), "%s did not preserve Mokou's warning" % tone)
	_expect(state.flags.has(&"flag.route.kaguya.rivalry_heard_without_ownership"), "%s did not retain the no-ownership boundary" % tone)
	var expected_flag: StringName = &"flag.route.kaguya.conduct_not_blessing"
	if tone == &"playful":
		expected_flag = &"flag.route.kaguya.rivalry_rule_chosen"
	elif tone == &"patient":
		expected_flag = &"flag.route.kaguya.warning_heard_without_defense"
	elif tone == &"defiant":
		expected_flag = &"flag.route.kaguya.not_prize_of_immortal_feud"
	_expect(state.flags.has(expected_flag), "%s did not preserve its non-ownership response" % tone)


func _state(profile_id: StringName, predecessor_complete: bool) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1861)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.eientei"))
	if predecessor_complete:
		dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.ein.short_lived_guest", &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.ein.short_lived_guest", &"complete"))
		dispatcher.dispatch(state, AdvanceRouteStageCommand.new(KAGUYA, 4))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Kaguya Mokou's Uninvited Honesty integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
