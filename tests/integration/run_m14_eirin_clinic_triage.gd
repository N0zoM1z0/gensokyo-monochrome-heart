extends SceneTree
## Proves Eirin's triage separates evidence layers across clear, assist, and safe-pause outcomes.

const EVENT_ID: StringName = &"evt.eir.clinic_triage"
const EIRIN: StringName = &"char.eirin_yagokoro"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Clinic Triage content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	_run(graph, &"direct", &"clear", 0)
	_run(graph, &"playful", &"assist_clear", 1)
	_run(graph, &"patient", &"loss", 2)
	_run(graph, &"defiant", &"clear", 3)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, mode_tag: StringName, index: int) -> void:
	var state := _state(StringName("p217%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach triage responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE and result.mode_context.mode_id == &"mini.eir.clinic_triage", "%s did not reach triage handoff" % tone)
	result = interpreter.resume_mode(ModeResult.new(mode_tag))
	var expected_node := StringName("n_%s" % (&"assist" if mode_tag == &"assist_clear" else mode_tag))
	_expect(result.node_id == expected_node, "%s did not reach its %s triage response" % [tone, mode_tag])
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"triage_layers_separated_before_any_treatment_choice", "%s/%s did not complete safe triage" % [tone, mode_tag])
	_expect(state.characters[EIRIN].route_stage == 1 and state.journal.entries.has(&"journal.eir.clinic_triage"), "%s/%s omitted route evidence" % [tone, mode_tag])
	_expect(state.flags.has(&"flag.route.eirin.triage.trace_layers_separated") and state.flags.has(&"flag.route.eirin.triage.patient_words_not_overwritten") and state.flags.has(&"flag.route.eirin.triage.tewi_noise_contained"), "%s/%s collapsed evidence into a diagnosis" % [tone, mode_tag])
	if mode_tag == &"loss": _expect(state.characters[EIRIN].relationship.strain == 0, "safe pause punished the route")


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2171)
	state.chapter_id = &"chapter.1"
	GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.eientei"))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Eirin Clinic Triage integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
