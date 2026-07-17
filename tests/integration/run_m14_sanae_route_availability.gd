extends SceneTree
## Proves Sanae's authored route unlocks in taskbook order with its semantic crisis gates.

const EVENTS: Array[StringName] = [
	&"evt.sne.faith_festival_planner",
	&"evt.sne.outside_world_shorthand",
	&"evt.sne.shrine_between_homes",
	&"evt.mtn.measurable_faith",
	&"evt.sne.ordinary_miracle",
	&"evt.sne.guaranteed_faith",
	&"evt.sne.promise",
]
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Sanae route content could not load"])
		return
	var evaluator := EventPredicateEvaluator.new()
	for index: int in range(EVENTS.size()): _expect_gate(evaluator, EVENTS[index], index)
	_finish(_failures)


func _expect_gate(evaluator: EventPredicateEvaluator, event_id: StringName, index: int) -> void:
	var graph := _content.graph(event_id)
	var state := _state(StringName("p216%d" % index))
	if index == 0:
		_expect(evaluator.all_pass(evaluator.evaluate_all(graph.availability, state)), "Sanae's opening event was unavailable")
		return
	_expect(not evaluator.all_pass(evaluator.evaluate_all(graph.availability, state)), "%s unlocked before %s" % [event_id, EVENTS[index - 1]])
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetEventPositionCommand.new(EVENTS[index - 1], &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(EVENTS[index - 1], &"complete"))
	if index == 5:
		_set_flags(state, [&"flag.route.sanae.publicity.future_image_use_requires_asking", &"flag.route.sanae.ordinary.power_not_required_for_care"])
	elif index == 6:
		_set_flags(state, [&"flag.route.sanae.publicity.future_image_use_requires_asking", &"flag.route.sanae.publicity.boundary_repaired_by_practice", &"flag.route.sanae.guarantee.doubt_departure_change_protected"])
	_expect(evaluator.all_pass(evaluator.evaluate_all(graph.availability, state)), "%s remained locked after its predecessor and semantic prerequisites" % event_id)


func _set_flags(state: GameState, flag_ids: Array[StringName]) -> void:
	var dispatcher := GameCommandDispatcher.new()
	for flag_id: StringName in flag_ids: dispatcher.dispatch(state, SetFlagCommand.new(FlagState.from_value(flag_id, true)))


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2161)
	state.chapter_id = &"chapter.1"
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Sanae route availability integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
