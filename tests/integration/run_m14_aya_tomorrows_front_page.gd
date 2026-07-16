extends SceneTree
## Proves every authored response preserves Aya's refusal of the perfect prediction.

const EVENT_ID: StringName = &"evt.aya.tomorrows_front_page"
const AYA: StringName = &"char.aya_shameimaru"
var _content := ContentRepository.new()
var _failures: Array[String] = []

func _initialize() -> void:
	if not _content.load_sources().is_success(): _finish(["Tomorrow's Front Page content could not load"]); return
	var graph := _content.graph(EVENT_ID)
	_expect_private_fact_gate(graph)
	for index: int in range(4): _run(graph, EventGraphValidator.TONES[index], index)
	_finish(_failures)

func _expect_private_fact_gate(graph: EventGraphRecord) -> void:
	var locked_state := _state(&"p176_locked", false)
	var locked := EventInterpreter.new().start(graph, locked_state, _content)
	_expect(locked.is_error(), "Tomorrow's Front Page started without a private fact being withheld")
	var open_state := _state(&"p176_open", true)
	var open := EventInterpreter.new().start(graph, open_state, _content)
	_expect(not open.is_error() and open.node_id == &"n003", "Tomorrow's Front Page remained locked after the private fact was withheld")

func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p176%d" % index)); var interpreter := EventInterpreter.new(); var result := interpreter.start(graph, state, _content); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach future-headline responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"perfect_future_headline_withheld_before_it_can_be_performed", "%s did not withhold the prediction" % tone)
	_expect(state.characters[AYA].route_stage == 6 and state.journal.entries.has(&"journal.aya.tomorrows_front_page") and state.flags.has(&"flag.route.aya.perfect_headline_withheld"), "%s did not retain archive-refusal evidence" % tone)

func _state(profile_id: StringName, has_private_fact: bool = true) -> GameState:
	var characters: Array[StringName] = []; for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []; for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1761); state.chapter_id = &"chapter.1"; var dispatcher := GameCommandDispatcher.new(); dispatcher.dispatch(state, SetLocationCommand.new(&"loc.youkai_mountain"))
	for event_id: StringName in [&"evt.aya.exclusive_interview", &"evt.aya.wind_frame_graze", &"evt.aya.hidden_folder", &"evt.aya.story_published_too_soon", &"evt.aya.camera_down"]: dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor")); dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	if has_private_fact: dispatcher.dispatch(state, SetFlagCommand.new(FlagState.from_value(&"flag.route.aya.private_fact_withheld", true)))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(AYA, 5)); return state

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
func _finish(failures: Array[String]) -> void:
	print("M14 Aya Tomorrow's Front Page integration: failures=%d" % failures.size()); for failure: String in failures: printerr("FAIL: %s" % failure); quit(0 if failures.is_empty() else 1)
