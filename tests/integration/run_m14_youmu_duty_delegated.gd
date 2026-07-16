extends SceneTree
## Proves every response preserves Youmu's explicit delegated boundary and stage-three progress.

const EVENT_ID: StringName = &"evt.hgy.duty_delegated"
const YOUMU: StringName = &"char.youmu_konpaku"
var _content := ContentRepository.new()
var _failures: Array[String] = []

func _initialize() -> void:
	if not _content.load_sources().is_success(): _finish(["Duty Delegated content could not load"]); return
	var tones: Array[StringName] = [&"direct", &"playful", &"patient", &"defiant"]
	for index: int in range(tones.size()): _run(_content.graph(EVENT_ID), tones[index], index)
	_finish(_failures)

func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p166%d" % index)); var interpreter := EventInterpreter.new(); var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach four delegation responses" % tone)
	result = interpreter.choose_tone(tone); _expect(result.node_id == StringName("n_%s_line" % tone), "%s did not reach its boundary response" % tone)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	var expected_outcome: StringName = &"watch_declined_with_observation" if tone == &"defiant" else &"east_path_watched_without_command"
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == expected_outcome, "%s did not finish delegated watch" % tone)
	_expect(state.characters[YOUMU].route_stage == 3, "%s did not advance Youmu to stage three" % tone)
	var journal_id: StringName = &"journal.hgy.duty_delegated.declined" if tone == &"defiant" else &"journal.hgy.duty_delegated"
	_expect(state.journal.entries.has(journal_id), "%s omitted delegation Journal evidence" % tone)
	_expect(state.event_flags.has(&"flag.route.youmu.delegation_declined") if tone == &"defiant" else state.event_flags.has(&"flag.route.youmu.delegation_accepted"), "%s did not persist the correct delegation boundary" % tone)

func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []; for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []; for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1661); state.chapter_id = &"chapter.1"; var dispatcher := GameCommandDispatcher.new(); dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakugyokurou"))
	for event_id: StringName in [&"evt.hgy.garden_shift", &"evt.hgy.two_bodies_one_embarrassment"]: dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor")); dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(YOUMU, 2)); return state

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
func _finish(failures: Array[String]) -> void:
	print("M14 Youmu Duty Delegated integration: failures=%d" % failures.size()); for failure: String in failures: printerr("FAIL: %s" % failure); quit(0 if failures.is_empty() else 1)
