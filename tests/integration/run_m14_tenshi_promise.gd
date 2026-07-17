extends SceneTree
## Proves Tenshi's friendship and five non-punitive finale outcomes, including separate romance consent.

const EVENT_ID: StringName = &"evt.tsh.promise"
const TENSHI: StringName = &"char.tenshi_hinanawi"
var _content := ContentRepository.new()
var _failures: Array[String] = []

func _initialize() -> void:
	if not _content.load_sources().is_success(): _finish(["Tenshi Promise content could not load"]); return
	_run(&"direct", &"", &"friendship", &"formal_challenge_contract_friendship", &"journal.tsh.promise.friendship")
	_run(&"playful", &"direct", &"romance", &"romance_contract_with_explicit_stop_clause", &"journal.tsh.promise.romance")
	_run(&"playful", &"defiant", &"undecided", &"romance_declined_contract_and_attention_remain", &"journal.tsh.promise.romance_declined")
	_run(&"patient", &"", &"postponed", &"challenge_contract_without_relationship_deadline", &"journal.tsh.promise.postponed")
	_run(&"defiant", &"", &"undecided", &"future_unclaimed_contract_remains_open", &"journal.tsh.promise.undecided")
	_finish(_failures)

func _run(tone: StringName, consent: StringName, intent: StringName, outcome: StringName, journal_id: StringName) -> void:
	var state := _state(StringName("p231_%s_%s" % [tone, consent]))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(_content.graph(EVENT_ID), state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.choice_id == &"choice.tsh.promise.intent", "%s did not reach intent" % tone)
	result = interpreter.choose_tone(tone)
	if tone == &"playful":
		result = interpreter.advance_line(); _expect(result.choice != null and result.choice.choice_id == &"choice.tsh.promise.romance_consent" and result.choice.options.size() == 2, "romance did not ask separately")
		result = interpreter.choose_tone(consent)
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == outcome, "%s/%s reached wrong finale" % [tone, consent])
	_expect(state.characters[TENSHI].route_stage == 7 and state.characters[TENSHI].route_intent == intent and state.journal.entries.has(journal_id), "%s/%s omitted outcome evidence" % [tone, consent])
	if tone == &"playful" and consent == &"defiant": _expect(state.flags.has(&"flag.route.tenshi.promise.romance_declined_contract_remains"), "romance no withdrew contract")

func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2311)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.heaven"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.tsh.heaven_without_friction", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.tsh.heaven_without_friction", &"complete"))
	for flag_id: StringName in [&"flag.route.tenshi.boundary.clear_no_spoken", &"flag.route.tenshi.boundary.player_left_engagement", &"flag.route.tenshi.boundary.tenshi_stopped_without_escalation", &"flag.route.tenshi.repair.completed_without_audience", &"flag.route.tenshi.repair.no_credit_requested", &"flag.route.tenshi.repair.boundary_strain_repaired_through_practice", &"flag.route.tenshi.archive.frictionless_offer_rejected_by_tenshi", &"flag.route.tenshi.archive.surprise_not_calibrated", &"flag.route.tenshi.archive.refusal_remains_possible", &"flag.route.tenshi.archive.irregular_future_chosen"]: dispatcher.dispatch(state, SetFlagCommand.new(FlagState.from_value(flag_id, true)))
	return state

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
func _finish(failures: Array[String]) -> void:
	print("M14 Tenshi Promise integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
