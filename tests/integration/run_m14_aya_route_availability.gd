extends SceneTree
## Proves Aya's deep route only unlocks in authored order, including its privacy gate.

const AYA: StringName = &"char.aya_shameimaru"
const EVENT_IDS: Array[StringName] = [
	&"evt.aya.exclusive_interview",
	&"evt.aya.wind_frame_graze",
	&"evt.aya.hidden_folder",
	&"evt.aya.story_published_too_soon",
	&"evt.aya.camera_down",
	&"evt.aya.tomorrows_front_page",
	&"evt.aya.promise",
]

var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Aya route content could not load"])
		return
	var evaluator := EventPredicateEvaluator.new()
	for index: int in range(EVENT_IDS.size()):
		_expect_route_gate(evaluator, EVENT_IDS[index], index)
	_finish(_failures)


func _expect_route_gate(evaluator: EventPredicateEvaluator, event_id: StringName, index: int) -> void:
	var graph := _content.graph(event_id)
	var locked := _state(StringName("p178%d" % index))
	if index > 0:
		_expect(
			not evaluator.all_pass(evaluator.evaluate_all(graph.availability, locked)),
			"%s unlocked before %s completed" % [event_id, EVENT_IDS[index - 1]]
		)
	else:
		_expect(
			evaluator.all_pass(evaluator.evaluate_all(graph.availability, locked)),
			"Aya's opening interview was not available at route start"
		)
		return
	_complete(locked, EVENT_IDS[index - 1])
	if event_id == &"evt.aya.tomorrows_front_page":
		_expect(
			not evaluator.all_pass(evaluator.evaluate_all(graph.availability, locked)),
			"Tomorrow's Front Page ignored the private-fact-withheld gate"
		)
		var dispatcher := GameCommandDispatcher.new()
		dispatcher.dispatch(locked, SetFlagCommand.new(FlagState.from_value(&"flag.route.aya.private_fact_withheld", true)))
	_expect(
		evaluator.all_pass(evaluator.evaluate_all(graph.availability, locked)),
		"%s remained locked after its exact predecessor%s" % [event_id, " and private fact" if event_id == &"evt.aya.tomorrows_front_page" else ""]
	)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters():
		characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations():
		locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1781)
	state.chapter_id = &"chapter.1"
	return state


func _complete(state: GameState, event_id: StringName) -> void:
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Aya route availability integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
