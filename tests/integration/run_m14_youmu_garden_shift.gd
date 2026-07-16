extends SceneTree
## Traverses every Garden Shift response and the clear or voluntary-withdrawal routes.

const EVENT_ID: StringName = &"evt.hgy.garden_shift"
const YOUMU: StringName = &"char.youmu_konpaku"

var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Garden Shift content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	var tones: Array[StringName] = [&"direct", &"playful", &"patient", &"defiant"]
	for index: int in range(tones.size()):
		_run(graph, tones[index], &"clear" if index % 2 == 0 else &"withdrawn", index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, result_tag: StringName, index: int) -> void:
	var state := _state(StringName("p164%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	_expect(result.node_id == &"n003", "%s did not reach Youmu's garden briefing" % tone)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach four Garden Shift responses" % tone)
	result = interpreter.choose_tone(tone)
	_expect(result.node_id == StringName("n_%s_line" % tone), "%s did not reach its garden response" % tone)
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE and result.mode_context.mode_id == &"mini.hgy.soul_garden", "%s did not reach Soul Garden" % tone)
	result = interpreter.resume_mode(ModeResult.new(result_tag))
	_expect(result.node_id == StringName("n_%s" % result_tag), "%s did not reach its %s afterbeat" % [tone, result_tag])
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"garden_shift_shared_without_a_drill", "%s did not complete Garden Shift" % tone)
	_expect(state.characters[YOUMU].route_stage == 1, "%s did not advance Youmu to stage one" % tone)
	var expected_journal := &"journal.hgy.garden_shift" if result_tag == &"clear" else &"journal.hgy.garden_shift.withdrawn"
	_expect(state.journal.entries.has(expected_journal), "%s omitted outcome-appropriate Garden Shift Journal evidence" % tone)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters():
		characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations():
		locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1641)
	state.chapter_id = &"chapter.1"
	GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.hakugyokurou"))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Youmu Garden Shift integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
