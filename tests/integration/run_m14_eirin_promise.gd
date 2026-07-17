extends SceneTree
## Proves every finale intent is complete and romance requires a separate yes while care remains outside the answer.

const EVENT_ID: StringName = &"evt.eir.promise"
const EIRIN: StringName = &"char.eirin_yagokoro"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Eirin Promise content could not load"])
		return
	_run(&"direct", &"", &"friendship", &"patient_owned_ordinary_lifespan_friendship_ledger", &"journal.eir.promise.friendship", &"flag.route.eirin.promise.ordinary_lifespan_friendship_ledger", 0)
	_run(&"playful", &"direct", &"romance", &"romance_promised_one_appointment_at_a_time", &"journal.eir.promise.romance", &"flag.route.eirin.promise.romance_next_appointment_consented", 1)
	_run(&"playful", &"defiant", &"undecided", &"romance_declined_appointment_and_care_remain", &"journal.eir.promise.romance_declined", &"flag.route.eirin.promise.romance_declined_without_penalty", 2)
	_run(&"patient", &"", &"postponed", &"relationship_label_postponed_without_deadline", &"journal.eir.promise.postponed", &"flag.route.eirin.promise.relationship_label_has_no_deadline", 3)
	_run(&"defiant", &"", &"undecided", &"future_unclaimed_uncertainty_not_treated", &"journal.eir.promise.undecided", &"flag.route.eirin.promise.future_unclaimed", 4)
	_finish(_failures)


func _run(tone: StringName, consent_tone: StringName, intent: StringName, outcome: StringName, journal_id: StringName, flag_id: StringName, index: int) -> void:
	var state := _state(StringName("p223%d" % index))
	if intent == &"undecided":
		GameCommandDispatcher.new().dispatch(state, SetRouteIntentCommand.new(EIRIN, &"romance"))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(_content.graph(EVENT_ID), state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.choice_id == &"choice.eir.promise.intent" and result.choice.options.size() == 4, "%s did not reach the route-intent choice" % tone)
	result = interpreter.choose_tone(tone)
	if tone == &"playful":
		result = interpreter.advance_line()
		_expect(result.choice != null and result.choice.choice_id == &"choice.eir.promise.romance_consent" and result.choice.options.size() == 2, "romance did not ask a separate yes or no")
		result = interpreter.choose_tone(consent_tone)
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == outcome, "%s/%s reached the wrong finale" % [tone, consent_tone])
	_expect(state.characters[EIRIN].route_stage == 7 and state.characters[EIRIN].route_intent == intent and state.characters[EIRIN].relationship.strain == 0, "%s/%s set the wrong intent or added strain" % [tone, consent_tone])
	_expect(state.flags.has(&"flag.route.eirin.promise.ledger_patient_owned") and state.flags.has(&"flag.route.eirin.promise.ordinary_lifespan_ledger_bounded"), "%s/%s lost the common patient-owned ledger" % [tone, consent_tone])
	_expect(state.flags.has(flag_id) and state.journal.entries.has(journal_id), "%s/%s omitted its finale evidence" % [tone, consent_tone])
	if tone == &"playful" and consent_tone == &"defiant":
		_expect(state.flags.has(&"flag.route.eirin.promise.appointment_and_care_remain") and state.flags.has(&"flag.route.eirin.promise.ledger_ownership_remains_after_no"), "declining romance withdrew the appointment, care, or ledger")


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2231)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.eientei"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.eir.permanent_cure", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.eir.permanent_cure", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(EIRIN, 6))
	for flag_id: StringName in [&"flag.route.eirin.consent.patient_refusal_respected", &"flag.route.eirin.practical_care.kosuzu_consent_preserved", &"flag.route.eirin.practical_care.kosuzu_care_scope_confirmed", &"flag.route.eirin.experiment.self_sacrifice_rejected", &"flag.route.eirin.rest.boundary_strain_repaired_through_practice", &"flag.route.eirin.cure.permanent_cure_rejected_by_eirin", &"flag.route.eirin.cure.patient_presence_required", &"flag.route.eirin.cure.mortality_not_failure", &"flag.route.eirin.cure.diagnosis_remains_revisable"]:
		dispatcher.dispatch(state, SetFlagCommand.new(FlagState.from_value(flag_id, true)))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Eirin Promise integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
