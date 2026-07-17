extends SceneTree
## Proves Patchouli's authored route stages unlock in order.

const EVENTS: Array[StringName] = [
	&"evt.pch.library_breathing_room",
	&"evt.pch.question_worth_asking",
	&"evt.pch.shared_silence_different_books",
	&"evt.pch.borrowing_argument",
	&"evt.pch.spell_for_two_readers",
	&"evt.pch.book_answers_everything",
]
var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Patchouli route content could not load"])
		return
	var evaluator := EventPredicateEvaluator.new()
	for index: int in range(EVENTS.size()): _expect_gate(evaluator, EVENTS[index], index)
	_finish(_failures)


func _expect_gate(evaluator: EventPredicateEvaluator, event_id: StringName, index: int) -> void:
	var graph := _content.graph(event_id)
	var state := _state(StringName("p192%d" % index))
	if index == 0:
		_expect(evaluator.all_pass(evaluator.evaluate_all(graph.availability, state)), "Patchouli's opening event was unavailable")
		return
	_expect(not evaluator.all_pass(evaluator.evaluate_all(graph.availability, state)), "%s unlocked before %s" % [event_id, EVENTS[index - 1]])
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetEventPositionCommand.new(EVENTS[index - 1], &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(EVENTS[index - 1], &"complete"))
	_expect(evaluator.all_pass(evaluator.evaluate_all(graph.availability, state)), "%s remained locked after its predecessor" % event_id)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters(): characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations(): locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1921)
	state.chapter_id = &"chapter.1"
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Patchouli route availability integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
