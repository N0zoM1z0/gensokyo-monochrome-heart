extends SceneTree
## Proves Yuyuko's levity protects a frightened spirit without erasing death or choice.

const EVENT_ID: StringName = &"evt.yyk.joke_about_death"
const YUYUKO: StringName = &"char.yuyuko_saigyouji"
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["A Joke About Death content could not load"])
		return
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p202%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the levity responses" % tone)
	result = interpreter.choose_tone(tone); result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"levity_made_room_for_the_spirits_own_question", "%s did not complete the protected conversation" % tone)
	_expect(state.characters[YUYUKO].route_stage == 2 and state.journal.entries.has(&"journal.yyk.joke_about_death"), "%s did not preserve the death-joke evidence" % tone)
	_expect(state.flags.has(&"flag.route.yuyuko.death_joke.protection_recognized") and state.flags.has(&"flag.route.yuyuko.death_joke.death_not_erased"), "%s let levity deny or trivialize death" % tone)
	if tone == &"defiant": _expect(state.flags.has(&"flag.route.yuyuko.death_joke.guest_mood_not_decided"), "defiant did not return the mood to the protected spirit")


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 2021)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakugyokurou"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.yyk.bottomless_banquet", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.yyk.bottomless_banquet", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(YUYUKO, 1))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Yuyuko A Joke About Death integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
