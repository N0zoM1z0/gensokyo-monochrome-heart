extends SceneTree
## Proves the empty plate keeps a shared person and an ending without forced reconstruction.

const EVENT_ID: StringName = &"evt.yyk.empty_plate"
const YUYUKO: StringName = &"char.yuyuko_saigyouji"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["The Empty Plate content could not load"])
		return
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p203%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the memory responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"ended_meal_remembered_through_the_person_not_the_plate", "%s did not complete the empty-plate memory" % tone)
	_expect(state.characters[YUYUKO].route_stage == 3 and state.journal.entries.has(&"journal.yyk.empty_plate"), "%s did not preserve empty-plate evidence" % tone)
	_expect(state.flags.has(&"flag.route.yuyuko.empty_plate.shared_person_remembered") and state.flags.has(&"flag.route.yuyuko.empty_plate.ending_respected"), "%s replaced relational memory with reconstruction" % tone)
	if tone == &"defiant": _expect(state.flags.has(&"flag.route.yuyuko.empty_plate.memory_not_inventory"), "defiant did not reject treating memory as inventory")


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2031)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakugyokurou"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.yyk.joke_about_death", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.yyk.joke_about_death", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(YUYUKO, 2))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Yuyuko Empty Plate integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
