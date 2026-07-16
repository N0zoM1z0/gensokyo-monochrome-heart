extends SceneTree
## Proves Sakuya's final promise exposes every explicit route intent and persists it.

const EVENT_ID: StringName = &"evt.sdm.promise"
const SAKUYA: StringName = &"char.sakuya_izayoi"

var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["Sakuya Promise content could not load"])
		return
	var graph := _content.graph(EVENT_ID)
	_run(graph, &"friendship", &"direct", &"after_hours_kitchen_invitation", 0)
	_run(graph, &"romance", &"playful", &"evening_not_work", 1)
	_run(graph, &"postponed", &"patient", &"time_left_open", 2)
	_run(graph, &"undecided", &"defiant", &"future_not_scheduled", 3)
	_finish(_failures)


func _run(graph: EventGraphRecord, intent: StringName, tone: StringName, expected_outcome: StringName, index: int) -> void:
	var state := _state(StringName("p163%d" % index))
	if intent == &"undecided":
		GameCommandDispatcher.new().dispatch(state, SetRouteIntentCommand.new(SAKUYA, &"romance"))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	_expect(not result.is_error(), "%s could not start Promise: %s" % [intent, result.diagnostic])
	_expect(result.node_id == &"n003", "%s did not reach Sakuya's invitation" % intent)
	result = interpreter.advance_line()
	_expect(result.node_id == &"n004", "%s did not reach the explicit-promise question" % intent)
	result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not see four explicit commitments" % intent)
	if result.choice != null:
		_expect(result.choice.option_for_tone(tone) != null, "%s commitment was not available" % intent)
	result = interpreter.choose_tone(tone)
	_expect(result.node_id == StringName("n_%s" % intent), "%s did not reach its response" % intent)
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == expected_outcome, "%s did not finish its authored outcome" % intent)
	_expect(state.characters[SAKUYA].route_stage == 7, "%s did not advance Sakuya to stage seven" % intent)
	_expect(state.characters[SAKUYA].route_intent == intent, "%s did not persist the selected route intent" % intent)
	_expect(state.journal.entries.has(&"journal.sdm.promise"), "%s omitted the final Journal entry" % intent)


func _state(profile_id: StringName) -> GameState:
	var characters: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters():
		characters.append(character.id)
	var locations: Array[StringName] = []
	for location: LocationRecord in _content.all_locations():
		locations.append(location.id)
	var state := GameStateFactory.create_new(profile_id, characters, locations, 1631)
	state.chapter_id = &"chapter.1"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.scarlet_devil_mansion"))
	for event_id: StringName in [
		&"evt.sdm.late_by_three_minutes",
		&"evt.sdm.corridor_no_dust",
		&"evt.sdm.kitchen_after_midnight",
		&"evt.sdm.competence_not_consent",
		&"evt.sdm.favor_cannot_optimize",
		&"evt.sdm.missing_minute",
	]:
		dispatcher.dispatch(state, SetEventPositionCommand.new(event_id, &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(event_id, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(SAKUYA, 6))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Sakuya Promise finale integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
