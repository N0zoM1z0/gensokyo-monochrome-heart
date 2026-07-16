extends SceneTree
## Proves all four tones converge on a no-slot, no-failure silence-tolerance clear.

const EVENT_ID: StringName = &"evt.hkr.day_nothing_happens"
const JOURNAL_ID: StringName = &"journal.hkr.day_nothing_happens"
const TONE_FLAGS: Array[StringName] = [
	&"flag.route.reimu.quiet.direct_work",
	&"flag.route.reimu.quiet.silence_bet",
	&"flag.route.reimu.quiet.followed_rhythm",
	&"flag.route.reimu.quiet.patch_challenged",
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
		_finish(["The Day Nothing Happens graph is missing"])
		return
	var tones: Array[StringName] = [&"direct", &"playful", &"patient", &"defiant"]
	for index: int in range(tones.size()):
		_run_branch(graph, tones[index], index == 2, index)
	_finish(_failures)


func _run_branch(graph: EventGraphRecord, tone: StringName, story_pacing: bool, profile_index: int) -> void:
	var state := _create_state(StringName("p143%d" % profile_index))
	var opening_slot := state.time_slot
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	_expect(result.status == EventInterpreterResult.Status.WAIT_INPUT and result.node_id == &"n003", "%s did not reach the ordinary afternoon" % tone)
	result = interpreter.advance_line()
	_expect(result.node_id == &"n004" and result.beat != null, "%s omitted Reimu refusing an invented incident" % tone)
	result = interpreter.advance_line()
	_expect(result.node_id == &"n005" and result.choice != null and result.choice.options.size() == 4, "%s did not reach four chore tones" % tone)
	result = interpreter.choose_tone(tone)
	_expect(result.node_id == StringName("n_%s_line" % tone) and result.beat != null, "%s did not reach its authored quiet-work response" % tone)
	_expect_tone_effect(state, tone)
	result = interpreter.advance_line()
	_expect(result.node_id == &"n006" and result.beat != null, "%s omitted the sweep-mend-sit instruction" % tone)
	result = interpreter.advance_line()
	_expect(
		result.status == EventInterpreterResult.Status.WAIT_MODE
		and result.node_id == &"n_quiet_chore"
		and result.mode_context != null
		and result.mode_context.mode_id == &"mini.hkr.quiet_chore",
		"%s did not yield the quiet chore runtime" % tone
	)
	var game := QuietChoreSimulation.new()
	var settings := MinigameAssistSettings.new()
	settings.slower_pace = story_pacing
	game.configure(result.mode_context, settings)
	var mode_result := _complete_quiet_chore(game)
	_expect(mode_result != null and mode_result.result_tag == &"clear", "%s did not clear through silence" % tone)
	_expect(&"quiet_chore.silence_tolerated" in mode_result.outcome_tags, "%s omitted silence evidence" % tone)
	result = interpreter.resume_mode(mode_result)
	_expect(result.node_id == &"n007" and result.beat != null, "%s omitted the cold-tea line" % tone)
	result = interpreter.advance_line()
	_expect(result.node_id == &"n008" and result.beat != null, "%s omitted the ordinary-afternoon afterbeat" % tone)
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END and result.outcome == &"ordinary_afternoon_shared_without_performance", "%s did not complete the quiet-day outcome" % tone)
	_expect(state.time_slot == opening_slot, "%s consumed a time slot despite the no-slot contract" % tone)
	_expect_completion(state, tone)


func _complete_quiet_chore(game: QuietChoreSimulation) -> ModeResult:
	var confirm := MinigameInputFrame.new()
	confirm.confirm_pressed = true
	game.step(confirm)
	for stroke: int in range(QuietChoreSimulation.REQUIRED_SWEEP_STROKES):
		var sweep := MinigameInputFrame.new()
		sweep.grid_direction.x = -1 if stroke % 2 == 0 else 1
		game.step(sweep)
	for _seam: int in range(QuietChoreSimulation.REQUIRED_MENDED_SEAMS):
		game.step(confirm)
	# An attempted input proves the final segment resets instead of pretending the wait was satisfied.
	for _tick: int in range(30):
		game.step(MinigameInputFrame.new())
	game.step(confirm)
	var required := QuietChoreSimulation.STORY_SILENCE_TICKS if game.assists.slower_pace else QuietChoreSimulation.STANDARD_SILENCE_TICKS
	for _tick: int in range(required):
		game.step(MinigameInputFrame.new())
	return game.final_result


func _expect_tone_effect(state: GameState, tone: StringName) -> void:
	var expected_index := EventGraphValidator.TONES.find(tone)
	var true_count := 0
	for index: int in range(TONE_FLAGS.size()):
		var flag := state.flags.get(TONE_FLAGS[index]) as FlagState
		if flag != null and flag.value() == true:
			true_count += 1
			_expect(index == expected_index, "%s set the wrong quiet-work flag" % tone)
	_expect(true_count == 1, "%s did not commit exactly one quiet-work flag" % tone)
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
	_expect(EVENT_ID in state.completed_event_ids, "%s did not record quiet-day completion" % tone)
	_expect(state.characters[&"char.reimu_hakurei"].route_stage == 2, "%s did not advance Reimu to route stage 2" % tone)
	_expect(EVENT_ID in state.journal.replay_event_ids, "%s did not unlock quiet-day replay" % tone)
	_expect(state.journal.entries.has(JOURNAL_ID), "%s did not write the ordinary-afternoon observation" % tone)
	for flag_id: StringName in [&"flag.route.reimu.silence_tolerated", &"flag.route.reimu.private_habit_seen", &"evt.hkr.day_nothing_happens.complete"]:
		var flag := state.flags.get(flag_id) as FlagState
		_expect(flag != null and flag.value() == true, "%s omitted route progress flag %s" % [tone, flag_id])


func _create_state(profile_id: StringName) -> GameState:
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters():
		character_ids.append(character.id)
	var location_ids: Array[StringName] = []
	for location: LocationRecord in _content.all_locations():
		location_ids.append(location.id)
	var state := GameStateFactory.create_new(profile_id, character_ids, location_ids, 1433)
	state.chapter_id = &"chapter.1"
	state.time_slot = &"dusk"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakurei_shrine"))
	for prior_event: StringName in [&"evt.hkr.empty_cushion", &"evt.hkr.offerings_without_owners"]:
		dispatcher.dispatch(state, SetEventPositionCommand.new(prior_event, &"n_route_predecessor"))
		dispatcher.dispatch(state, CompleteEventCommand.new(prior_event, &"complete"))
	dispatcher.dispatch(state, AdvanceRouteStageCommand.new(&"char.reimu_hakurei", 1))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Reimu quiet-day event integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
