extends SceneTree
## Proves Kaguya's Promise preserves friendship, romance, postponement, and uncertainty as intact futures.

const EVENT_ID: StringName = &"evt.ein.promise"
const KAGUYA: StringName = &"char.kaguya_houraisan"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Kaguya Promise content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	_run(graph, &"friendship", &"direct", &"standing_challenge_with_changing_rules", 0)
	_run(graph, &"romance", &"playful", &"finite_moments_named_irreplaceable", 1)
	_run(graph, &"postponed", &"patient", &"future_left_open_without_deadline", 2)
	_run(graph, &"undecided", &"defiant", &"future_left_unclaimed", 3)
	_finish(_failures)


func _run(graph: EventGraphRecord, intent: StringName, tone: StringName, outcome: StringName, index: int) -> void:
	var state := _state(StringName("p188%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not show four intact futures" % intent)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == outcome, "%s did not complete Kaguya's authored future" % intent)
	_expect(state.characters[KAGUYA].route_stage == 7 and state.characters[KAGUYA].route_intent == intent, "%s did not persist stage seven and intent" % intent)
	_expect(state.journal.entries.has(StringName("journal.ein.promise.%s" % intent)), "%s omitted Promise Journal evidence" % intent)
	if intent == &"romance":
		_expect(state.flags.has(&"flag.route.kaguya.moments_not_replaceable"), "romance did not reject replaceable moments")


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1881)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.eientei"))
	for event_id: StringName in [&"evt.ein.five_impossibilities", &"evt.ein.elegance_and_boredom", &"evt.ein.game_with_no_continue", &"evt.ein.short_lived_guest", &"evt.ein.mokou_uninvited_honesty", &"evt.ein.endless_night_offer"]:
		dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(KAGUYA, 6))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Kaguya Promise integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
