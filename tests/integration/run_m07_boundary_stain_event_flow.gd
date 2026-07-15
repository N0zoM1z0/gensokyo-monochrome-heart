extends SceneTree
## Drives the real Boundary Stain scene through clear, loss, and assist event returns.

const MODE_SCENE := preload("res://src/presentation/danmaku/BoundaryStainMode.tscn")

var _failures: Array[String] = []
var _content := ContentRepository.new()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not _content.load_sources().is_success():
		_finish(["content could not be loaded for the Boundary Stain integration"])
		return
	var graph := _boundary_event_graph()
	var graph_errors := EventGraphValidator.new().validate(graph)
	if not graph_errors.is_empty():
		_finish(["synthetic Boundary Stain event is invalid: %s" % "; ".join(graph_errors)])
		return
	await _run_clear_branch(graph)
	await _run_loss_branch(graph)
	await _run_assist_branch(graph)
	_finish(_failures)


func _run_clear_branch(graph: EventGraphRecord) -> void:
	var state := _create_event_state(&"p71")
	var interpreter := EventInterpreter.new()
	var event_yield := interpreter.start(graph, state, _content)
	_expect(
		event_yield.status == EventInterpreterResult.Status.WAIT_MODE
		and event_yield.node_id == &"n_mode"
		and event_yield.mode_context != null
		and event_yield.mode_context.mode_type == &"start_danmaku"
		and event_yield.mode_context.mode_id == &"danmaku.hkr.boundary_stain",
		"event did not yield the typed Boundary Stain handoff"
	)
	if event_yield.mode_context == null:
		return
	event_yield.mode_context.deterministic_seed = 7070
	var story_before_mode := GameStateCodec.new().canonical_state(state)
	var mode := MODE_SCENE.instantiate() as BoundaryStainMode
	var assists := DanmakuAssistSettings.new()
	assists.bullet_speed_percent = 70
	assists.density_percent = 55
	assists.safe_lane_preview = true
	assists.auto_bomb = true
	assists.larger_graze_radius = true
	assists.background_dim_percent = 70
	assists.no_flash = true
	mode.configure(event_yield.mode_context)
	mode.configure_assists(assists)
	var emitted_results: Array[ModeResult] = []
	mode.mode_completed.connect(func(result: ModeResult) -> void: emitted_results.append(result))
	get_root().add_child(mode)
	await process_frame
	mode.suspend()

	_expect(
		mode.action_contract() == PackedStringArray(["move", "shot", "focus", "bomb", "companion", "pause", "confirm", "cancel"]),
		"Boundary Stain scene omitted a semantic action from its mode contract"
	)
	var held := _input_frame(0, 0, true, true)
	mode.step_fixture(120, held)
	var deterministic_snapshot := mode.state_snapshot()
	mode.pause_for_test()
	mode.step_fixture(60, held)
	_expect(
		mode.is_paused_state() and mode.state_snapshot() == deterministic_snapshot,
		"paused Boundary Stain presentation continued its simulation"
	)
	mode.handle_semantic_action(GameInput.PAUSE)
	_expect(
		not mode.is_paused_state()
		and int(mode.capture_debug_state().get("resume_countdown_ticks", 0)) == 3,
		"pause resume did not arm the required three-frame countdown"
	)
	mode.retry_phase_for_test()
	mode.step_fixture(120, held)
	_expect(
		mode.state_snapshot() == deterministic_snapshot,
		"presentation-level phase retry did not reproduce the same fixed-step state"
	)
	mode.retry_phase_for_test()
	mode.step_fixture(720, held)
	mode.step_fixture(28, _input_frame(1, 0, true, true))
	var clear_result := mode.step_fixture(332, held)
	_expect(
		clear_result != null
		and clear_result.result_tag == &"clear"
		and clear_result.telemetry != null
		and clear_result.telemetry.attempt_count == 3,
		"real Boundary Stain scene did not return a typed clear with retry telemetry"
	)
	_expect(
		GameStateCodec.new().canonical_state(state) == story_before_mode,
		"mechanical Boundary Stain mode mutated route state before returning"
	)
	mode.handle_semantic_action(GameInput.CONFIRM)
	mode.handle_semantic_action(GameInput.CONFIRM)
	_expect(
		emitted_results.size() == 1 and emitted_results[0] == clear_result,
		"clear result confirmation did not emit exactly once"
	)
	event_yield = interpreter.resume_mode(clear_result)
	_expect(
		event_yield.status == EventInterpreterResult.Status.END
		and event_yield.outcome == &"clear"
		and graph.id in state.completed_event_ids,
		"clear result did not complete its authored event branch"
	)
	mode.free()


func _run_loss_branch(graph: EventGraphRecord) -> void:
	var state := _create_event_state(&"p72")
	var interpreter := EventInterpreter.new()
	var event_yield := interpreter.start(graph, state, _content)
	var mode := MODE_SCENE.instantiate() as BoundaryStainMode
	mode.configure(event_yield.mode_context)
	get_root().add_child(mode)
	await process_frame
	mode.suspend()
	var accepted_loss := mode.accept_loss_for_test()
	_expect(
		accepted_loss != null and accepted_loss.result_tag == &"loss",
		"Accept Loss did not return a valid story result"
	)
	event_yield = interpreter.resume_mode(accepted_loss)
	_expect(
		event_yield.status == EventInterpreterResult.Status.END
		and event_yield.outcome == &"loss"
		and graph.id in state.completed_event_ids,
		"accepted loss did not remain story-completable"
	)
	mode.free()


func _run_assist_branch(graph: EventGraphRecord) -> void:
	var state := _create_event_state(&"p73")
	var interpreter := EventInterpreter.new()
	var event_yield := interpreter.start(graph, state, _content)
	var mode := MODE_SCENE.instantiate() as BoundaryStainMode
	mode.configure(event_yield.mode_context)
	get_root().add_child(mode)
	await process_frame
	mode.suspend()
	mode.host.defeat_count = 3
	var assisted := mode.assist_clear_for_test()
	_expect(
		assisted != null
		and assisted.result_tag == &"assist_clear"
		and assisted.used_assist,
		"three defeats did not unlock an explicit Assist Clear result"
	)
	event_yield = interpreter.resume_mode(assisted)
	_expect(
		event_yield.status == EventInterpreterResult.Status.END
		and event_yield.outcome == &"assist_clear"
		and graph.id in state.completed_event_ids,
		"Assist Clear did not return to its valid story branch"
	)
	mode.free()


func _boundary_event_graph() -> EventGraphRecord:
	var graph := EventGraphRecord.new(
		1,
		&"evt.fixture.boundary_return",
		&"ui.danmaku.boundary.title",
		&"loc.hakurei_shrine",
		&"spot.hkr.veranda",
		[],
		&"n_mode",
		[],
		"res://tests/integration/run_m07_boundary_stain_event_flow.gd"
	)
	var mode_node := EventNodeRecord.new(&"n_mode", &"start_danmaku")
	mode_node.minigame_id = &"danmaku.hkr.boundary_stain"
	mode_node.result_branches = [
		ModeResultBranchRecord.new(&"clear", &"n_clear"),
		ModeResultBranchRecord.new(&"loss", &"n_loss"),
		ModeResultBranchRecord.new(&"assist_clear", &"n_assist"),
	]
	var clear_end := EventNodeRecord.new(&"n_clear", &"end_event")
	clear_end.outcome = &"clear"
	var loss_end := EventNodeRecord.new(&"n_loss", &"end_event")
	loss_end.outcome = &"loss"
	var assist_end := EventNodeRecord.new(&"n_assist", &"end_event")
	assist_end.outcome = &"assist_clear"
	graph.nodes = [mode_node, clear_end, loss_end, assist_end]
	return graph


func _create_event_state(profile_id: StringName) -> GameState:
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters():
		character_ids.append(character.id)
	var location_ids: Array[StringName] = []
	for location: LocationRecord in _content.all_locations():
		location_ids.append(location.id)
	var state := GameStateFactory.create_new(profile_id, character_ids, location_ids, 7070)
	state.chapter_id = &"chapter.1"
	state.time_slot = &"day"
	GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.hakurei_shrine"))
	return state


func _input_frame(
	horizontal: int,
	vertical: int,
	focus: bool,
	shot: bool
) -> DanmakuInputFrame:
	var frame := DanmakuInputFrame.new()
	frame.horizontal_axis = horizontal
	frame.vertical_axis = vertical
	frame.focus_held = focus
	frame.shot_held = shot
	return frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M07 Boundary Stain/event integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
