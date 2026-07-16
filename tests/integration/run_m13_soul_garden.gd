extends SceneTree
## Proves collect, safe mismatch, matched release, bilingual parity, and one-shot handoff.

var _failures: Array[String] = []
var _completion_count: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed := load("res://src/presentation/minigames/SoulGardenMode.tscn") as PackedScene
	var mode := packed.instantiate() as SoulGardenMode if packed != null else null
	if mode == null:
		_finish(["Soul Garden scene could not instantiate"])
		return
	mode.mode_completed.connect(func(_result: ModeResult) -> void: _completion_count += 1)
	root.add_child(mode)
	await process_frame
	mode.configure_fixture(&"A", &"en")
	var assists := MinigameAssistSettings.new()
	assists.slower_pace = true
	mode.configure_assists(assists)
	_expect(mode.garden.assists.slower_pace, "Soul Garden presentation discarded its slower-pace assist")
	mode.handle_semantic_action(GameInput.CONFIRM)
	mode.move_cursor_for_test(mode.garden.state.spirit_columns[0])
	mode.confirm_for_test()
	_expect(mode.garden.state.carried_spirit == 0, "fan spirit was not collected")
	mode.move_cursor_for_test(1)
	mode.confirm_for_test()
	_expect(mode.garden.state.carried_spirit == 0 and mode.garden.state.mismatch_count == 0, "empty space penalized or consumed the carried spirit")
	mode.move_cursor_for_test(SoulGardenSimulation.TREE_COLUMNS[1])
	mode.confirm_for_test()
	_expect(mode.garden.state.carried_spirit == 0 and mode.garden.state.released_count == 0, "mismatch consumed the carried spirit")
	for index: int in range(3):
		if mode.garden.state.carried_spirit < 0:
			mode.move_cursor_for_test(mode.garden.state.spirit_columns[index])
			mode.confirm_for_test()
		mode.move_cursor_for_test(SoulGardenSimulation.TREE_COLUMNS[index])
		mode.confirm_for_test()
	_expect(mode.final_result != null and mode.final_result.result_tag == &"clear", "three memorial matches did not clear Soul Garden")
	_expect(mode.garden.state.released_count == 3, "Soul Garden cleared without releasing all spirits")
	mode.handle_semantic_action(GameInput.CONFIRM)
	mode.handle_semantic_action(GameInput.CONFIRM)
	_expect(_completion_count == 1, "Soul Garden emitted completion more than once")
	mode.switch_locale(&"ja")
	mode.configure_fixture(&"D", &"ja")
	_expect(mode.resolved_profile_id() == &"D", "Soul Garden lost inverted-profile locale parity")
	mode.queue_free()
	await process_frame
	_finish(_failures)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M13 Soul Garden integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
