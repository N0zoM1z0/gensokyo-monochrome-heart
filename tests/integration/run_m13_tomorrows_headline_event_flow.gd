extends SceneTree
## Traverses every publication-boundary tone and every Wind-Frame return branch.

const EVENT_ID: StringName = &"evt.mtn.tomorrows_headline"
const JOURNAL_ID: StringName = &"journal.mtn.tomorrows_headline"
const KEEPSAKE_ID: StringName = &"item.keepsake.unprinted_caption"
const BOUNDARY_FLAGS: Array[StringName] = [
	&"flag.mtn.headline.boundary.off_record",
	&"flag.mtn.headline.boundary.correction",
	&"flag.mtn.headline.boundary.inspect_first",
	&"flag.mtn.headline.boundary.causal_challenge",
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
		_finish(["Tomorrow's Headline graph is missing"])
		return
	var graph_errors := EventGraphValidator.new().validate(graph)
	if not graph_errors.is_empty():
		_finish(["Tomorrow's Headline graph is invalid: %s" % "; ".join(graph_errors)])
		return
	var tones: Array[StringName] = [&"direct", &"playful", &"patient", &"defiant"]
	var result_tags: Array[StringName] = [&"clear", &"assist_clear", &"loss", &"clear"]
	for index: int in range(tones.size()):
		_run_branch(graph, tones[index], result_tags[index], index)
	_finish(_failures)


func _run_branch(
	graph: EventGraphRecord,
	tone: StringName,
	result_tag: StringName,
	profile_index: int
) -> void:
	var state := _create_state(StringName("p13%d" % profile_index))
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	_expect(
		result.status == EventInterpreterResult.Status.WAIT_INPUT
		and result.node_id == &"n003"
		and result.beat != null,
		"%s did not reach Aya's opening line" % tone
	)
	result = interpreter.advance_line()
	_expect(result.node_id == &"n004" and result.beat != null, "%s omitted Aya's evidence line" % tone)
	result = interpreter.advance_line()
	_expect(
		result.node_id == &"n005"
		and result.choice != null
		and result.choice.options.size() == 4,
		"%s did not reach the four-tone publication boundary" % tone
	)
	result = interpreter.choose_tone(tone)
	_expect(
		result.node_id == StringName("n_%s_line" % tone) and result.beat != null,
		"%s did not reach its authored boundary response" % tone
	)
	_expect_tone_effect(tone, state)
	result = interpreter.advance_line()
	_expect(result.node_id == &"n_photo_origin" and result.beat != null, "%s omitted the causal setup" % tone)
	result = interpreter.advance_line()
	_expect(
		result.status == EventInterpreterResult.Status.WAIT_MODE
		and result.node_id == &"n_danmaku"
		and result.mode_context != null
		and result.mode_context.mode_type == &"start_danmaku"
		and result.mode_context.mode_id == &"danmaku.mtn.tomorrows_headline",
		"%s did not yield the Wind-Frame handoff" % tone
	)
	result = interpreter.resume_mode(ModeResult.new(result_tag))
	var expected_result_node: StringName = {
		&"clear": &"n_danmaku_clear",
		&"assist_clear": &"n_danmaku_assist",
		&"loss": &"n_danmaku_loss",
	}[result_tag]
	_expect(
		result.status == EventInterpreterResult.Status.WAIT_INPUT
		and result.node_id == expected_result_node,
		"%s mapped %s to the wrong Aya response" % [tone, result_tag]
	)
	result = interpreter.advance_line()
	_expect(result.node_id == &"n_after_01" and result.beat != null, "%s omitted the patrol reveal" % tone)
	result = interpreter.advance_line()
	_expect(result.node_id == &"n_after_02" and result.beat != null, "%s omitted Aya lowering her camera" % tone)
	result = interpreter.advance_line()
	_expect(
		result.status == EventInterpreterResult.Status.END
		and result.outcome == &"headline_withheld_pending_correction",
		"%s did not complete the authored outcome" % tone
	)
	_expect_completion(state, tone)


func _expect_tone_effect(tone: StringName, state: GameState) -> void:
	var flag_index := EventGraphValidator.TONES.find(tone)
	var true_flags := 0
	for index: int in range(BOUNDARY_FLAGS.size()):
		var flag := state.flags.get(BOUNDARY_FLAGS[index]) as FlagState
		if flag != null and flag.value() == true:
			true_flags += 1
			_expect(index == flag_index, "%s set the wrong publication-boundary flag" % tone)
	_expect(true_flags == 1, "%s did not commit exactly one publication boundary" % tone)
	var aya := state.characters[&"char.aya_shameimaru"].relationship
	var actual := [aya.trust, aya.ease, aya.respect, aya.spark, aya.strain]
	var expected: Array = {
		&"direct": [0, 0, 1, 0, 0],
		&"playful": [0, 0, 0, 1, 0],
		&"patient": [0, 1, 0, 0, 0],
		&"defiant": [0, 0, 0, 0, 1],
	}[tone]
	_expect(actual == expected, "%s committed the wrong Aya relationship facet: %s" % [tone, actual])


func _expect_completion(state: GameState, tone: StringName) -> void:
	_expect(EVENT_ID in state.completed_event_ids, "%s did not record event completion" % tone)
	_expect(EVENT_ID in state.journal.replay_event_ids, "%s did not unlock Journal replay" % tone)
	_expect(state.inventory.keepsakes.has(KEEPSAKE_ID), "%s did not grant the unprinted caption" % tone)
	_expect(state.journal.entries.has(JOURNAL_ID), "%s did not write the Journal observation" % tone)
	for flag_id: StringName in [
		&"flag.mtn.prediction_performance.observed",
		&"flag.mtn.headline.withheld",
		&"evt.mtn.tomorrows_headline.complete",
	]:
		var flag := state.flags.get(flag_id) as FlagState
		_expect(flag != null and flag.value() == true, "%s omitted completion flag %s" % [tone, flag_id])
	if state.inventory.keepsakes.has(KEEPSAKE_ID):
		var keepsake := state.inventory.keepsakes[KEEPSAKE_ID] as KeepsakeState
		_expect(
			keepsake.owner_character_id == &"char.aya_shameimaru"
			and keepsake.dialogue_tags == [&"mtn.tomorrows_headline", &"boundary.off_record"],
			"%s lost the unprinted caption's Aya context" % tone
		)


func _create_state(profile_id: StringName) -> GameState:
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters():
		character_ids.append(character.id)
	var location_ids: Array[StringName] = []
	for location: LocationRecord in _content.all_locations():
		location_ids.append(location.id)
	var state := GameStateFactory.create_new(profile_id, character_ids, location_ids, 1313)
	state.chapter_id = &"chapter.1"
	state.time_slot = &"day"
	GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.youkai_mountain"))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M13 Tomorrow's Headline event integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
