extends SceneTree
## Proves Promise exposes four explicit endings and persists the selected route intent.

const EVENT_ID: StringName = &"evt.hkr.promise"
const REIMU_ID: StringName = &"char.reimu_hakurei"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Promise content could not be loaded"])
		return
	var graph := _content.graph(EVENT_ID)
	_run(graph, &"friendship", &"direct", &"friendship_open_door", &"flag.route.reimu.promise.friendship")
	_run(graph, &"romance", &"playful", &"romance_cushion_inside", &"flag.route.reimu.promise.romance")
	_run(graph, &"postponed", &"patient", &"promise_left_open", &"flag.route.reimu.promise.postponed")
	_run(graph, &"undecided", &"defiant", &"return_without_label", &"flag.route.reimu.promise.undecided")
	_finish(_failures)


func _run(graph: EventGraphRecord, intent: StringName, tone: StringName, expected_outcome: StringName, flag_id: StringName) -> void:
	var state := _state(StringName("p148%d" % _intent_index(intent)))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	_expect(not result.is_error(), "%s could not start Promise: %s" % [intent, result.diagnostic])
	_expect(result.node_id == &"n003", "%s did not reach Reimu's rain greeting" % intent)
	result = interpreter.advance_line()
	_expect(result.node_id == &"n004", "%s did not reach the explicit-promise question" % intent)
	result = interpreter.advance_line()
	_expect(result.node_id == &"n005" and result.choice != null, "%s did not reach Promise choice" % intent)
	if result.choice != null:
		_expect(result.choice.options.size() == 4, "Promise did not expose all four explicit commitments")
		_expect(result.choice.option_for_tone(tone) != null, "%s commitment was not available" % intent)
	result = interpreter.choose_tone(tone)
	_expect(result.node_id == StringName("n_%s" % intent), "%s did not reach its response line" % intent)
	result = interpreter.advance_line()
	_expect(result.node_id == StringName("n_after_%s" % intent), "%s did not reach the shared ordinary-afternoon landing" % intent)
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == expected_outcome, "%s did not end with its authored outcome" % intent)
	_expect(state.characters[REIMU_ID].route_stage == 6, "%s did not advance Reimu to stage six" % intent)
	_expect(state.characters[REIMU_ID].route_intent == intent, "%s did not persist its selected route intent" % intent)
	_expect(state.journal.entries.has(&"journal.hkr.promise"), "%s omitted the Promise Journal entry" % intent)
	var flag := state.flags.get(flag_id) as FlagState
	_expect(flag != null and flag.value() == true, "%s did not persist its semantic outcome flag" % intent)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1486)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakurei_shrine"))
	for event_id: StringName in [&"evt.hkr.empty_cushion", &"evt.hkr.offerings_without_owners", &"evt.hkr.day_nothing_happens", &"evt.hkr.shrine_not_guesthouse", &"evt.hkr.unasked_rescue", &"evt.hkr.perfectly_recorded_tea"]:
		dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(REIMU_ID, 5))
	return state


func _intent_index(intent: StringName) -> int:
	match intent:
		&"friendship": return 0
		&"romance": return 1
		&"postponed": return 2
		_: return 3


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Reimu Promise finale integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
