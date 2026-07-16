extends SceneTree
## Walks the real mountain spot through evidence order and Aya's gated handoff.

var _failures: Array[String] = []
var _event_signal_count := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed := load(
		"res://src/presentation/exploration/YoukaiMountainExplorationMode.tscn"
	) as PackedScene
	if packed == null:
		_finish(["Youkai Mountain exploration scene could not be loaded"])
		return
	var mode := packed.instantiate() as ExplorationMode
	if mode == null:
		_finish(["Youkai Mountain scene did not instantiate the generic controller"])
		return
	mode.event_triggered.connect(func(_event_id: StringName) -> void: _event_signal_count += 1)
	get_root().add_child(mode)
	await process_frame
	mode.configure_fixture(&"A", &"en")
	await process_frame

	_expect(not mode.objective_complete() and mode.objective_step() == 0, "mountain evidence opened complete")
	_expect(not mode.handle_semantic_action(GameInput.COMPANION), "unmet Aya should not grant a generic traversal key")
	_expect(mode.interact_target_for_test(&"prop.mtn.intact_guardrail"), "intact guardrail was not inspectable")
	_expect(mode.objective_step() == 0, "guardrail advanced before the future newspaper was read")
	mode.set_player_position_for_test(Vector2(552, 130))
	_expect(mode.triggered_event_id() == &"", "Aya event fired before both evidence observations")
	_expect(mode.interact_target_for_test(&"prop.mtn.tomorrow_paper"), "future newspaper was not inspectable")
	_expect(mode.objective_step() == 1, "future newspaper did not become evidence step one")
	_expect(mode.interact_target_for_test(&"prop.mtn.intact_guardrail"), "guardrail could not be revisited")
	_expect(mode.objective_complete(), "newspaper-to-guardrail evidence sequence did not complete")
	for target_id: StringName in [
		&"prop.mtn.rope_bridge",
		&"prop.mtn.patrol_notice",
		&"prop.mtn.camera_perch",
	]:
		_expect(mode.interact_target_for_test(target_id), "optional mountain clue was not inspectable: %s" % target_id)
	_expect(mode.interact_target_for_test(&"char.aya_shameimaru"), "Aya talk prompt was not reachable")
	_expect(mode.triggered_event_id() == &"evt.mtn.tomorrows_headline", "completed evidence did not hand off to Tomorrow's Headline")
	_expect(_event_signal_count == 1, "Aya event handoff did not emit exactly once")
	mode.set_player_position_for_test(Vector2(552, 130))
	_expect(_event_signal_count == 1, "one-shot Aya event volume fired again")
	mode.switch_locale(&"ja")
	mode.configure_fixture(&"D", &"ja")
	_expect(mode.resolved_profile_id() == &"D", "mountain spot lost inverted-profile locale parity")

	var controller_source := FileAccess.get_file_as_string(
		"res://src/presentation/exploration/ExplorationMode.gd"
	)
	_expect(
		not controller_source.contains("evt.mtn.tomorrows_headline"),
		"generic exploration controller hard-coded Aya's event ID"
	)

	mode.queue_free()
	await process_frame
	await process_frame
	_finish(_failures)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M13 mountain exploration integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
