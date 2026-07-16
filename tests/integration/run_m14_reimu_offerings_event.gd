extends SceneTree
## Traverses all four work tones and all three respectful danmaku outcomes.

const EVENT_ID: StringName = &"evt.hkr.offerings_without_owners"
const JOURNAL_ID: StringName = &"journal.hkr.offerings_without_owners"
const TONE_FLAGS: Array[StringName] = [
	&"flag.route.reimu.offerings.sorted",
	&"flag.route.reimu.offerings.appraised",
	&"flag.route.reimu.offerings.instructions_followed",
	&"flag.route.reimu.offerings.duty_named",
]

var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	var report := _content.load_sources()
	if not report.is_success():
		_finish(["content could not be loaded: %s" % report.human_readable()])
		return
	var graph := _content.graph(EVENT_ID)
	if graph == null:
		_finish(["Offerings Without Owners graph is missing"])
		return
	var graph_errors := EventGraphValidator.new().validate(graph)
	if not graph_errors.is_empty():
		_finish(["Offerings Without Owners graph is invalid: %s" % "; ".join(graph_errors)])
		return
	var tones: Array[StringName] = [&"direct", &"playful", &"patient", &"defiant"]
	var results: Array[StringName] = [&"clear", &"assist_clear", &"loss", &"clear"]
	for index: int in range(tones.size()):
		_run_branch(graph, tones[index], results[index], index)
	_finish(_failures)


func _run_branch(graph: EventGraphRecord, tone: StringName, result_tag: StringName, profile_index: int) -> void:
	var state := _create_state(StringName("p14%d" % profile_index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	_expect(result.status == EventInterpreterResult.Status.WAIT_INPUT and result.node_id == &"n003", "%s did not reach the ownerless offerings" % tone)
	result = interpreter.advance_line()
	_expect(result.node_id == &"n004" and result.beat != null, "%s omitted Reimu naming shrine duty" % tone)
	result = interpreter.advance_line()
	_expect(result.node_id == &"n005" and result.choice != null and result.choice.options.size() == 4, "%s did not reach the four work tones" % tone)
	result = interpreter.choose_tone(tone)
	_expect(result.node_id == StringName("n_%s_line" % tone) and result.beat != null, "%s did not reach its authored work response" % tone)
	_expect_tone_effect(state, tone)
	result = interpreter.advance_line()
	_expect(result.node_id == &"n006" and result.beat != null, "%s omitted the memory-pattern warning" % tone)
	result = interpreter.advance_line()
	_expect(
		result.status == EventInterpreterResult.Status.WAIT_MODE
		and result.node_id == &"n008"
		and result.mode_context != null
		and result.mode_context.mode_id == &"danmaku.hkr.boundary_stain",
		"%s did not yield the shared Boundary Stain handoff" % tone
	)
	var mode_result := ModeResult.new(result_tag)
	mode_result.outcome_tags = [&"strategy.focus_lane"]
	result = interpreter.resume_mode(mode_result)
	var expected_node: StringName = {
		&"clear": &"n_clear",
		&"assist_clear": &"n_assist",
		&"loss": &"n_loss",
	}[result_tag]
	_expect(result.status == EventInterpreterResult.Status.WAIT_INPUT and result.node_id == expected_node, "%s mapped %s to the wrong Reimu response" % [tone, result_tag])
	result = interpreter.advance_line()
	_expect(result.node_id == &"n010" and result.beat != null, "%s omitted Reimu returning the offering" % tone)
	result = interpreter.advance_line()
	_expect(result.node_id == &"n011" and result.beat != null, "%s omitted the second-broom afterbeat" % tone)
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"offerings_returned_to_shrine_care", "%s did not complete the shrine-work outcome" % tone)
	_expect_completion(state, tone)


func _expect_tone_effect(state: GameState, tone: StringName) -> void:
	var expected_index := EventGraphValidator.TONES.find(tone)
	var true_count := 0
	for index: int in range(TONE_FLAGS.size()):
		var flag := state.flags.get(TONE_FLAGS[index]) as FlagState
		if flag != null and flag.value() == true:
			true_count += 1
			_expect(index == expected_index, "%s set the wrong work-tone flag" % tone)
	_expect(true_count == 1, "%s did not commit exactly one work-tone flag" % tone)
	var relationship := state.characters[&"char.reimu_hakurei"].relationship
	var actual := [relationship.trust, relationship.ease, relationship.respect, relationship.spark, relationship.strain]
	var expected: Array = {
		&"direct": [0, 0, 1, 0, 0],
		&"playful": [0, 0, 0, 1, 0],
		&"patient": [0, 1, 0, 0, 0],
		&"defiant": [0, 0, 1, 0, 1],
	}[tone]
	_expect(actual == expected, "%s committed the wrong Reimu facets: %s" % [tone, actual])


func _expect_completion(state: GameState, tone: StringName) -> void:
	_expect(EVENT_ID in state.completed_event_ids, "%s did not record event completion" % tone)
	_expect(EVENT_ID in state.journal.replay_event_ids, "%s did not unlock replay" % tone)
	_expect(state.journal.entries.has(JOURNAL_ID), "%s did not write the ownerless-offering observation" % tone)
	for flag_id: StringName in [&"flag.route.reimu.shrine_function_restored", &"evt.hkr.offerings_without_owners.complete"]:
		var flag := state.flags.get(flag_id) as FlagState
		_expect(flag != null and flag.value() == true, "%s omitted completion flag %s" % [tone, flag_id])
	_expect(RecordedStrategyLedger.ranked_tags(state) == [&"strategy.focus_lane"], "%s did not preserve the reusable focus-lane evidence" % tone)
	if state.journal.entries.has(JOURNAL_ID):
		var entry := state.journal.entries[JOURNAL_ID] as JournalEntryState
		_expect(&"strategy.focus_lane" in entry.tags and &"shrine_duty" in entry.tags, "%s Journal omitted work or strategy evidence" % tone)


func _create_state(profile_id: StringName) -> GameState:
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters():
		character_ids.append(character.id)
	var location_ids: Array[StringName] = []
	for location: LocationRecord in _content.all_locations():
		location_ids.append(location.id)
	var state := GameStateFactory.create_new(profile_id, character_ids, location_ids, 1414)
	state.chapter_id = &"chapter.1"
	state.time_slot = &"day"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakurei_shrine"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.hkr.empty_cushion", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.hkr.empty_cushion", &"complete"))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Reimu Offerings event integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
