extends SceneTree
## Proves wrong-way wrap, four ordered audiovisual anchors, and Reisen handoff.

var _failures: Array[String] = []
var _event_signal_count := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed := load("res://src/presentation/exploration/EienteiBambooExplorationMode.tscn") as PackedScene
	var mode := packed.instantiate() as ExplorationMode if packed != null else null
	if mode == null:
		_finish(["Eientei four-dawn exploration scene could not instantiate"])
		return
	mode.event_triggered.connect(func(_event_id: StringName) -> void: _event_signal_count += 1)
	root.add_child(mode)
	await process_frame
	mode.configure_fixture(&"A", &"en")
	await process_frame

	_expect(mode.loop_topology is BambooFourDawnsTopology, "Eientei scene did not create the bamboo topology")
	_cross_seam(mode)
	_expect(mode.objective_step() == 0, "unprimed corridor seam advanced the dawn")
	_expect(mode.player_position().x == 64.0, "wrong seam did not wrap to the readable entry")
	_expect(mode.loop_topology.crossing_count() == 1, "wrong seam was not recorded deterministically")

	for index: int in range(BambooFourDawnsTopology.ANCHOR_SEQUENCE.size()):
		var anchor_id := BambooFourDawnsTopology.ANCHOR_SEQUENCE[index]
		_expect(mode.interact_target_for_test(anchor_id), "sound anchor was not inspectable: %s" % anchor_id)
		_expect(mode.loop_topology.primed_for_exit(), "sound anchor did not prime dawn %d" % (index + 1))
		_cross_seam(mode)
		_expect(mode.objective_step() == index + 1, "seam did not commit dawn %d" % (index + 1))
		if index < BambooFourDawnsTopology.ANCHOR_SEQUENCE.size() - 1:
			_expect(mode.player_position().x == 64.0, "intermediate dawn did not reconnect at the entry")

	_expect(mode.objective_complete(), "four distinct dawns did not complete the corridor objective")
	_expect(mode.triggered_event_id() == &"evt.ein.four_dawns", "final seam did not hand off to Reisen's event")
	_expect(_event_signal_count == 1, "Reisen handoff did not emit exactly once")
	mode.set_player_position_for_test(Vector2(600, 140))
	_expect(_event_signal_count == 1, "one-shot four-dawn event volume fired twice")
	mode.switch_locale(&"ja")
	mode.configure_fixture(&"D", &"ja")
	_expect(mode.resolved_profile_id() == &"D", "Eientei loop lost inverted-profile locale parity")

	var controller_source := FileAccess.get_file_as_string("res://src/presentation/exploration/ExplorationMode.gd")
	_expect(not controller_source.contains("evt.ein.four_dawns"), "generic controller hard-coded Reisen's event ID")
	mode.queue_free()
	await process_frame
	_finish(_failures)


func _cross_seam(mode: ExplorationMode) -> void:
	mode.set_player_position_for_test(Vector2(585, 140))
	mode.step_fixture(1.0, 2)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(failures: Array[String]) -> void:
	print("M13 bamboo loop integration: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(0 if failures.is_empty() else 1)
