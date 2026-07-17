extends SceneTree
## Proves Yuyuko ends the Archive feast herself across every authored response.

const EVENT_ID: StringName = &"evt.yyk.feast_without_ending"
const YUYUKO: StringName = &"char.yuyuko_saigyouji"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["The Feast Without an Ending content could not load"])
		return
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p206%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the infinite-feast responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"infinite_feast_ended_by_its_host", "%s did not complete the Archive refusal" % tone)
	_expect(state.characters[YUYUKO].route_stage == 6 and state.journal.entries.has(&"journal.yyk.feast_without_ending"), "%s did not preserve the ended-feast evidence" % tone)
	_expect(state.flags.has(&"flag.route.yuyuko.infinite_feast.ended_by_yuyuko") and state.flags.has(&"flag.route.yuyuko.infinite_feast.archive_refused"), "%s let the protagonist end Yuyuko's feast or kept the loop" % tone)
	if tone == &"patient": _expect(state.flags.has(&"flag.route.yuyuko.infinite_feast.end_left_to_yuyuko"), "patient took over Yuyuko's ending")


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2061)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakugyokurou"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.yyk.hosts_responsibility", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.yyk.hosts_responsibility", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(YUYUKO, 5))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Yuyuko Feast Without Ending integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
