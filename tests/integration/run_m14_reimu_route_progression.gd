extends SceneTree
## Proves Reimu's non-romantic route checkpoints survive saves and Journal replay stays read-only.

const REIMU: StringName = &"char.reimu_hakurei"
const OFFERINGS: StringName = &"evt.hkr.offerings_without_owners"
const QUIET_DAY: StringName = &"evt.hkr.day_nothing_happens"

var _content := ContentRepository.new()
var _failures: Array[String] = []


func _initialize() -> void:
	if not _content.load_sources().is_success():
		_finish(["route progression content could not be loaded"])
		return
	var state := _create_state()
	if state == null:
		_finish(["route progression state could not be created"])
		return
	_run_offerings(state)
	_expect_checkpoint(state, 1, OFFERINGS, &"journal.hkr.offerings_without_owners")
	_expect_codec_round_trip(state, 1)
	_run_quiet_day(state)
	_expect_checkpoint(state, 2, QUIET_DAY, &"journal.hkr.day_nothing_happens")
	_expect_codec_round_trip(state, 2)
	_expect_quiet_replay_is_read_only(state)
	_finish(_failures)


func _run_offerings(state: GameState) -> void:
	var graph := _content.graph(OFFERINGS)
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	result = interpreter.choose_tone(&"patient")
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE, "Offerings did not reach Boundary Stain")
	result = interpreter.resume_mode(ModeResult.new(&"assist_clear"))
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END, "Offerings did not reach its route checkpoint")


func _run_quiet_day(state: GameState) -> void:
	var graph := _content.graph(QUIET_DAY)
	var interpreter := EventInterpreter.new()
	var result := interpreter.start(graph, state, _content)
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	result = interpreter.choose_tone(&"patient")
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE, "Quiet day did not reach the chore handoff")
	result = interpreter.resume_mode(ModeResult.new(&"clear"))
	result = interpreter.advance_line()
	result = interpreter.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END, "Quiet day did not reach its route checkpoint")


func _expect_checkpoint(state: GameState, expected_stage: int, event_id: StringName, journal_id: StringName) -> void:
	_expect(state.characters[REIMU].route_intent == &"friendship", "non-romantic route intent changed during %s" % event_id)
	_expect(state.characters[REIMU].route_stage == expected_stage, "%s did not persist route stage %d" % [event_id, expected_stage])
	_expect(event_id in state.completed_event_ids, "%s was not recorded as complete" % event_id)
	_expect(event_id in state.journal.replay_event_ids, "%s did not unlock Journal replay" % event_id)
	_expect(state.journal.entries.has(journal_id), "%s did not write its Journal object" % event_id)


func _expect_codec_round_trip(state: GameState, expected_stage: int) -> void:
	var codec := GameStateCodec.new()
	var decoded := codec.decode(codec.encode(state))
	_expect(decoded.is_success(), "route checkpoint %d could not be decoded from save data" % expected_stage)
	if decoded.is_success():
		_expect(decoded.state.characters[REIMU].route_intent == &"friendship", "save changed the non-romantic route intent at stage %d" % expected_stage)
		_expect(decoded.state.characters[REIMU].route_stage == expected_stage, "save lost route stage %d" % expected_stage)
		_expect(codec.canonical_state(decoded.state) == codec.canonical_state(state), "save round trip changed route checkpoint %d" % expected_stage)


func _expect_quiet_replay_is_read_only(state: GameState) -> void:
	var opening := GameStateCodec.new().canonical_state(state)
	var replay := EventInterpreter.new()
	var graph := _content.graph(QUIET_DAY)
	var result := replay.start(graph, state, _content, true)
	result = replay.advance_line()
	result = replay.advance_line()
	result = replay.choose_tone(&"direct")
	result = replay.advance_line()
	result = replay.advance_line()
	_expect(result.status == EventInterpreterResult.Status.WAIT_MODE and result.mode_context.is_replay, "Journal replay did not use a read-only quiet-chore handoff")
	result = replay.resume_mode(ModeResult.new(&"clear"))
	result = replay.advance_line()
	result = replay.advance_line()
	_expect(result.status == EventInterpreterResult.Status.END, "Journal replay did not complete the quiet-day graph")
	_expect(GameStateCodec.new().canonical_state(state) == opening, "Journal replay mutated Reimu route state")


func _create_state() -> GameState:
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters():
		character_ids.append(character.id)
	var location_ids: Array[StringName] = []
	for location: LocationRecord in _content.all_locations():
		location_ids.append(location.id)
	var state := GameStateFactory.create_new(&"p144", character_ids, location_ids, 1444)
	state.chapter_id = &"chapter.1"
	state.time_slot = &"dusk"
	var dispatcher := GameCommandDispatcher.new()
	dispatcher.dispatch(state, SetLocationCommand.new(&"loc.hakurei_shrine"))
	dispatcher.dispatch(state, SetRouteIntentCommand.new(REIMU, &"friendship"))
	dispatcher.dispatch(state, SetEventPositionCommand.new(&"evt.hkr.empty_cushion", &"n_route_predecessor"))
	dispatcher.dispatch(state, CompleteEventCommand.new(&"evt.hkr.empty_cushion", &"complete"))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Reimu route progression integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
