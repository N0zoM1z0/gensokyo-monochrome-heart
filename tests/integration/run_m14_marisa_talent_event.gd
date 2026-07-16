extends SceneTree
## Proves the talent-comparison conflict continues through every tone without hiding the failed joke.

const EVENT_ID: StringName = &"evt.mrs.talent_bad_conversation"
var _content := ContentRepository.new()
var _failures: Array[String] = []

func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Talent conflict content could not load"])
		return
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(_content.graph(EVENT_ID), EventGraphValidator.TONES[index], index)
	_finish(_failures)

func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p154%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the comparison conflict" % tone)
	result = interpreter.choose_tone(tone)
	result = interpreter.advance_line(); result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"effort_named_without_ranking", "%s did not continue conflict to completion" % tone)
	_expect(state.characters[&"char.marisa_kirisame"].route_stage == 4, "%s did not advance Marisa to stage four" % tone)
	_expect(state.journal.entries.has(&"journal.mrs.talent_bad_conversation"), "%s omitted conflict Journal evidence" % tone)
	if tone == &"playful":
		var flag := state.flags.get(&"flag.route.marisa.talent.joke_failed") as FlagState
		_expect(flag != null and flag.value() == true and state.characters[&"char.marisa_kirisame"].relationship.strain == 1, "failed joke did not remain visible as strain")

func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1541)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new(); dispatcher.dispatch(state, SetLocationCommand.new(&"loc.forest_of_magic"))
	for event_id: StringName in [&"evt.mrs.crash_landing", &"evt.mrs.field_notes", &"evt.mrs.shelf_marked_later"]:
		dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor")); dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(&"char.marisa_kirisame", 3)); return state

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
func _finish(failures: Array[String]) -> void:
	print("M14 Marisa talent conflict integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
