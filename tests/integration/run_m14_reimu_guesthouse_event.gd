extends SceneTree
## Proves Reimu's boundary test completes through every tone and supported Boundary Stain result.

const EVENT_ID: StringName = &"evt.hkr.shrine_not_guesthouse"
const JOURNAL_ID: StringName = &"journal.hkr.shrine_not_guesthouse"
const TONE_FLAGS: Array[StringName] = [
	&"flag.route.reimu.boundary.admitted_refuge",
	&"flag.route.reimu.boundary.joked_past_labor",
	&"flag.route.reimu.boundary.asked_for_work",
	&"flag.route.reimu.boundary.named_uneven_burden",
]

var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["guesthouse boundary content could not be loaded"])
		return
	var graph := _content.graph(EVENT_ID)
	if graph == null:
		_finish(["guesthouse boundary graph is missing"])
		return
	var tones: Array[StringName] = [&"direct", &"playful", &"patient", &"defiant"]
	var results: Array[StringName] = [&"clear", &"assist_clear", &"loss", &"clear"]
	for index: int in range(tones.size()):
		_run_branch(graph, tones[index], results[index], index)
	_finish(_failures)


func _run_branch(graph: EventGraphRecord, tone: StringName, result_tag: StringName, profile_index: int) -> void:
	var state := _create_state(StringName("p145%d" % profile_index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	_expect(result.status == EventInterpreterResult.Status.WAIT_INPUT and result.node_id == &"n003", "%s did not reach the bag-at-the-door boundary" % tone)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.choice != null and result.choice.options.size() == 4, "%s did not reach the four boundary responses" % tone)
	result = interpreter.choose_tone(tone)
	_expect(result.node_id == StringName("n_%s_line" % tone), "%s did not receive its boundary response" % tone)
	_expect_tone_effect(state, tone)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE and result.mode_context.mode_id == &"danmaku.hkr.boundary_stain", "%s did not hand off shared boundary labor" % tone)
	result = interpreter.resume_mode(ModeResult.new(result_tag))
	_expect(result.node_id == {&"clear": &"n_clear", &"assist_clear": &"n_assist", &"loss": &"n_loss"}[result_tag], "%s sent %s to the wrong response" % [tone, result_tag])
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"welcome_named_without_claiming_the_shrine", "%s did not complete the boundary event" % tone)
	_expect(state.characters[&"char.reimu_hakurei"].route_stage == 3, "%s did not advance Reimu to stage 3" % tone)
	_expect(EVENT_ID in state.completed_event_ids and EVENT_ID in state.journal.replay_event_ids, "%s did not complete and unlock replay" % tone)
	_expect(state.journal.entries.has(JOURNAL_ID), "%s did not write the west-marker Journal object" % tone)


func _expect_tone_effect(state: GameState, tone: StringName) -> void:
	var expected_index := EventGraphValidator.TONES.find(tone)
	var true_count := 0
	for index: int in range(TONE_FLAGS.size()):
		var flag := state.flags.get(TONE_FLAGS[index]) as FlagState
		if flag != null and flag.value() == true:
			true_count += 1
			_expect(index == expected_index, "%s set the wrong boundary record" % tone)
	_expect(true_count == 1, "%s did not record exactly one boundary response" % tone)


func _create_state(profile_id: StringName) -> GameState:
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters():
		character_ids.append(character.id)
	var location_ids: Array[StringName] = []
	for location: LocationRecord in _content.all_locations():
		location_ids.append(location.id)
	var state := GameStateFactory.create_new(profile_id, character_ids, location_ids, 1454)
	state.chapter_id = &"chapter.1"
	state.time_slot = &"dusk"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakurei_shrine"))
	for prior_event: StringName in [&"evt.hkr.empty_cushion", &"evt.hkr.offerings_without_owners", &"evt.hkr.day_nothing_happens"]:
		dispatcher.dispatch(state, SetEventPositionCommand.new(prior_event, &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(prior_event, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(&"char.reimu_hakurei", 2))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Reimu guesthouse boundary event integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
