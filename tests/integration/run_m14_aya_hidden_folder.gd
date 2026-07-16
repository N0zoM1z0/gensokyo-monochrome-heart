extends SceneTree
## Proves Aya's intervention record remains accountable without exposing its subjects.

const EVENT_ID: StringName = &"evt.aya.hidden_folder"
const AYA: StringName = &"char.aya_shameimaru"
var _content := ContentRepository.new()
var _failures: Array[String] = []

func _initialize() -> void:
	if not _content.load_sources().is_success(): _finish(["Hidden Folder content could not load"]); return
	var tones: Array[StringName] = [&"direct", &"playful", &"patient", &"defiant"]
	for index: int in range(tones.size()): _run(_content.graph(EVENT_ID), tones[index], index)
	_finish(_failures)

func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p173%d" % index)); var interpreter := EventInterpreter.new(); var result := interpreter.start(graph, state, _content)
	_expect(result.node_id == &"n003", "%s did not reach Aya's private record" % tone)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach four accountability responses" % tone)
	result = interpreter.choose_tone(tone); _expect(result.node_id == StringName("n_%s_line" % tone), "%s did not reach its record response" % tone)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"intervention_record_kept_without_a_headline", "%s did not complete the hidden record" % tone)
	_expect(state.characters[AYA].route_stage == 3 and state.journal.entries.has(&"journal.aya.hidden_folder"), "%s did not preserve stage-three intervention evidence" % tone)
	_expect(state.flags.has(&"flag.route.aya.interventions_recorded_without_exposure"), "%s did not persist accountable privacy" % tone)

func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []; for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []; for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1731)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.youkai_mountain"))
	for event_id: StringName in [&"evt.aya.exclusive_interview", &"evt.aya.wind_frame_graze"]:
		dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(AYA, 2))
	return state

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
func _finish(failures: Array[String]) -> void:
	print("M14 Aya Hidden Folder integration: failures=%d" % failures.size()); for failure: String in failures: printerr("FAIL: %s" % failure); quit(0 if failures.is_empty() else 1)
