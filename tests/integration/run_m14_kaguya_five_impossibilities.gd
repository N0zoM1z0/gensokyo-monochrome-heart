extends SceneTree
## Proves every Kaguya response keeps an impossible request optional and advances her route.

const EVENT_ID: StringName = &"evt.ein.five_impossibilities"
const KAGUYA: StringName = &"char.kaguya_houraisan"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Five Impossible Errands content could not load"])
		return
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p181%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	_expect(result.node_id == &"n003", "%s did not reach Kaguya's opening request" % tone)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach four answers to the request" % tone)
	result = interpreter.choose_tone(tone)
	_expect(result.node_id == StringName("n_%s_line" % tone), "%s did not reach its Kaguya response" % tone)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"impossible_request_answered_without_proving_worth", "%s did not finish with an optional challenge" % tone)
	_expect(state.characters[KAGUYA].route_stage == 1, "%s did not advance Kaguya to stage one" % tone)
	_expect(state.journal.entries.has(&"journal.ein.five_impossibilities"), "%s omitted Kaguya's first Journal evidence" % tone)
	var response_flag: StringName = {
		&"direct": &"flag.route.kaguya.useful_answer_requested",
		&"playful": &"flag.route.kaguya.clever_answer_offered",
		&"patient": &"flag.route.kaguya.request_meaning_asked",
		&"defiant": &"flag.route.kaguya.refusal_is_accepted",
	}[tone]
	_expect(state.flags.has(response_flag), "%s did not preserve its answer boundary" % tone)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters():
		characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations():
		locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1811)
	state.chapter_id = &"chapter.1"
	GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.eientei"))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Kaguya Five Impossible Errands integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
