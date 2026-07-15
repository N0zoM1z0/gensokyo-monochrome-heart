extends SceneTree
## Runs the authored Empty Cushion handoff through the real Tea Temperature mode.

var _failures: Array[String] = []
var _content := ContentRepository.new()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not _content.load_sources().is_success():
		_finish(["content could not be loaded for the Tea Temperature integration"])
		return
	var graph := _content.graph(&"evt.hkr.empty_cushion")
	var packed := load("res://src/presentation/minigames/TeaTemperatureMode.tscn") as PackedScene
	if graph == null or packed == null:
		_finish(["authored event graph or Tea Temperature scene is missing"])
		return

	var state := _create_event_state(&"p61")
	var interpreter := EventInterpreter.new()
	var event_yield := interpreter.start(graph, state, _content)
	event_yield = interpreter.advance_line()
	event_yield = interpreter.choose_tone(&"patient")
	_expect(
		event_yield.status == EventInterpreterResult.Status.WAIT_INPUT
		and event_yield.node_id == &"n_patient_line",
		"Patient event branch did not present its authored response"
	)
	event_yield = interpreter.advance_line()
	_expect(
		event_yield.status == EventInterpreterResult.Status.WAIT_MODE
		and event_yield.node_id == &"n005"
		and event_yield.mode_context != null,
		"Patient event branch did not produce the authored tea handoff"
	)
	if event_yield.mode_context == null:
		_finish(_failures)
		return

	var story_before_mode := GameStateCodec.new().canonical_state(state)
	var mode := packed.instantiate() as TeaTemperatureMode
	var emitted_results: Array[ModeResult] = []
	mode.configure(event_yield.mode_context)
	mode.mode_completed.connect(func(result: ModeResult) -> void: emitted_results.append(result))
	get_root().add_child(mode)
	await process_frame
	_expect(
		mode.action_contract().has("focus") and mode.action_contract().has("pause"),
		"Tea Temperature omitted patience or pause from its semantic action contract"
	)
	_expect(
		mode.capture_debug_state().get("mode_id", "") == "mini.shrine.tea_temperature",
		"Tea Temperature lost the event-owned mode identity"
	)

	mode.start_for_test()
	mode.step_fixture(12, 1, true)
	var paused_snapshot := mode.state_snapshot()
	mode.handle_semantic_action(GameInput.CONFIRM)
	mode.pause_for_test()
	mode.step_fixture(90, 1, true)
	_expect(mode.is_paused_state() and mode.state_snapshot() == paused_snapshot, "paused tea simulation continued to tick")
	mode.pause_for_test()
	mode.retry_for_test()
	_expect(
		mode.tea.state.phase == TeaTemperatureState.Phase.TUTORIAL
		and mode.tea.state.elapsed_ticks == 0
		and mode.host.attempt_count == 2
		and not bool(mode.capture_debug_state().get("pour_queued", true)),
		"presentation retry did not reset the tea runtime and increment the attempt"
	)

	mode.start_for_test()
	mode.step_fixture(110, 1, true)
	mode.step_fixture(70, 0, true)
	mode.pour_for_test()
	mode.step_fixture(TeaTemperatureSimulation.POUR_LOCK_TICKS)
	var excellent := mode.pour_for_test()
	_expect(
		excellent != null
		and excellent.result_tag == &"excellent"
		and excellent.performance_band == &"excellent"
		and excellent.telemetry != null
		and excellent.telemetry.attempt_count == 2,
		"real Tea Temperature mode did not return typed Excellent telemetry"
	)
	_expect(
		GameStateCodec.new().canonical_state(state) == story_before_mode,
		"mechanical tea mode mutated route state before returning its ModeResult"
	)
	mode.handle_semantic_action(GameInput.CONFIRM)
	mode.handle_semantic_action(GameInput.CONFIRM)
	_expect(
		emitted_results.size() == 1 and emitted_results[0] == excellent,
		"result confirmation did not emit the mode result exactly once"
	)
	event_yield = interpreter.resume_mode(excellent)
	_expect(
		event_yield.status == EventInterpreterResult.Status.WAIT_INPUT
		and event_yield.node_id == &"n006a"
		and event_yield.beat != null
		and event_yield.beat.text_key == &"dlg.hkr.empty_cushion.reimu.excellent",
		"Excellent tea result did not resume the authored Excellent response"
	)
	event_yield = interpreter.advance_line()
	_expect(
		event_yield.status == EventInterpreterResult.Status.WAIT_INPUT
		and event_yield.node_id == &"n006d",
		"Excellent response did not continue to the boundary-stain setup"
	)
	event_yield = interpreter.advance_line()
	_expect(
		event_yield.status == EventInterpreterResult.Status.WAIT_MODE
		and event_yield.node_id == &"n007"
		and event_yield.mode_context != null
		and event_yield.mode_context.mode_type == &"start_danmaku"
		and &"evt.hkr.empty_cushion" not in state.completed_event_ids,
		"Excellent tea branch did not hand the unfinished story to Boundary Stain"
	)
	mode.free()

	var loss_state := _create_event_state(&"p62")
	var loss_interpreter := EventInterpreter.new()
	var loss_yield := loss_interpreter.start(graph, loss_state, _content)
	loss_yield = loss_interpreter.advance_line()
	loss_yield = loss_interpreter.choose_tone(&"direct")
	loss_yield = loss_interpreter.advance_line()
	var loss_mode := packed.instantiate() as TeaTemperatureMode
	loss_mode.configure(loss_yield.mode_context)
	get_root().add_child(loss_mode)
	await process_frame
	loss_mode.start_for_test()
	var accepted_loss := loss_mode.accept_loss_for_test()
	_expect(
		accepted_loss != null and accepted_loss.result_tag == &"loss",
		"Accept Loss did not produce a valid typed Loss result"
	)
	loss_yield = loss_interpreter.resume_mode(accepted_loss)
	_expect(
		loss_yield.status == EventInterpreterResult.Status.WAIT_INPUT
		and loss_yield.node_id == &"n006c"
		and loss_yield.beat != null
		and loss_yield.beat.text_key == &"dlg.hkr.empty_cushion.reimu.loss",
		"accepted Loss did not resume Reimu's authored recovery line"
	)
	loss_yield = loss_interpreter.advance_line()
	_expect(
		loss_yield.status == EventInterpreterResult.Status.WAIT_INPUT
		and loss_yield.node_id == &"n006d",
		"Loss recovery branch did not continue to the same story setup"
	)
	loss_yield = loss_interpreter.advance_line()
	_expect(
		loss_yield.status == EventInterpreterResult.Status.WAIT_MODE
		and loss_yield.node_id == &"n007"
		and &"evt.hkr.empty_cushion" not in loss_state.completed_event_ids,
		"Loss recovery branch did not remain story-completable through Boundary Stain"
	)
	loss_mode.free()
	_finish(_failures)


func _create_event_state(profile_id: StringName) -> GameState:
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in _content.all_characters():
		character_ids.append(character.id)
	var location_ids: Array[StringName] = []
	for location: LocationRecord in _content.all_locations():
		location_ids.append(location.id)
	var state := GameStateFactory.create_new(profile_id, character_ids, location_ids, 6060)
	state.chapter_id = &"chapter.1"
	state.time_slot = &"day"
	GameCommandDispatcher.new().dispatch(state, SetLocationCommand.new(&"loc.hakurei_shrine"))
	return state


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M06 tea/event integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
