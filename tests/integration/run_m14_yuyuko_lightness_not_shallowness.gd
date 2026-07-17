extends SceneTree
## Proves Yuyuko refuses imposed solemnity while the protagonist's mistake retains strain.

const EVENT_ID: StringName = &"evt.yyk.lightness_not_shallowness"
const YUYUKO: StringName = &"char.yuyuko_saigyouji"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Do Not Treat Lightness as Shallowness content could not load"])
		return
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p204%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the boundary responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"chosen_lightness_kept_without_denying_memorial_weight", "%s did not complete the lightness boundary" % tone)
	_expect(state.characters[YUYUKO].route_stage == 4 and state.journal.entries.has(&"journal.yyk.lightness_not_shallowness"), "%s did not preserve the boundary evidence" % tone)
	_expect(state.characters[YUYUKO].relationship.strain == 1 and state.flags.has(&"flag.route.yuyuko.lightness.seriousness_imposed"), "%s erased the consequence of demanding solemnity" % tone)
	_expect(state.flags.has(&"flag.route.yuyuko.lightness.mood_not_imposed") and state.flags.has(&"flag.route.yuyuko.lightness.not_shallow"), "%s did not preserve Yuyuko's chosen expression" % tone)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2041)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakugyokurou"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.yyk.empty_plate", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.yyk.empty_plate", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(YUYUKO, 3))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Yuyuko Lightness Not Shallowness integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
