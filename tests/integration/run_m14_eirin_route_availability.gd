extends SceneTree
## Proves Eirin's seven stages unlock in taskbook order and the finale requires practiced route semantics rather than a particular valid consent answer.

const EVENTS: Array[StringName] = [
	&"evt.eir.clinic_triage",
	&"evt.ein.patient_refuses",
	&"evt.eir.practical_care",
	&"evt.eir.do_not_volunteer",
	&"evt.eir.doctor_sleeps",
	&"evt.eir.permanent_cure",
	&"evt.eir.promise",
]
const FINALE_FLAGS: Array[StringName] = [
	&"flag.route.eirin.consent.patient_refusal_respected",
	&"flag.route.eirin.practical_care.kosuzu_consent_preserved",
	&"flag.route.eirin.practical_care.kosuzu_care_scope_confirmed",
	&"flag.route.eirin.experiment.self_sacrifice_rejected",
	&"flag.route.eirin.rest.boundary_strain_repaired_through_practice",
	&"flag.route.eirin.cure.permanent_cure_rejected_by_eirin",
	&"flag.route.eirin.cure.patient_presence_required",
	&"flag.route.eirin.cure.mortality_not_failure",
	&"flag.route.eirin.cure.diagnosis_remains_revisable",
]
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Eirin route content could not load"])
		return
	var evaluator := EventPredicateEvaluator.new()
	for index: int in range(EVENTS.size()):
		_expect_gate(evaluator, EVENTS[index], index)
	_expect_finale_semantics(evaluator)
	_finish(_failures)


func _expect_gate(evaluator: EventPredicateEvaluator, event_id: StringName, index: int) -> void:
	var graph := _content.graph(event_id)
	var state := _state(StringName("p224%d" % index))
	if index == 0:
		_expect(evaluator.all_pass(evaluator.evaluate_all(graph.availability, state)), "Eirin's clinic triage was unavailable at route start")
		return
	_expect(not evaluator.all_pass(evaluator.evaluate_all(graph.availability, state)), "%s unlocked before %s" % [event_id, EVENTS[index - 1]])
	_complete(state, EVENTS[index - 1])
	if index == 5:
		_set_flags(state, [&"flag.route.eirin.rest.boundary_strain_repaired_through_practice"])
	elif index == 6:
		_set_flags(state, FINALE_FLAGS)
	_expect(evaluator.all_pass(evaluator.evaluate_all(graph.availability, state)), "%s remained locked after its predecessor and semantic prerequisites" % event_id)


func _expect_finale_semantics(evaluator: EventPredicateEvaluator) -> void:
	var graph := _content.graph(&"evt.eir.promise")
	for predicate: AvailabilityPredicateRecord in graph.availability:
		if String(predicate.key).contains("player_test_answer") or String(predicate.key).contains("player_test_refused"):
			_failures.append("Eirin finale required one valid Stage 2 consent answer: %s" % predicate.key)
	for missing_index: int in range(FINALE_FLAGS.size()):
		var missing_flag := FINALE_FLAGS[missing_index]
		var state := _state(StringName("p224%d" % (10 + missing_index)))
		_complete(state, &"evt.eir.permanent_cure")
		var present: Array[StringName] = []
		for flag_id: StringName in FINALE_FLAGS:
			if flag_id != missing_flag: present.append(flag_id)
		_set_flags(state, present)
		_expect(not evaluator.all_pass(evaluator.evaluate_all(graph.availability, state)), "Eirin finale ignored semantic gate %s" % missing_flag)


func _complete(state: GameState, event_id: StringName) -> void:
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))


func _set_flags(state: GameState, flag_ids: Array[StringName]) -> void:
	var dispatcher := GameCommandDispatcher.new()
	for flag_id: StringName in flag_ids:
		dispatcher.dispatch(state, SetFlagCommand.new(FlagState.from_value(flag_id, true)))


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2241)
	state.chapter_id = &"chapter.1"
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Eirin route availability integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
