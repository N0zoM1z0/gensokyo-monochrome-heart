extends SceneTree
## Proves Aya's first route event honors every authored publication boundary.

const EVENT_ID: StringName = &"evt.aya.exclusive_interview"
const AYA: StringName = &"char.aya_shameimaru"
var _content := ContentRepository.new()
var _failures: Array[String] = []

func _initialize() -> void:
	if not _content.load_sources().is_success(): _finish(["Exclusive Interview content could not load"]); return
	var tones: Array[StringName] = [&"direct", &"playful", &"patient", &"defiant"]
	for index: int in range(tones.size()): _run(_content.graph(EVENT_ID), tones[index], index)
	_finish(_failures)

func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p171%d" % index)); var interpreter := EventInterpreter.new(); var result := interpreter.start(graph, state, _content)
	_expect(result.node_id == &"n003", "%s did not reach Aya's opening question" % tone)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach four publication terms" % tone)
	result = interpreter.choose_tone(tone); _expect(result.node_id == StringName("n_%s_line" % tone), "%s did not reach its boundary response" % tone)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"arrival_story_has_terms", "%s did not complete the interview" % tone)
	_expect(state.characters[AYA].route_stage == 1, "%s did not advance Aya to stage one" % tone)
	_expect(state.journal.entries.has(&"journal.aya.exclusive_interview"), "%s omitted interview Journal evidence" % tone)
	var boundary_flag: StringName
	match tone:
		&"direct": boundary_flag = &"flag.route.aya.arrival_off_record"
		&"playful": boundary_flag = &"flag.route.aya.harmless_detail_offered"
		&"patient": boundary_flag = &"flag.route.aya.verification_requested"
		&"defiant": boundary_flag = &"flag.route.aya.privacy_boundary_named"
	_expect(state.event_flags.has(boundary_flag), "%s did not preserve its publication boundary" % tone)

func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []; for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []; for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1711); state.chapter_id = &"chapter.1"; GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.youkai_mountain")); return state

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
func _finish(failures: Array[String]) -> void:
	print("M14 Aya Exclusive Interview integration: failures=%d" % failures.size()); for failure: String in failures: printerr("FAIL: %s" % failure); quit(0 if failures.is_empty() else 1)
