extends SceneTree
## Proves the paired-body runtime swaps control, clears without a timer, and can safely stop.

var _failures: Array[String] = []
const BALANCE_SIMULATION := preload("res://src/application/minigames/HalfPhantomBalanceSimulation.gd")


func _initialize() -> void:
	var game = BALANCE_SIMULATION.new()
	game.configure(_context(), MinigameAssistSettings.new())
	game.step(_frame(0, true))
	for _step_index: int in range(4): game.step(_frame(1))
	_expect(game.state.youmu_column == BALANCE_SIMULATION.YOUMU_TARGET, "Youmu did not reach her bridge mark")
	game.step(_frame(0, true))
	_expect(game.selected_label() == &"phantom", "Confirm did not switch control to Youmu's phantom")
	for _step_index: int in range(4): game.step(_frame(-1))
	_expect(game.final_result != null and game.final_result.result_tag == &"clear", "paired bodies did not clear at their opposite marks")
	var withdrawn = BALANCE_SIMULATION.new()
	withdrawn.configure(_context(), MinigameAssistSettings.new())
	withdrawn.step(_frame(0, true))
	withdrawn.accept_loss()
	_expect(withdrawn.final_result != null and withdrawn.final_result.result_tag == &"withdrawn", "voluntary bridge stop did not remain a safe outcome")
	_finish(_failures)


func _context() -> ModeContext:
	var context := ModeContext.new()
	context.mode_type = &"start_minigame"
	context.mode_id = &"mini.hgy.half_phantom_balance"
	context.event_id = &"evt.hgy.two_bodies_one_embarrassment"
	context.node_id = &"n_balance"
	context.deterministic_seed = 1652
	return context


func _frame(direction: int, confirm: bool = false) -> MinigameInputFrame:
	var frame := MinigameInputFrame.new()
	frame.grid_direction.x = direction
	frame.confirm_pressed = confirm
	return frame


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M14 Half-Phantom Balance integration: failures=%d" % failures.size())
	for failure: String in failures: printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
