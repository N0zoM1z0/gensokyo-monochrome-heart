extends SceneTree
## Covers every response tone for Sakuya's first route event after the Missing Minute.

const EVENT_ID: StringName = &"evt.sdm.corridor_no_dust"
const SAKUYA: StringName = &"char.sakuya_izayoi"

var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Sakuya corridor content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	for index: int in range(EventGraphValidator.TONES.size()):
		_run(graph, EventGraphValidator.TONES[index], index)
	_finish(_failures)


func _run(graph: EventGraphRecord, tone: StringName, index: int) -> void:
	var state := _state(StringName("p158%d" % index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	_expect(result.node_id == &"n003", "%s did not reach the unwalked corridor" % tone)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach four corridor responses" % tone)
	result = interpreter.choose_tone(tone)
	_expect(result.node_id == StringName("n_%s_line" % tone), "%s did not reach its authored response" % tone)
	result = interpreter.advance_line()
	_expect(result.node_id == &"n_after", "%s omitted the corridor afterbeat" % tone)
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"corridor_left_walkable", "%s did not complete the corridor" % tone)
	_expect(state.characters[SAKUYA].route_stage == 2, "%s did not advance Sakuya to stage two" % tone)
	_expect(state.journal.entries.has(&"journal.sdm.corridor_no_dust"), "%s omitted the corridor Journal entry" % tone)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters():
		characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations():
		locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1581)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.scarlet_devil_mansion"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.sdm.late_by_three_minutes", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.sdm.late_by_three_minutes", &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(SAKUYA, 1))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Sakuya corridor event integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
