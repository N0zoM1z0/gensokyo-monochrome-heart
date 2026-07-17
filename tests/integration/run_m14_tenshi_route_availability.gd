extends SceneTree
## Proves Tenshi's seven authored events unlock in order and finale semantics require practiced boundaries.

const EVENTS: Array[StringName] = [&"evt.tsh.entrance_tremor", &"evt.tsh.keystone_construction", &"evt.tsh.imperfect_meal", &"evt.tsh.attention_not_permission", &"evt.tsh.repair_she_finishes", &"evt.tsh.heaven_without_friction", &"evt.tsh.promise"]
const FINALE_FLAGS: Array[StringName] = [&"flag.route.tenshi.boundary.clear_no_spoken", &"flag.route.tenshi.boundary.player_left_engagement", &"flag.route.tenshi.boundary.tenshi_stopped_without_escalation", &"flag.route.tenshi.repair.completed_without_audience", &"flag.route.tenshi.repair.no_credit_requested", &"flag.route.tenshi.repair.boundary_strain_repaired_through_practice", &"flag.route.tenshi.archive.frictionless_offer_rejected_by_tenshi", &"flag.route.tenshi.archive.surprise_not_calibrated", &"flag.route.tenshi.archive.refusal_remains_possible", &"flag.route.tenshi.archive.irregular_future_chosen"]
var _content := ContentRepository.new()
var _failures: Array[String] = []

func _initialize() -> void:
	if not _content.load_sources().is_success(): _finish(["Tenshi route content could not load"]); return
	var evaluator := EventPredicateEvaluator.new()
	for index: int in range(EVENTS.size()): _expect_gate(evaluator, EVENTS[index], index)
	_expect_finale_semantics(evaluator)
	_finish(_failures)

func _expect_gate(evaluator: EventPredicateEvaluator, event_id: StringName, index: int) -> void:
	var state := _state(StringName("p232_%d" % index))
	var graph := _content.graph(event_id)
	if index == 0:
		_expect(evaluator.all_pass(evaluator.evaluate_all(graph.availability, state)), "Tenshi opening event was unavailable"); return
	_expect(not evaluator.all_pass(evaluator.evaluate_all(graph.availability, state)), "%s unlocked before predecessor" % event_id)
	_complete(state, EVENTS[index - 1])
	if index == 4: _set_flags(state, [&"flag.route.tenshi.boundary.clear_no_spoken", &"flag.route.tenshi.boundary.player_left_engagement", &"flag.route.tenshi.boundary.tenshi_stopped_without_escalation"])
	elif index == 5: _set_flags(state, [&"flag.route.tenshi.repair.boundary_strain_repaired_through_practice"])
	elif index == 6: _set_flags(state, FINALE_FLAGS)
	_expect(evaluator.all_pass(evaluator.evaluate_all(graph.availability, state)), "%s remained locked after predecessor and prerequisites" % event_id)

func _expect_finale_semantics(evaluator: EventPredicateEvaluator) -> void:
	var graph := _content.graph(&"evt.tsh.promise")
	for missing: StringName in FINALE_FLAGS:
		var state := _state(StringName("p232_missing_%s" % String(missing).get_slice(".", 4)))
		_complete(state, &"evt.tsh.heaven_without_friction")
		var present: Array[StringName] = []
		for flag_id: StringName in FINALE_FLAGS:
			if flag_id != missing: present.append(flag_id)
		_set_flags(state, present)
		_expect(not evaluator.all_pass(evaluator.evaluate_all(graph.availability, state)), "Tenshi finale ignored semantic gate %s" % missing)

func _complete(state: GameState, event_id: StringName) -> void:
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
func _set_flags(state: GameState, flags: Array[StringName]) -> void:
	var dispatcher := GameCommandDispatcher.new()
	for flag_id: StringName in flags: dispatcher.dispatch(state, SetFlagCommand.new(FlagState.from_value(flag_id, true)))
func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2321)
	state.chapter_id = &"chapter.1"
	return state
func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
func _finish(failures: Array[String]) -> void:
	print("M14 Tenshi route availability integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
