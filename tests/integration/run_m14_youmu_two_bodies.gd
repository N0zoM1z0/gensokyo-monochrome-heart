extends SceneTree
## Covers every reply and both safe outcomes for Youmu's paired-body bridge event.

const EVENT_ID: StringName = &"evt.hgy.two_bodies_one_embarrassment"
const YOUMU: StringName = &"char.youmu_konpaku"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Two Bodies content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	var tones: Array[StringName] = [&"direct", &"playful", &"patient", &"defiant"]
	for index: int in range(tones.size()):
		_run(graph, tones[index], &"clear" if index % 2 == 0 else &"withdrawn", index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, mode_tag: StringName, index: int) -> void:
	var state := _state(StringName("p165%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach four paired-body responses" % tone)
	result = interpreter.choose_tone(tone)
	_expect(result.node_id == StringName("n_%s_line" % tone), "%s did not reach its response" % tone)
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE and result.mode_context.mode_id == &"mini.hgy.half_phantom_balance", "%s did not reach Half-Phantom Balance" % tone)
	result = interpreter.resume_mode(ModeResult.new(mode_tag))
	_expect(result.node_id == StringName("n_%s" % mode_tag), "%s did not reach its outcome line" % tone)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"two_bodies_crossed_by_permission", "%s did not complete the bridge event" % tone)
	_expect(state.characters[YOUMU].route_stage == 2, "%s did not advance Youmu to stage two" % tone)
	var journal := &"journal.hgy.two_bodies" if mode_tag == &"clear" else &"journal.hgy.two_bodies.withdrawn"
	_expect(state.journal.entries.has(journal), "%s omitted its outcome-appropriate Journal evidence" % tone)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1651)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakugyokurou"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.hgy.garden_shift", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.hgy.garden_shift", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(YOUMU, 1))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Youmu Two Bodies integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
