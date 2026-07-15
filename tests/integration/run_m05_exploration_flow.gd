extends SceneTree
## Walks the real shrine spot through observations, objective order, trigger, and assists.

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed := load("res://src/presentation/exploration/ExplorationMode.tscn") as PackedScene
	if packed == null:
		_finish(["exploration mode scene could not be loaded"])
		return
	var mode := packed.instantiate() as ExplorationMode
	if mode == null:
		_finish(["exploration mode scene did not instantiate its typed controller"])
		return
	get_root().add_child(mode)
	await process_frame
	mode.configure_fixture(&"A", &"en")
	await process_frame

	_expect(mode.action_contract().has("move") and mode.action_contract().has("companion"), "exploration action contract omitted movement or companion skill")
	_expect(not mode.objective_complete() and mode.objective_step() == 0, "exploration objective opened in a completed state")
	_expect(mode.interact_target_for_test(&"prop.empty_cushion"), "magnetic prompt could not inspect the empty cushion")
	mode.set_player_position_for_test(Vector2(260, 140))
	_expect(mode.triggered_event_id() == &"", "event trigger fired before the authored observation sequence")
	_expect(mode.interact_target_for_test(&"prop.unpaired_cup"), "magnetic prompt could not inspect the warm second cup")
	_expect(mode.objective_step() == 1 and not mode.objective_complete(), "warm-cup observation did not become objective step one")
	_expect(mode.interact_target_for_test(&"prop.empty_cushion"), "empty cushion could not be revisited after the cup")
	_expect(mode.objective_complete(), "cup-to-cushion authored sequence did not complete")

	for target_id: StringName in [
		&"prop.donation_box",
		&"prop.old_tree",
		&"prop.veranda_door",
		&"prop.broom",
	]:
		_expect(mode.interact_target_for_test(target_id), "required object was not inspectable: %s" % target_id)
	for target_id: StringName in [
		&"prop.unpaired_cup",
		&"prop.empty_cushion",
		&"prop.donation_box",
		&"prop.old_tree",
		&"prop.veranda_door",
		&"prop.broom",
	]:
		_expect(target_id in mode.observed_ids(), "observation registry omitted required object: %s" % target_id)
	_expect(mode.triggered_event_id() == &"evt.hkr.empty_cushion", "data-owned volume did not request the Empty Cushion event")

	mode.set_player_position_for_test(Vector2(330, 140))
	var opening_x := mode.player_position().x
	mode.step_fixture(1.0, 60)
	_expect(mode.player_position().x > opening_x + 40.0, "fixed-step movement did not traverse into the adjacent room")
	mode.set_companion_skill_enabled(false)
	_expect(not mode.handle_semantic_action(GameInput.COMPANION) and not mode.companion_preview_visible(), "disabled companion skill still activated")
	mode.set_companion_skill_enabled(true)
	_expect(mode.handle_semantic_action(GameInput.COMPANION) and mode.companion_preview_visible(), "remapped Intuitive Float preview did not activate")
	mode.set_story_hint_delay_for_test(0.0)
	await process_frame
	_expect(mode.hint_visible(), "Story navigation hint did not appear after its configured delay")
	mode.switch_locale(&"ja")
	mode.configure_fixture(&"D", &"ja")
	_expect(mode.resolved_profile_id() == &"D", "exploration did not retain the inverted presentation profile")

	var controller_source := FileAccess.get_file_as_string("res://src/presentation/exploration/ExplorationMode.gd")
	_expect(not controller_source.contains("evt.hkr.empty_cushion"), "generic exploration controller hard-coded an event ID")
	var debug := mode.capture_debug_state()
	_expect(int(debug.get("registry_queries", 0)) > 0, "central interaction registry was never queried")

	await create_timer(0.2).timeout
	mode.queue_free()
	await process_frame
	await process_frame
	_finish(_failures)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M05 exploration integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
