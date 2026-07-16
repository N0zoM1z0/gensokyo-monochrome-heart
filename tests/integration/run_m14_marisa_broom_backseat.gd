extends SceneTree
## Proves Marisa's cargo tutorial is deterministic, accessible, and never converts a rough landing into route failure.

var _failures: Array[String] = []


func _initialize() -> void:
	var clear := _run([ -1, 1, 0, -1 ], MinigameAssistSettings.new())
	_expect(clear != null and clear.result_tag == &"clear", "precise cargo landings did not clear")
	_expect(&"broom_backseat.rough_landings.0" in clear.outcome_tags, "precise cargo run recorded rough landings")
	var rough := _run([0, 0, 0, 0], MinigameAssistSettings.new())
	_expect(rough != null and rough.result_tag == &"assist_clear", "rough cargo landings did not continue the route")
	_expect(&"broom_backseat.cargo_delivered" in rough.outcome_tags, "rough cargo run omitted delivery evidence")
	var assisted := MinigameAssistSettings.new()
	assisted.wider_timing_window = true
	var assisted_result := _run([0, 0, 0, 0], assisted)
	_expect(assisted_result != null and assisted_result.result_tag == &"clear" and assisted_result.used_assist, "wider timing did not safely support cargo landings")
	_finish(_failures)


func _run(targets: Array[int], assists: MinigameAssistSettings) -> ModeResult:
	var game := BroomBackseatSimulation.new()
	var context := ModeContext.new()
	context.mode_id = &"mini.mrs.broom_backseat"
	context.event_id = &"evt.mrs.crash_landing"
	context.node_id = &"n_broom_backseat"
	context.deterministic_seed = 1501
	game.configure(context, assists)
	var confirm := MinigameInputFrame.new()
	confirm.confirm_pressed = true
	game.step(confirm)
	for target: int in targets:
		while game.state.cargo_lane != target:
			var move := MinigameInputFrame.new()
			move.grid_direction.x = 1 if target > game.state.cargo_lane else -1
			game.step(move)
		game.step(confirm)
	return game.final_result


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Marisa Broom Backseat integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
