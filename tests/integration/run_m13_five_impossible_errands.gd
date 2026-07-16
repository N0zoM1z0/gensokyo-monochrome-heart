extends SceneTree
## Proves all three philosophies, five modules, bilingual parity, and one-shot handoff.

var _failures: Array[String] = []
var _completion_count: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed := load("res://src/presentation/minigames/FiveImpossibleErrandsMode.tscn") as PackedScene
	var mode := packed.instantiate() as FiveImpossibleErrandsMode if packed != null else null
	if mode == null:
		_finish(["Five Impossible Errands scene could not instantiate"])
		return
	mode.mode_completed.connect(func(_result: ModeResult) -> void: _completion_count += 1)
	root.add_child(mode)
	await process_frame
	mode.configure_fixture(&"C", &"en")
	await process_frame
	var choices: Array[int] = [0, 1, 2, 1, 0]
	for choice: int in choices:
		mode.select_approach_for_test(choice)
	_expect(mode.final_result != null and mode.final_result.result_tag == &"clear", "five valid positions did not clear the framework")
	_expect(mode.final_result.performance_band == &"varied", "result ranked the player instead of recording answer shape")
	_expect(mode.errands.state.choices == [&"literal", &"clever", &"refuse", &"clever", &"literal"], "presentation changed the authored answer sequence")
	mode.handle_semantic_action(GameInput.CONFIRM)
	mode.handle_semantic_action(GameInput.CONFIRM)
	_expect(_completion_count == 1, "Five Impossible Errands emitted its mechanical result more than once")
	mode.switch_locale(&"ja")
	mode.configure_fixture(&"D", &"ja")
	_expect(mode.resolved_profile_id() == &"D", "Five Impossible Errands lost inverted-profile locale parity")
	_expect(mode.errands.errands.size() == 5, "presentation omitted one modular errand")
	mode.queue_free()
	await process_frame
	_finish(_failures)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M13 Five Impossible Errands integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
