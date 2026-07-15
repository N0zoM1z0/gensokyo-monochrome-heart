class_name TestFighterFoundation
extends RefCounted
## M08 fighter data, inputs, boxes, identities, AI, reset, and replay contracts.

const DUEL_PATH := "res://content/fighter/reimu_marisa_duel.json"
const SCHEMA_PATH := "res://schemas/fighter_duel.schema.json"
const REPLAY_PATH := "res://tests/fixtures/fighter/reimu_marisa_golden_replay.json"

var _definition: FighterDuelDefinition


func run() -> Array[String]:
	var failures: Array[String] = []
	var loader := FighterDefinitionLoader.new()
	_definition = loader.load_path(DUEL_PATH)
	if _definition == null or not loader.errors.is_empty():
		return ["Reimu/Marisa fighter data could not load: %s" % [loader.errors]]
	_expect_schema_moves_and_boxes(failures)
	_expect_input_buffer_and_simple_parity(failures)
	_expect_projectile_cap(failures)
	_expect_character_passives(failures)
	_expect_pause_frame_step_and_retry(failures)
	_expect_spell_break_reset_and_loss(failures)
	_expect_story_ai_escape_policy(failures)
	if FileAccess.file_exists(REPLAY_PATH):
		_expect_golden_replay(failures)
	return failures


func _expect_schema_moves_and_boxes(failures: Array[String]) -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DUEL_PATH))
	var schema: Variant = JSON.parse_string(FileAccess.get_file_as_string(SCHEMA_PATH))
	var schema_errors := JsonSchemaValidator.new().validate(raw, schema)
	if not schema_errors.is_empty():
		failures.append("fighter JSON failed its schema: %s" % [schema_errors])
	if _definition.fighters.size() != 2 or _definition.data_hash.length() != 64:
		failures.append("fighter definition lost its two loadouts or SHA-256 identity")
	for fighter: FighterDefinition in _definition.fighters:
		if fighter.moves.size() != 5:
			failures.append("fighter %s did not expose the five foundation actions" % fighter.id)
		for move: FighterMoveDefinition in fighter.moves:
			if move.frame_events.is_empty():
				failures.append("move %s has no fixed-step frame events" % move.id)
	var source := FileAccess.get_file_as_string("res://src/application/fighter/FighterDuelSimulation.gd")
	if source.contains("AnimationPlayer") or source.contains("sprite.get_rect"):
		failures.append("fighter rules depend on presentation animation or sprite bounds")
	var simulation := _simulation(FighterAssistSettings.new())
	simulation.states[0].x_fp = 120 * FighterDuelSimulation.FP
	simulation.states[1].x_fp = 140 * FighterDuelSimulation.FP
	var light := FighterInputFrame.new()
	light.light_pressed = true
	simulation.step(light, FighterInputFrame.new())
	for _tick: int in range(4):
		simulation.step(FighterInputFrame.new(), FighterInputFrame.new())
	var move := _definition.fighter(&"fighter.reimu").move_for_action(&"light")
	var expected_box := move.hitbox.global_rect(
		simulation.states[0].origin(_definition.ground_y),
		simulation.states[0].facing
	)
	if not simulation.states[0].active_hitbox or simulation.current_hitbox(0) != expected_box:
		failures.append("active hitbox viewer did not match the data-authored frame/box")


func _expect_input_buffer_and_simple_parity(failures: Array[String]) -> void:
	var simple_buffer := FighterInputBuffer.new()
	var simple := FighterInputFrame.new()
	simple.horizontal_axis = 1
	simple.skill_pressed = true
	simple_buffer.push(simple)
	if simple_buffer.consume_action(1, true) != &"skill_forward":
		failures.append("simple forward+Skill did not resolve the command special")
	var motion_buffer := FighterInputBuffer.new()
	var down := FighterInputFrame.new()
	down.vertical_axis = 1
	var toward := FighterInputFrame.new()
	toward.horizontal_axis = 1
	var skill := toward.duplicate_frame()
	skill.skill_pressed = true
	motion_buffer.push(down)
	motion_buffer.push(toward)
	motion_buffer.push(skill)
	if motion_buffer.consume_action(1, false) != &"skill_forward":
		failures.append("advanced down-toward+Skill did not resolve the same command special")
	var stale_buffer := FighterInputBuffer.new()
	stale_buffer.push(down)
	for _tick: int in range(FighterInputBuffer.CAPACITY):
		stale_buffer.push(FighterInputFrame.new())
	stale_buffer.push(skill)
	if stale_buffer.consume_action(1, false) != &"skill":
		failures.append("fighter motion reader accepted input older than five frames")
	var simple_assists := FighterAssistSettings.new()
	simple_assists.simple_inputs = true
	var advanced_assists := simple_assists.duplicate_settings()
	advanced_assists.simple_inputs = false
	var simple_sim := _simulation(simple_assists)
	var advanced_sim := _simulation(advanced_assists)
	simple_sim.step(simple, FighterInputFrame.new())
	advanced_sim.step(down, FighterInputFrame.new())
	advanced_sim.step(toward, FighterInputFrame.new())
	advanced_sim.step(skill, FighterInputFrame.new())
	var simple_move := _definition.fighter(&"fighter.reimu").move_by_id(simple_sim.states[0].current_move_id)
	var advanced_move := _definition.fighter(&"fighter.reimu").move_by_id(advanced_sim.states[0].current_move_id)
	if simple_move == null or advanced_move == null or simple_move.id != advanced_move.id or simple_move.damage != advanced_move.damage:
		failures.append("simple and motion inputs did not retain exact move/damage parity")


func _expect_projectile_cap(failures: Array[String]) -> void:
	var pool := FighterProjectilePool.new(64)
	for side: int in range(2):
		for _index: int in range(65):
			var spec := FighterProjectileSpec.new()
			spec.owner_side = side
			spec.lifetime_ticks = 60
			pool.spawn(spec)
	if (
		pool.active_count != 128
		or pool.active_for_side(0) != 64
		or pool.active_for_side(1) != 64
		or pool.dropped_spawn_count != 2
	):
		failures.append("64-projectiles-per-fighter pool did not cap and degrade safely")
	var source := FileAccess.get_file_as_string("res://src/application/fighter/FighterProjectilePool.gd")
	if source.contains("extends Node") or source.contains("Node2D"):
		failures.append("fighter projectile pool introduced a Node per projectile")


func _expect_character_passives(failures: Array[String]) -> void:
	var simulation := _simulation(FighterAssistSettings.new())
	var light := FighterInputFrame.new()
	light.light_pressed = true
	simulation.step(light, FighterInputFrame.new())
	for _tick: int in range(50):
		simulation.step(FighterInputFrame.new(), FighterInputFrame.new())
	if simulation.states[0].temperament < 120 or simulation.states[0].neutral_reset_armed:
		failures.append("Reimu neutral reset did not grant Temperament exactly after returning to rest")
	var marisa_forward := FighterInputFrame.new()
	marisa_forward.horizontal_axis = -1
	for _tick: int in range(50):
		simulation.step(FighterInputFrame.new(), marisa_forward)
	if simulation.states[1].temperament <= 0 or simulation.states[1].firepower_level < 1:
		failures.append("Marisa forward Momentum did not build Temperament and firepower")


func _expect_pause_frame_step_and_retry(failures: Array[String]) -> void:
	var simulation := _simulation(FighterAssistSettings.new())
	var right := FighterInputFrame.new()
	right.horizontal_axis = 1
	for _tick: int in range(20):
		simulation.step(right, FighterInputFrame.new())
	var before_pause := simulation.canonical_snapshot()
	simulation.toggle_pause()
	for _tick: int in range(60):
		simulation.step(right, FighterInputFrame.new())
	if simulation.canonical_snapshot() != before_pause:
		failures.append("paused fighter simulation continued to tick")
	simulation.frame_step(right, FighterInputFrame.new())
	if simulation.encounter_tick != 21:
		failures.append("training frame-step did not advance exactly one fixed tick")
	simulation.reset_match()
	for _tick: int in range(20):
		simulation.step(right, FighterInputFrame.new())
	if simulation.canonical_snapshot() != before_pause:
		failures.append("full fighter retry did not reproduce identical input/seed state")


func _expect_spell_break_reset_and_loss(failures: Array[String]) -> void:
	var simulation := _simulation(FighterAssistSettings.new())
	for side: int in range(2):
		for _index: int in range(4):
			var spec := FighterProjectileSpec.new()
			spec.owner_side = side
			spec.lifetime_ticks = 60
			simulation.projectiles.spawn(spec)
	simulation.states[1].firepower_level = 3
	simulation.states[0].current_move_id = &"move.reimu.paper_tap"
	simulation.hitstop_ticks = 8
	simulation.camera_impulse = 7
	simulation.force_damage_for_test(1, FighterState.MAX_VITALITY, 0)
	if (
		simulation.states[0].breaks_won != 1
		or simulation.projectiles.active_count != 0
		or simulation.states[1].firepower_level != 0
		or simulation.states[0].current_move_id != &""
		or simulation.hitstop_ticks != 0
		or simulation.camera_impulse != 0
	):
		failures.append("spell-break reset retained projectiles, buffs, hitstop, move, or camera state")
	simulation.force_damage_for_test(1, FighterState.MAX_VITALITY, 0)
	if simulation.final_result == null or simulation.final_result.result_tag != &"win" or simulation.checkpoints.size() != 2:
		failures.append("two spell breaks did not produce the player Win result")
	var host := FighterHost.new()
	var host_runtime := FighterDuelSimulation.new()
	if not host.load_duel(host_runtime, _definition, _context(8081), FighterAssistSettings.new(), &"gentle"):
		failures.append("FighterHost rejected a valid story duel")
		return
	var emitted := [0]
	host.result_ready.connect(func(_result: ModeResult) -> void: emitted[0] += 1)
	var loss := host.accept_loss()
	host.accept_loss()
	if loss == null or loss.result_tag != &"loss" or emitted[0] != 1:
		failures.append("accepting fighter loss did not return one valid typed story result")


func _expect_story_ai_escape_policy(failures: Array[String]) -> void:
	var host := FighterHost.new()
	var runtime := FighterDuelSimulation.new()
	if not host.load_duel(runtime, _definition, _context(8082), FighterAssistSettings.new(), &"assertive"):
		failures.append("assertive story AI configuration failed")
		return
	var longest_lock := 0
	for _tick: int in range(1800):
		host.step(FighterInputFrame.new())
		longest_lock = maxi(longest_lock, runtime.states[0].longest_lock_ticks)
		if runtime.final_result != null:
			break
	if longest_lock > FighterDuelSimulation.MAX_HITSTUN_TICKS:
		failures.append("story AI exceeded the authored combo escape/lock window: %d" % longest_lock)


func _expect_golden_replay(failures: Array[String]) -> void:
	var tape := FighterReplayTape.load_path(REPLAY_PATH)
	var playback := FighterReplayPlayer.new().play(tape, _definition)
	if not playback.is_valid:
		failures.append("golden Reimu/Marisa duel replay mismatch: %s" % playback.diagnostic)
	elif playback.result == null or playback.result.result_tag != &"win" or playback.checkpoints.size() != 2:
		failures.append("golden fighter replay did not win through two spell breaks")


func _simulation(settings: FighterAssistSettings) -> FighterDuelSimulation:
	var simulation := FighterDuelSimulation.new()
	simulation.configure(_definition, _context(8080), settings)
	return simulation


func _context(seed: int) -> ModeContext:
	var context := ModeContext.new()
	context.mode_type = &"start_duel"
	context.mode_id = &"duel.hkr.spell_card_terms"
	context.event_id = &"evt.hkr.spell_card_terms"
	context.node_id = &"n_duel"
	context.deterministic_seed = seed
	return context
