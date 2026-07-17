extends SceneTree
## Proves every explicit Aya future persists its matching intent and Journal evidence.

const EVENT_ID: StringName = &"evt.aya.promise"
const AYA: StringName = &"char.aya_shameimaru"
var _content := ContentRepository.new(); var _failures: Array[String] = []
func _initialize() -> void:
	if not _content.load_sources().is_success(): _finish(["Aya Promise content could not load"]); return
	var graph := _content.graph(EVENT_ID)
	_run(graph, &"friendship", &"direct", &"corrective_article_shared_byline", 0)
	_run(graph, &"romance", &"playful", &"first_approved_portrait_kept_private", 1)
	_run(graph, &"postponed", &"patient", &"future_label_left_open", 2)
	_run(graph, &"undecided", &"defiant", &"future_left_unclaimed", 3)
	_run_romance_declined(graph)
	_finish(_failures)
func _run(graph: EventGraphRecord, intent: StringName, tone: StringName, outcome: StringName, index: int) -> void:
	var state := _state(StringName("p177%d" % index))
	if intent == &"undecided":
		GameCommandDispatcher.new().dispatch(state, SetRouteIntentCommand.new(AYA, &"romance"))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not show four chosen futures" % intent)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line()
	if intent == &"romance":
		_expect(result.choice != null and result.choice.choice_id == &"choice.aya.promise.romance_consent", "romance did not ask for portrait consent after the request")
		result = interpreter.choose_tone(&"direct")
		result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == outcome, "%s did not complete Aya's authored future" % intent)
	_expect(state.characters[AYA].route_stage == 7 and state.characters[AYA].route_intent == intent and state.journal.entries.has(StringName("journal.aya.promise.%s" % intent)), "%s did not persist Aya Promise evidence" % intent)

func _run_romance_declined(graph: EventGraphRecord) -> void:
	var state := _state(&"p1774")
	GameCommandDispatcher.new().dispatch(state, SetRouteIntentCommand.new(AYA, &"romance"))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	result = interpreter.choose_tone(&"playful")
	result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.choice_id == &"choice.aya.promise.romance_consent", "declined portrait path did not wait for explicit consent")
	result = interpreter.choose_tone(&"defiant"); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"portrait_declined_future_unclaimed", "declined portrait path did not complete as an intact unlabelled future")
	_expect(state.characters[AYA].route_stage == 7 and state.characters[AYA].route_intent == &"undecided" and state.journal.entries.has(&"journal.aya.promise.romance_declined"), "declined portrait path did not preserve the consent-respecting journal evidence")

func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1771)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.youkai_mountain"))
	for event_id: StringName in [&"evt.aya.exclusive_interview", &"evt.aya.wind_frame_graze", &"evt.aya.hidden_folder", &"evt.aya.story_published_too_soon", &"evt.aya.camera_down", &"evt.aya.tomorrows_front_page"]:
		dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(AYA, 6))
	return state
func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
func _finish(failures: Array[String]) -> void:
	print("M14 Aya Promise integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
