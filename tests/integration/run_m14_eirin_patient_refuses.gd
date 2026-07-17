extends SceneTree
## Proves Eirin respects the patient's refusal and the player's independent yes or no without route penalty.

const EVENT_ID: StringName = &"evt.ein.patient_refuses"
const EIRIN: StringName = &"char.eirin_yagokoro"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["The Patient Who Says No content could not load"])
		return
	var tones: Array[StringName] = [&"direct", &"playful", &"patient", &"defiant"]
	var index := 0
	for tone: StringName in tones:
		_run(tone, true, index); index += 1
		_run(tone, false, index); index += 1
	_finish(_failures)


func _run(tone: StringName, accepts_test: bool, index: int) -> void:
	var state := _state(StringName("p218%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(_content.graph(EVENT_ID), state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.choice_id == &"choice.ein.patient_refuses.response" and result.choice.options.size() == 4, "%s did not reach the consent response" % tone)
	result = interpreter.choose_tone(tone)
	result = interpreter.advance_line(); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.choice_id == &"choice.ein.patient_refuses.player_test_consent" and result.choice.options.size() == 2, "%s did not receive a separate player test choice" % tone)
	result = interpreter.choose_tone(&"direct" if accepts_test else &"defiant")
	_expect(result.node_id == (&"n_yes_line" if accepts_test else &"n_no_line"), "%s reached the wrong player-consent response" % tone)
	result = interpreter.advance_line()
	var expected_outcome := &"patient_refusal_preserved_player_accepted_bounded_test" if accepts_test else &"patient_and_player_refusals_preserved_without_penalty"
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == expected_outcome, "%s did not complete the selected consent branch" % tone)
	_expect(state.characters[EIRIN].route_stage == 2 and state.flags.has(&"flag.route.eirin.consent.patient_refusal_respected") and state.flags.has(&"flag.route.eirin.consent.reason_not_required"), "%s omitted the patient's completed refusal evidence" % tone)
	var branch_flag := &"flag.route.eirin.consent.player_test_accepted_with_scope" if accepts_test else &"flag.route.eirin.consent.player_test_refused_without_penalty"
	var journal_id := &"journal.ein.patient_refuses.player_yes" if accepts_test else &"journal.ein.patient_refuses.player_no"
	_expect(state.flags.has(branch_flag) and state.journal.entries.has(journal_id), "%s omitted the selected player-consent evidence" % tone)
	_expect_relationship(state.characters[EIRIN].relationship, tone, accepts_test)


func _expect_relationship(relationship: RelationshipState, tone: StringName, accepts_test: bool) -> void:
	var expected := [0, 0, 0, 0, 0]
	match tone:
		&"direct", &"defiant": expected[2] = 1
		&"playful": expected[3] = 1
		&"patient": expected[0] = 1
	var actual := [relationship.trust, relationship.ease, relationship.respect, relationship.spark, relationship.strain]
	_expect(actual == expected, "%s player-test decision changed route affinity: %s" % ["accepted" if accepts_test else "refused", actual])


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2181)
	state.chapter_id = &"chapter.1"
	GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.eientei"))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Eirin Patient Who Says No integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
