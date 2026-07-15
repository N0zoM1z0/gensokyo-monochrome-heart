extends SceneTree
## Drives the real compact fighter through Win and accepted-Loss event returns.

const MODE_SCENE := preload("res://src/presentation/fighter/CompactFighterMode.tscn")

var _failures: Array[String] = []
var _content := ContentRepository.new()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not _content.load_sources().is_success():
		_finish(["content could not be loaded for the fighter integration"])
		return
	var graph := _fighter_event_graph()
	var graph_errors := EventGraphValidator.new().validate(graph)
	if not graph_errors.is_empty():
		_finish(["synthetic fighter event is invalid: %s" % "; ".join(graph_errors)])
		return
	await _run_win_branch(graph)
	await _run_loss_branch(graph)
	_finish(_failures)


func _run_win_branch(graph: EventGraphRecord) -> void:
	var state := _create_event_state(&"p81")
	var interpreter := EventInterpreter.new()
	var event_yield := interpreter.start(graph, state, _content)
	_expect(
		event_yield.status == EventInterpreterResult.Status.WAIT_MODE
		and event_yield.node_id == &"n_duel"
		and event_yield.mode_context != null
		and event_yield.mode_context.mode_type == &"start_duel"
		and event_yield.mode_context.mode_id == &"duel.hkr.spell_card_terms",
		"event did not yield the typed compact-fighter handoff"
	)
	if event_yield.mode_context == null:
		return
	var story_before_mode := GameStateCodec.new().canonical_state(state)
	var assists := FighterAssistSettings.new()
	assists.simple_inputs = true
	assists.hold_to_guard = true
	assists.speed_percent = 70
	assists.auto_face = true
	var mode := MODE_SCENE.instantiate() as CompactFighterMode
	if mode == null:
		_failures.append("compact fighter Win scene could not be instantiated")
		return
	mode.configure(event_yield.mode_context)
	mode.configure_assists(assists)
	var emitted_results: Array[ModeResult] = []
	mode.mode_completed.connect(func(result: ModeResult) -> void: emitted_results.append(result))
	get_root().add_child(mode)
	await process_frame
	mode.suspend()

	_expect(
		mode.action_contract() == PackedStringArray([
			"move", "light", "heavy", "skill", "spell", "guard", "pause", "confirm", "cancel",
		]),
		"compact fighter omitted an action from its semantic contract"
	)
	_expect(
		mode.runtime.assists.simple_inputs
		and mode.runtime.assists.hold_to_guard
		and mode.runtime.assists.speed_percent == 70
		and mode.runtime.assists.auto_face,
		"compact fighter did not apply the complete story-assist handoff"
	)
	var right := FighterInputFrame.new()
	right.horizontal_axis = 1
	mode.step_fixture(20, right)
	var deterministic_snapshot := mode.state_snapshot()
	mode.pause_for_test()
	mode.step_fixture(60, right)
	_expect(
		mode.is_paused_state() and mode.state_snapshot() == deterministic_snapshot,
		"paused fighter presentation continued its simulation"
	)
	mode.handle_semantic_action(GameInput.PAUSE)
	_expect(
		not mode.is_paused_state()
		and int(mode.capture_debug_state().get("resume_countdown_ticks", 0)) == 3,
		"fighter resume did not arm the required three-frame countdown"
	)
	mode.retry_for_test()
	mode.step_fixture(20, right)
	_expect(
		mode.state_snapshot() == deterministic_snapshot,
		"presentation-level fighter retry did not reproduce fixed-step state"
	)
	mode.pause_for_test()
	var before_frame_step := mode.runtime.encounter_tick
	mode.training_frame_step_for_test(right)
	_expect(
		mode.runtime.encounter_tick == before_frame_step + 1 and mode.is_paused_state(),
		"fighter training frame-step did not advance exactly one paused tick"
	)
	mode.pause_for_test()
	mode.force_spell_break_for_test(0)
	_expect(
		mode.runtime.states[0].breaks_won == 1 and mode.current_result() == null,
		"first forced Spell Break did not reset into the second phase"
	)
	mode.force_spell_break_for_test(0)
	var win := mode.current_result()
	_expect(
		win != null
		and win.result_tag == &"win"
		and win.telemetry != null
		and win.telemetry.attempt_count == 2,
		"two Spell Breaks did not return a typed Win with retry telemetry"
	)
	_expect(
		GameStateCodec.new().canonical_state(state) == story_before_mode,
		"mechanical fighter mode mutated route state before returning"
	)
	mode.handle_semantic_action(GameInput.CONFIRM)
	mode.handle_semantic_action(GameInput.CONFIRM)
	_expect(
		emitted_results.size() == 1 and emitted_results[0] == win,
		"fighter Win confirmation did not emit exactly once"
	)
	event_yield = interpreter.resume_mode(win)
	_expect(
		event_yield.status == EventInterpreterResult.Status.END
		and event_yield.outcome == &"win"
		and graph.id in state.completed_event_ids,
		"fighter Win did not complete its authored event branch"
	)
	mode.free()


func _run_loss_branch(graph: EventGraphRecord) -> void:
	var state := _create_event_state(&"p82")
	var interpreter := EventInterpreter.new()
	var event_yield := interpreter.start(graph, state, _content)
	var mode := MODE_SCENE.instantiate() as CompactFighterMode
	if mode == null:
		_failures.append("compact fighter Loss scene could not be instantiated")
		return
	mode.configure(event_yield.mode_context)
	get_root().add_child(mode)
	await process_frame
	mode.suspend()
	var accepted_loss := mode.accept_loss_for_test()
	_expect(
		accepted_loss != null and accepted_loss.result_tag == &"loss",
		"Accept Loss did not return a valid fighter story result"
	)
	event_yield = interpreter.resume_mode(accepted_loss)
	_expect(
		event_yield.status == EventInterpreterResult.Status.END
		and event_yield.outcome == &"loss"
		and graph.id in state.completed_event_ids,
		"accepted fighter Loss did not remain story-completable"
	)
	mode.free()


func _fighter_event_graph() -> EventGraphRecord:
	var graph := EventGraphRecord.new(
		1,
		&"evt.fixture.fighter_return",
		&"ui.fighter.terms.title",
		&"loc.hakurei_shrine",
		&"spot.hkr.veranda",
		[],
		&"n_duel",
		[],
		"res://tests/integration/run_m08_fighter_event_flow.gd"
	)
	var mode_node := EventNodeRecord.new(&"n_duel", &"start_duel")
	mode_node.minigame_id = &"duel.hkr.spell_card_terms"
	mode_node.result_branches = [
		ModeResultBranchRecord.new(&"win", &"n_win"),
		ModeResultBranchRecord.new(&"loss", &"n_loss"),
	]
	var win_end := EventNodeRecord.new(&"n_win", &"end_event")
	win_end.outcome = &"win"
	var loss_end := EventNodeRecord.new(&"n_loss", &"end_event")
	loss_end.outcome = &"loss"
	graph.nodes = [mode_node, win_end, loss_end]
	return graph


func _create_event_state(profile_id: StringName) -> GameState:
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters():
		character_ids.append(character.id)
	var location_ids: Array[StringName] = []
	for location: LocationRecord in _content.all_locations():
		location_ids.append(location.id)
	var state := GameStateFactory.create_new(profile_id, character_ids, location_ids, 8080)
	state.chapter_id = &"chapter.1"
	state.time_slot = &"day"
	GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.hakurei_shrine"))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M08 fighter/event integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
