extends SceneTree
## Proves Eirin chooses rest, the handoff survives routine and Archive requests, and prior boundary strain is repaired only through practice.

const EVENT_ID: StringName = &"evt.eir.doctor_sleeps"
const EIRIN: StringName = &"char.eirin_yagokoro"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["The Doctor Sleeps content could not load"])
		return
	var index := 0
	for tone: StringName in EventGraphValidator.TONES:
		_run(_content.graph(EVENT_ID), tone, index); index += 1
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p221%d" % index))
	state.characters[EIRIN].relationship.strain = 1
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	for _step: int in range(4): result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the rest-boundary response" % tone)
	result = interpreter.choose_tone(tone)
	for _step: int in range(8): result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"chosen_rest_completed_through_audited_handoff", "%s did not complete the uninterrupted rest" % tone)
	_expect(state.characters[EIRIN].route_stage == 5 and state.characters[EIRIN].relationship.strain == 0, "%s flattered away strain or failed to repair it through practice" % tone)
	_expect(state.flags.has(&"flag.route.eirin.rest.chosen_by_eirin") and state.flags.has(&"flag.route.eirin.rest.routine_work_redirected") and state.flags.has(&"flag.route.eirin.rest.archive_waited_until_morning") and state.flags.has(&"flag.route.eirin.rest.uninterrupted_period_completed"), "%s imposed rest or allowed an interruption through the handoff" % tone)
	_expect(state.flags.has(&"flag.route.eirin.rest.protagonist_routed_nonurgent_request") and state.flags.has(&"flag.route.eirin.rest.boundary_strain_repaired_through_practice") and state.journal.entries.has(&"journal.eir.doctor_sleeps"), "%s omitted the protagonist's practiced repair evidence" % tone)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2211)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.eientei"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.eir.do_not_volunteer", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.eir.do_not_volunteer", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(EIRIN, 4))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Eirin Doctor Sleeps integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
