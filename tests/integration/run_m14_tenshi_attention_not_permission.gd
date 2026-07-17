extends SceneTree
## Proves every Tenshi boundary response says no, leaves, and preserves strain without a pursuit.

const EVENT_ID: StringName = &"evt.tsh.attention_not_permission"
const TENSHI: StringName = &"char.tenshi_hinanawi"
var _content := ContentRepository.new()
var _failures: Array[String] = []

func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Tenshi Attention Is Not Permission content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	_expect(_content.localized_string(&"dlg.tsh.attention_not_permission.patient").japanese.contains("私の修復を見届ける義務はない"), "Japanese boundary text no longer says the player need not witness Tenshi's repair")
	for tone: StringName in [&"direct", &"playful", &"patient", &"defiant"]: _run(graph, tone)
	_finish(_failures)

func _run(graph: EventGraphRecord, tone: StringName) -> void:
	var state := _state(StringName("p228_%s" % tone))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the clear-no response" % tone)
	result = interpreter.choose_tone(tone)
	result = interpreter.advance_line(); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"clear_no_followed_by_departure_and_respected_without_escalation", "%s did not complete boundary departure" % tone)
	_expect(state.characters[TENSHI].route_stage == 4 and state.characters[TENSHI].relationship.strain == 1, "%s did not retain the boundary strain" % tone)
	for flag_id: StringName in [&"flag.route.tenshi.boundary.clear_no_spoken", &"flag.route.tenshi.boundary.player_left_engagement", &"flag.route.tenshi.boundary.tenshi_stopped_without_escalation", &"flag.route.tenshi.boundary.attention_not_permission"]:
		_expect(state.flags.has(flag_id), "%s omitted boundary evidence %s" % [tone, flag_id])

func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2281)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.heaven"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.tsh.imperfect_meal", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.tsh.imperfect_meal", &"complete"))
	return state

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)

func _finish(failures: Array[String]) -> void:
	print("M14 Tenshi Attention Is Not Permission integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
