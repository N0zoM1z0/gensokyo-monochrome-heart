extends SceneTree
## Proves Eirin rejects the Archive cure before player agreement and preserves the patient across every tone.

const EVENT_ID: StringName = &"evt.eir.permanent_cure"
const EIRIN: StringName = &"char.eirin_yagokoro"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Permanent Cure content could not load"])
		return
	var index := 0
	for tone: StringName in EventGraphValidator.TONES:
		_run(_content.graph(EVENT_ID), tone, index); index += 1
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p222%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	for _step: int in range(7): result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4 and result.node_id == &"n_choice", "%s did not reach the record choice after Eirin's rejection" % tone)
	_expect(state.flags.has(&"flag.route.eirin.cure.permanent_cure_rejected_by_eirin"), "%s let the player choice cause Eirin's refusal" % tone)
	result = interpreter.choose_tone(tone)
	for _step: int in range(4): result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"permanent_cure_rejected_patient_and_revision_remain", "%s did not close the permanent cure" % tone)
	_expect(state.characters[EIRIN].route_stage == 6 and state.characters[EIRIN].relationship.strain == 0, "%s punished the Archive refusal or missed stage six" % tone)
	_expect(state.flags.has(&"flag.route.eirin.cure.permanent_cure_rejected_by_eirin") and state.flags.has(&"flag.route.eirin.cure.patient_presence_required") and state.flags.has(&"flag.route.eirin.cure.mortality_not_failure"), "%s omitted Eirin's autonomous refusal or the patient" % tone)
	_expect(state.flags.has(&"flag.route.eirin.cure.uncertainty_preserved") and state.flags.has(&"flag.route.eirin.cure.diagnosis_remains_revisable") and state.flags.has(&"flag.route.eirin.cure.no_sample_or_procedure") and state.journal.entries.has(&"journal.eir.permanent_cure"), "%s erased uncertainty, revision, or the no-procedure evidence" % tone)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2221)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.eientei"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.eir.doctor_sleeps", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.eir.doctor_sleeps", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(EIRIN, 5))
	dispatcher.dispatch(state, SetFlagCommand.new(FlagState.from_value(&"flag.route.eirin.rest.boundary_strain_repaired_through_practice", true)))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Eirin Permanent Cure integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
