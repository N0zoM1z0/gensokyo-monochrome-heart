extends SceneTree
## Proves Aya repairs a premature publication with a visible correction rather than erasure.

const EVENT_ID: StringName = &"evt.aya.story_published_too_soon"
const AYA: StringName = &"char.aya_shameimaru"
var _content := ContentRepository.new()
var _failures: Array[String] = []

func _initialize() -> void:
	if not _content.load_sources().is_success(): _finish(["Premature Story content could not load"]); return
	var tones: Array[StringName] = [&"direct", &"playful", &"patient", &"defiant"]
	for index: int in range(tones.size()): _run(_content.graph(EVENT_ID), tones[index], index)
	_finish(_failures)

func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p174%d" % index)); var interpreter := EventInterpreter.new(); var result := interpreter.start(graph, state, _content)
	_expect(result.node_id == &"n003", "%s did not reach Aya's public-error admission" % tone)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach four correction responses" % tone)
	result = interpreter.choose_tone(tone); _expect(result.node_id == StringName("n_%s_line" % tone), "%s did not reach its correction response" % tone)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"correction_reaches_the_people_harmed_by_the_headline", "%s did not complete visible correction" % tone)
	_expect(state.characters[AYA].route_stage == 4 and state.journal.entries.has(&"journal.aya.story_published_too_soon"), "%s did not preserve stage-four correction evidence" % tone)
	_expect(state.flags.has(&"flag.route.aya.visible_correction_published"), "%s did not persist public repair" % tone)

func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []; for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []; for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1741)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new(); dispatcher.dispatch(state, SetLocationCommand.new(&"loc.youkai_mountain"))
	for event_id: StringName in [&"evt.aya.exclusive_interview", &"evt.aya.wind_frame_graze", &"evt.aya.hidden_folder"]:
		dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor")); dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(AYA, 3)); return state

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
func _finish(failures: Array[String]) -> void:
	print("M14 Aya Premature Story integration: failures=%d" % failures.size()); for failure: String in failures: printerr("FAIL: %s" % failure); quit(0 if failures.is_empty() else 1)
