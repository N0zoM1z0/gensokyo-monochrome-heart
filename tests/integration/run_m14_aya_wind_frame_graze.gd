extends SceneTree
## Traverses every Aya framing response and every accessible Wind-Frame return.

const EVENT_ID: StringName = &"evt.aya.wind_frame_graze"
const AYA: StringName = &"char.aya_shameimaru"
var _content := ContentRepository.new()
var _failures: Array[String] = []

func _initialize() -> void:
	if not _content.load_sources().is_success(): _finish(["Wind-Frame Graze content could not load"]); return
	var tones: Array[StringName] = [&"direct", &"playful", &"patient", &"defiant"]
	var results: Array[StringName] = [&"clear", &"assist_clear", &"loss", &""]
	for index: int in range(tones.size()):
		_run(_content.graph(EVENT_ID), tones[index], results[index], index)
	_finish(_failures)

func _run(graph: EventGraphRecord, tone: StringName, mode_tag: StringName, index: int) -> void:
	var state := _state(StringName("p172%d" % index)); var interpreter := EventInterpreter.new(); var result := interpreter.start(graph, state, _content)
	_expect(result.node_id == &"n003", "%s did not reach Aya's framing setup" % tone)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach four framing boundaries" % tone)
	result = interpreter.choose_tone(tone); _expect(result.node_id == StringName("n_%s_line" % tone), "%s did not reach its framing response" % tone)
	result = interpreter.advance_line()
	if tone == &"defiant":
		_expect(result.status == EventInterpreterResult.Status.WAIT_INPUT and result.node_id == &"n_withdrawn", "defiant did not reach its camera-down afterbeat")
		result = interpreter.advance_line()
		_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"wind_frame_declined_with_camera_down", "defiant did not complete without entering the photo-chase")
		_expect(state.characters[AYA].route_stage == 2 and state.journal.entries.has(&"journal.aya.wind_frame_graze.withdrawn"), "defiant did not preserve the consent-respecting withdrawal")
		_expect(state.flags.has(&"flag.route.aya.wind_frame_practiced"), "defiant did not persist camera-down practice")
		return
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE and result.mode_context.mode_id == &"danmaku.mtn.tomorrows_headline", "%s did not reach accessible Wind-Frame" % tone)
	result = interpreter.resume_mode(ModeResult.new(mode_tag)); var expected_node: StringName
	match mode_tag:
		&"clear": expected_node = &"n_clear"
		&"assist_clear": expected_node = &"n_assist"
		&"loss": expected_node = &"n_loss"
	_expect(result.node_id == expected_node, "%s mapped %s to the wrong framing response" % [tone, mode_tag])
	result = interpreter.advance_line(); _expect(result.node_id == &"n_after", "%s omitted Aya's camera-down afterbeat" % tone)
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"wind_frame_practiced_without_staging_anyone", "%s did not complete Wind-Frame practice" % tone)
	_expect(state.characters[AYA].route_stage == 2 and state.journal.entries.has(&"journal.aya.wind_frame_graze"), "%s did not preserve stage-two framing evidence" % tone)
	_expect(state.flags.has(&"flag.route.aya.wind_frame_practiced"), "%s did not persist accessible framing practice" % tone)

func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []; for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []; for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1721); state.chapter_id = &"chapter.1"; var dispatcher := GameCommandDispatcher.new(); dispatcher.dispatch(state, SetLocationCommand.new(&"loc.youkai_mountain")); dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.aya.exclusive_interview", &"n_route_predecessor")); dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.aya.exclusive_interview", &"complete")); dispatcher.dispatch(state, AdvanceRouteStageCommand.new(AYA, 1)); return state

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
func _finish(failures: Array[String]) -> void:
	print("M14 Aya Wind-Frame Graze integration: failures=%d" % failures.size()); for failure: String in failures: printerr("FAIL: %s" % failure); quit(0 if failures.is_empty() else 1)
