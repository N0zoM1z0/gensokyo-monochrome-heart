class_name TestExplorationFoundation
extends RefCounted
## M05 typed interactions, objective order, fixed locomotion, triggers, hints, and input parity.


func run() -> Array[String]:
	var failures: Array[String] = []
	_expect_registry_and_magnetism(failures)
	_expect_objective_and_trigger(failures)
	_expect_fixed_motor(failures)
	_expect_companion_hint_and_feedback(failures)
	_expect_input_parity(failures)
	_expect_mansion_service_spot(failures)
	_expect_youkai_mountain_spot(failures)
	_expect_bamboo_four_dawns_topology(failures)
	return failures


func _expect_bamboo_four_dawns_topology(failures: Array[String]) -> void:
	var spot := ExplorationSpotRegistry.build(&"bamboo_four_dawns")
	if (
		spot.location_id != &"loc.eientei"
		or spot.environment_style != &"bamboo_loop"
		or spot.topology_component != &"bamboo_four_dawns"
		or spot.required_sequence != BambooFourDawnsTopology.ANCHOR_SEQUENCE
	):
		failures.append("Eientei registry lost its typed four-dawn topology contract")
	if spot.interactables.size() != 4 or spot.event_triggers.size() != 1:
		failures.append("Eientei corridor omitted a sound anchor or Reisen handoff")
	var topology := ExplorationLoopTopologyRegistry.create(spot.topology_component)
	if not topology is BambooFourDawnsTopology:
		failures.append("four-dawn component did not resolve through the topology registry")
		return
	if topology.observe_anchor(&"prop.ein.rabbit_knock") or topology.cross_exit().advanced:
		failures.append("an out-of-order sound escaped the first dawn")
	for index: int in range(BambooFourDawnsTopology.ANCHOR_SEQUENCE.size()):
		var anchor_id := BambooFourDawnsTopology.ANCHOR_SEQUENCE[index]
		if not topology.observe_anchor(anchor_id) or not topology.primed_for_exit():
			failures.append("dawn %d did not accept its authored audiovisual anchor" % (index + 1))
			break
		var transition := topology.cross_exit()
		if not transition.advanced or transition.iteration_after != index + 1:
			failures.append("dawn %d did not advance across the corridor seam" % (index + 1))
			break
		if transition.completed != (index == BambooFourDawnsTopology.ANCHOR_SEQUENCE.size() - 1):
			failures.append("four-dawn topology completed at the wrong seam")
	if topology.current_iteration() != 4 or topology.crossing_count() != 5:
		failures.append("four-dawn topology lost its successful or failed crossing history")


func _expect_youkai_mountain_spot(failures: Array[String]) -> void:
	var spot := ExplorationSpotRegistry.build(&"mountain_trail")
	if (
		spot.environment_style != &"mountain_trail"
		or spot.location_id != &"loc.youkai_mountain"
		or spot.required_sequence != [&"prop.mtn.tomorrow_paper", &"prop.mtn.intact_guardrail"]
	):
		failures.append("mountain trail registry lost its typed location or evidence sequence")
	if spot.interactables.size() != 6 or spot.event_triggers.size() != 1:
		failures.append("mountain trail omitted authored evidence or Aya's event volume")
	else:
		var trigger := spot.event_triggers[0]
		if (
			trigger.event_id != &"evt.mtn.tomorrows_headline"
			or trigger.required_objective_id != spot.objective_id
		):
			failures.append("mountain trail did not gate Aya's headline handoff on both clues")
	var tracker := ExplorationObjectiveTracker.new()
	tracker.configure(spot.objective_id, spot.required_sequence)
	tracker.observe(&"prop.mtn.tomorrow_paper")
	tracker.observe(&"prop.mtn.intact_guardrail")
	var triggers := ExplorationTriggerRegistry.new()
	triggers.register(spot.event_triggers[0])
	if triggers.resolve(Vector2(552, 130), &"") != null:
		failures.append("Aya headline handoff fired before the evidence objective completed")
	var resolved := triggers.resolve(Vector2(552, 130), tracker.objective_id)
	if resolved == null or resolved.event_id != &"evt.mtn.tomorrows_headline":
		failures.append("completed mountain evidence did not resolve Aya's event handoff")
	var motor := ExplorationMotor.new()
	motor.world_bounds = spot.world_bounds
	motor.floor_y = spot.floor_y
	motor.solid_obstacles = spot.solid_obstacles.duplicate()
	var state := ExplorationMotorState.new()
	state.position = spot.start_position
	var move_right := ExplorationMotorInput.new()
	move_right.horizontal_axis = 1.0
	for _frame: int in range(600):
		motor.step(state, move_right)
	if state.position.x < 540.0:
		failures.append("mountain evidence route requires an undisclosed hop to reach Aya")


func _expect_mansion_service_spot(failures: Array[String]) -> void:
	var spot := MansionServiceSpotFactory.build()
	if spot.environment_style != &"mansion_service" or spot.required_sequence != [&"prop.sdm.offset_clock", &"prop.sdm.reset_tray"]:
		failures.append("mansion service spot lost its typed environment or objective sequence")
	if spot.interactables.size() != 6 or spot.event_triggers.size() != 1:
		failures.append("mansion service spot omitted authored foyer/kitchen interactions")
	else:
		var trigger := spot.event_triggers[0]
		if trigger.event_id != &"evt.sdm.late_by_three_minutes" or trigger.required_objective_id != spot.objective_id:
			failures.append("mansion service trigger lost its objective-gated event handoff")
	var motor := ExplorationMotor.new()
	motor.world_bounds = spot.world_bounds
	motor.floor_y = spot.floor_y
	motor.solid_obstacles = spot.solid_obstacles.duplicate()
	var state := ExplorationMotorState.new()
	state.position = spot.start_position
	var move_right := ExplorationMotorInput.new()
	move_right.horizontal_axis = 1.0
	for _frame: int in range(600):
		motor.step(state, move_right)
	if state.position.x < 540.0:
		failures.append("mansion service route requires an undisclosed hop to reach Sakuya")


func _expect_registry_and_magnetism(failures: Array[String]) -> void:
	var registry := ExplorationInteractionRegistry.new()
	var required_ids: Array[StringName] = [
		&"prop.unpaired_cup",
		&"prop.empty_cushion",
		&"prop.donation_box",
		&"prop.old_tree",
		&"prop.veranda_door",
		&"prop.broom",
	]
	for index: int in range(required_ids.size()):
		var action := ExplorationAction.new(
			StringName("explore.observe.%s" % String(required_ids[index]).trim_prefix("prop.")),
			&"observe",
			required_ids[index],
			&"ui.exploration.observe",
			StringName("observe.%s" % String(required_ids[index]).trim_prefix("prop."))
		)
		if not action.validation_errors().is_empty():
			failures.append("valid exploration action was rejected")
		registry.register(ExplorationInteractable.new(required_ids[index], Vector2(index * 80 + 40, 140), action, 20.0))
	if registry.all().size() != 6 or registry.query_count != 0:
		failures.append("interaction registry did not remain passive after six registrations")
	var magnetized := registry.nearest(Vector2(17, 140), Vector2.RIGHT)
	if magnetized == null or magnetized.interactable_id != &"prop.unpaired_cup":
		failures.append("four-pixel interaction magnetism did not acquire the nearby cup")
	if registry.nearest(Vector2(17, 140), Vector2.LEFT) != null:
		failures.append("eight-direction probe acquired an object behind the player")
	for interactable: ExplorationInteractable in registry.all():
		if interactable.has_method("_process") or interactable.has_method("_physics_process"):
			failures.append("an interactable owns a per-frame player-distance poll")


func _expect_objective_and_trigger(failures: Array[String]) -> void:
	var tracker := ExplorationObjectiveTracker.new()
	tracker.configure(&"obj.hkr.find_second_cup", [&"prop.unpaired_cup", &"prop.empty_cushion"])
	if tracker.observe(&"prop.empty_cushion").accepted_step or tracker.current_step != 0:
		failures.append("objective advanced from the authored sequence in reverse order")
	if not tracker.observe(&"prop.unpaired_cup").accepted_step or tracker.current_step != 1:
		failures.append("objective did not accept its first authored observation")
	if tracker.observe(&"prop.donation_box").accepted_step:
		failures.append("unrelated exploration note advanced the event objective")
	var completed := tracker.observe(&"prop.empty_cushion")
	if not completed.completed_now or not tracker.is_complete():
		failures.append("authored cup-to-cushion sequence did not complete the objective")
	var triggers := ExplorationTriggerRegistry.new()
	triggers.register(ExplorationEventTrigger.new(
		&"trigger.empty_cushion",
		&"evt.hkr.empty_cushion",
		Rect2(248, 100, 40, 40),
		&"obj.hkr.find_second_cup"
	))
	if triggers.resolve(Vector2(260, 120), &"") != null:
		failures.append("event trigger ignored its authored objective requirement")
	var triggered := triggers.resolve(Vector2(260, 120), tracker.objective_id)
	if triggered == null or triggered.event_id != &"evt.hkr.empty_cushion":
		failures.append("data-owned event trigger did not resolve after objective completion")
	if triggers.resolve(Vector2(260, 120), tracker.objective_id) != null:
		failures.append("one-shot event trigger fired more than once")


func _expect_fixed_motor(failures: Array[String]) -> void:
	var motor := ExplorationMotor.new()
	motor.solid_obstacles.append(Rect2(70, 120, 20, 20))
	var state := ExplorationMotorState.new()
	state.position = Vector2(40, 140)
	var input := ExplorationMotorInput.new()
	input.horizontal_axis = 1.0
	for _frame: int in range(180):
		motor.step(state, input)
	if not is_equal_approx(state.position.x, 64.0) or not state.is_grounded or not is_equal_approx(state.position.y, 140.0):
		failures.append("60 Hz motor did not settle against the donation-box collision")
	var settled := state.position
	for _frame: int in range(120):
		motor.step(state, input)
	if state.position != settled:
		failures.append("ground/prop collision drifted after repeated fixed steps")
	var free_motor := ExplorationMotor.new()
	var hopping := ExplorationMotorState.new()
	var hop := ExplorationMotorInput.new()
	hop.hop_pressed = true
	free_motor.step(hopping, hop)
	hop.hop_pressed = false
	var rose_above_floor := hopping.position.y < 140.0
	for _frame: int in range(120):
		free_motor.step(hopping, hop)
	if not rose_above_floor or not hopping.is_grounded or not is_equal_approx(hopping.position.y, 140.0):
		failures.append("short hop did not deterministically return to the floor")
	if not motor.consume_footstep(state) or motor.consume_footstep(state):
		failures.append("distance-based wood footstep cadence was not deterministic")


func _expect_companion_hint_and_feedback(failures: Array[String]) -> void:
	var context := ExplorationModeContext.new()
	context.location_id = &"loc.hakurei_shrine"
	context.spot_id = &"loc.hakurei_shrine.veranda"
	context.companion_id = &"char.reimu_hakurei"
	if context.mode_type != &"exploration" or context.companion_id == &"":
		failures.append("exploration mode context omitted its typed mode/companion contract")
	var preview := IntuitiveFloatPreview.new()
	preview.rebuild(Vector2(50, 120), Vector2.RIGHT)
	if preview.points.size() != 6 or preview.points[2].y >= 120:
		failures.append("Intuitive Float did not produce a readable traversal arc")
	preview.is_enabled = false
	preview.rebuild(Vector2(50, 120), Vector2.RIGHT)
	if not preview.points.is_empty():
		failures.append("disabled companion skill still produced traversal guidance")
	var hint := ExplorationHintTimer.new()
	hint.story_hints_enabled = true
	hint.delay_seconds = 2.0
	if hint.tick(1.0) or not hint.tick(1.0) or hint.tick(10.0):
		failures.append("Story navigation hint did not fire once after its configured delay")
	hint.reset_after_progress()
	if not hint.tick(2.0):
		failures.append("Story navigation hint did not reset after meaningful progress")
	var wood := ExplorationSfxCue.new(&"sfx.step.wood", &"ui.sfx.wood_step", 140.0)
	var cup := ExplorationSfxCue.new(&"sfx.prop.cup", &"ui.sfx.cup", 420.0)
	var door := ExplorationSfxCue.new(&"sfx.door.wood", &"ui.sfx.door", 210.0)
	if wood.pitch_hz == cup.pitch_hz or cup.pitch_hz == door.pitch_hz or wood.visual_key == cup.visual_key:
		failures.append("exploration SFX intents lack distinct audio/visual equivalents")


func _expect_input_parity(failures: Array[String]) -> void:
	InputMapInstaller.install_defaults(true)
	if not _has_event_type(GameInput.CONFIRM, InputEventKey) or not _has_event_type(GameInput.CONFIRM, InputEventJoypadButton):
		failures.append("Confirm lacks keyboard/controller parity")
	if not _has_event_type(GameInput.COMPANION, InputEventKey) or not _has_event_type(GameInput.COMPANION, InputEventJoypadButton):
		failures.append("remappable companion skill lacks keyboard/controller parity")
	InputMapInstaller.apply_one_handed_preset(InputMapInstaller.OneHandedPreset.LEFT_HAND)
	var left_bindings: Dictionary[StringName, int] = {
		GameInput.CONFIRM: KEY_SPACE, GameInput.SHOT: KEY_SPACE, GameInput.LIGHT: KEY_SPACE,
		GameInput.CANCEL: KEY_QUOTELEFT, GameInput.FOCUS: KEY_Q, GameInput.HEAVY: KEY_Q,
		GameInput.COMPANION: KEY_E, GameInput.SKILL: KEY_E, GameInput.BOMB: KEY_R,
		GameInput.SPELL: KEY_R, GameInput.GUARD: KEY_SHIFT, GameInput.JOURNAL: KEY_TAB,
		GameInput.MAP: KEY_F, GameInput.PAGE_LEFT: KEY_1, GameInput.PAGE_RIGHT: KEY_2,
		GameInput.PAUSE: KEY_ESCAPE,
	}
	for action: StringName in left_bindings:
		if not _has_key(action, left_bindings[action]):
			failures.append("left-handed preset omitted %s" % action)
	InputMapInstaller.apply_one_handed_preset(InputMapInstaller.OneHandedPreset.RIGHT_HAND)
	var right_bindings: Dictionary[StringName, int] = {
		GameInput.CONFIRM: KEY_KP_0, GameInput.SHOT: KEY_KP_0, GameInput.LIGHT: KEY_KP_0,
		GameInput.CANCEL: KEY_KP_PERIOD, GameInput.FOCUS: KEY_KP_1, GameInput.HEAVY: KEY_KP_1,
		GameInput.COMPANION: KEY_KP_2, GameInput.SKILL: KEY_KP_2, GameInput.BOMB: KEY_KP_3,
		GameInput.SPELL: KEY_KP_3, GameInput.GUARD: KEY_KP_ADD, GameInput.JOURNAL: KEY_KP_7,
		GameInput.MAP: KEY_KP_9, GameInput.PAGE_LEFT: KEY_KP_4, GameInput.PAGE_RIGHT: KEY_KP_6,
		GameInput.PAUSE: KEY_KP_SUBTRACT,
	}
	for action: StringName in right_bindings:
		if not _has_key(action, right_bindings[action]):
			failures.append("right-handed preset omitted %s" % action)
	var tree := Engine.get_main_loop() as SceneTree
	var accessibility := tree.root.get_node_or_null("AccessibilityState") if tree != null else null
	if accessibility != null:
		accessibility.set_one_handed_preset(InputMapInstaller.OneHandedPreset.LEFT_HAND, false)
		if accessibility.one_handed_preset != InputMapInstaller.OneHandedPreset.LEFT_HAND or not _has_key(GameInput.SPELL, KEY_R):
			failures.append("AccessibilityState did not apply the selected one-handed preset")
		accessibility.set_one_handed_preset(InputMapInstaller.OneHandedPreset.NONE, false)
	InputMapInstaller.install_defaults(true)


func _has_event_type(action: StringName, expected_type: Variant) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if is_instance_of(event, expected_type):
			return true
	return false


func _has_key(action: StringName, keycode: int) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == keycode:
			return true
	return false
