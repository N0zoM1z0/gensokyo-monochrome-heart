extends SceneTree
## Covers every response and both Broom Backseat outcomes for Marisa's weather rescue.

const EVENT_ID: StringName = &"evt.mrs.rescue_looks_like_race"
var _content := ContentRepository.new()
var _failures: Array[String] = []

func _initialize() -> void:
	if not _content.load_sources().is_success(): _finish(["rescue content could not load"]); return
	for index: int in range(EventGraphValidator.TONES.size()): _run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], &"clear" if index % 2 == 0 else &"assist_clear", index)
	_finish(_failures)

func _run(graph: EventGraphRecord, tone: StringName, mode_tag: StringName, index: int) -> void:
	var state := _state(StringName("p155%d" % index)); var interpreter := EventInterpreter.new(); var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line(); _expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach rescue answers" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); _expect(result.status == EventInterpreterResult.Status.WAIT_MODE and result.mode_context.mode_id == &"mini.mrs.broom_backseat", "%s did not reach shared navigation" % tone)
	result = interpreter.resume_mode(ModeResult.new(mode_tag)); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"weather_crossed_together", "%s/%s did not complete rescue" % [tone, mode_tag])
	_expect(state.characters[&"char.marisa_kirisame"].route_stage == 5 and state.journal.entries.has(&"journal.mrs.rescue_looks_like_race"), "%s/%s omitted stage or Journal" % [tone, mode_tag])

func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []; for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []; for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1551); state.chapter_id = &"chapter.1"; var dispatcher := GameCommandDispatcher.new(); dispatcher.dispatch(state, SetLocationCommand.new(&"loc.forest_of_magic"))
	for event_id: StringName in [&"evt.mrs.crash_landing", &"evt.mrs.field_notes", &"evt.mrs.shelf_marked_later", &"evt.mrs.talent_bad_conversation"]: dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor")); dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(&"char.marisa_kirisame", 4)); return state

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
func _finish(failures: Array[String]) -> void:
	print("M14 Marisa rescue integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
