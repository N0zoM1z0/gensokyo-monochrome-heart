extends SceneTree
## Proves Marisa's final promise exposes four explicit, persisted outcomes.

const EVENT_ID: StringName = &"evt.mrs.promise"
const MARISA: StringName = &"char.marisa_kirisame"
var _content := ContentRepository.new()
var _failures: Array[String] = []
func _initialize() -> void:
	if not _content.load_sources().is_success(): _finish(["Marisa Promise content could not load"]); return
	_run(_content.graph(EVENT_ID), &"friendship", &"direct", &"permanent_broom_backseat", 0)
	_run(_content.graph(EVENT_ID), &"romance", &"playful", &"tomorrow_borrowed_by_permission", 1)
	_run(_content.graph(EVENT_ID), &"postponed", &"patient", &"future_left_open", 2)
	_run(_content.graph(EVENT_ID), &"undecided", &"defiant", &"future_not_named", 3)
	_finish(_failures)
func _run(graph: EventGraphRecord, intent: StringName, tone: StringName, outcome: StringName, index: int) -> void:
	var state := _state(StringName("p157%d" % index))
	if intent == &"undecided":
		GameCommandDispatcher.new().dispatch(state, SetRouteIntentCommand.new(MARISA, &"romance"))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not see four explicit Promise commitments" % intent)
	result = interpreter.choose_tone(tone); _expect(result.node_id == StringName("n_%s" % intent), "%s did not reach its response" % intent)
	result = interpreter.advance_line(); _expect(result.status == EventInterpreterResult.Status.END and result.outcome == outcome, "%s did not complete authored outcome" % intent)
	_expect(state.characters[MARISA].route_stage == 7 and state.characters[MARISA].route_intent == intent, "%s did not persist route intent and stage seven" % intent)
	_expect(state.journal.entries.has(&"journal.mrs.promise"), "%s omitted final Journal entry" % intent)
func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []; for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []; for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1571); state.chapter_id = &"chapter.1"; var dispatcher := GameCommandDispatcher.new(); dispatcher.dispatch(state, SetLocationCommand.new(&"loc.forest_of_magic"))
	for event_id: StringName in [&"evt.mrs.crash_landing", &"evt.mrs.field_notes", &"evt.mrs.shelf_marked_later", &"evt.mrs.talent_bad_conversation", &"evt.mrs.rescue_looks_like_race", &"evt.mrs.infinite_experiment"]: dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor")); dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(MARISA, 6)); return state
func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
func _finish(failures: Array[String]) -> void:
	print("M14 Marisa Promise finale integration: failures=%d" % failures.size()); for failure: String in failures: printerr("FAIL: %s" % failure); quit(0 if failures.is_empty() else 1)
