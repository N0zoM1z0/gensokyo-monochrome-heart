class_name FighterDuelSimulation
extends RefCounted
## Deterministic 60 Hz compact duel; animation is presentation-only.

signal spell_break(checkpoint: String)

const FP := 256
const TICKS_PER_SECOND := 60
const GRAVITY_FP := 128
const MAX_HITSTUN_TICKS := 24
const COMBO_ESCAPE_HITS := 3
const COMBO_ESCAPE_INVULNERABILITY := 30
const NOTCH_DELAY_PER_TICK := 18
const MINIMUM_CENTER_SEPARATION_FP := 28 * FP

var definition: FighterDuelDefinition
var mode_context: ModeContext
var assists := FighterAssistSettings.new()
var fighter_definitions: Array[FighterDefinition] = []
var states: Array[FighterState] = []
var input_buffers: Array[FighterInputBuffer] = []
var projectiles := FighterProjectilePool.new(64)
var checkpoints := PackedStringArray()
var final_result: ModeResult
var deterministic_seed: int = 1
var encounter_tick: int = 0
var phase_index: int = 0
var hitstop_ticks: int = 0
var camera_impulse: int = 0
var is_paused: bool = false
var attempt_count: int = 1
var _speed_accumulator: int = 0


func configure(
	duel: FighterDuelDefinition,
	context: ModeContext,
	assist_settings: FighterAssistSettings = null,
	player_fighter_id: StringName = &"fighter.reimu",
	opponent_fighter_id: StringName = &"fighter.marisa"
) -> bool:
	if duel == null or context == null or not duel.validation_errors().is_empty():
		return false
	definition = duel
	mode_context = context
	assists = assist_settings.duplicate_settings() if assist_settings != null else FighterAssistSettings.new()
	if not assists.validation_errors().is_empty():
		return false
	var player_definition := definition.fighter(player_fighter_id)
	var opponent_definition := definition.fighter(opponent_fighter_id)
	if player_definition == null or opponent_definition == null:
		return false
	fighter_definitions = [player_definition, opponent_definition]
	deterministic_seed = maxi(1, context.deterministic_seed)
	projectiles = FighterProjectilePool.new(definition.max_projectiles_per_fighter)
	reset_match()
	return true


func reset_match() -> void:
	states = [_new_state(0), _new_state(1)]
	input_buffers = [FighterInputBuffer.new(), FighterInputBuffer.new()]
	projectiles.clear(true)
	checkpoints.clear()
	final_result = null
	encounter_tick = 0
	phase_index = 0
	hitstop_ticks = 0
	camera_impulse = 0
	is_paused = false
	_speed_accumulator = 0


func step(player_input: FighterInputFrame, opponent_input: FighterInputFrame) -> ModeResult:
	if is_paused or final_result != null:
		return final_result
	return _step_internal(player_input, opponent_input)


func frame_step(player_input: FighterInputFrame, opponent_input: FighterInputFrame) -> ModeResult:
	if final_result != null:
		return final_result
	return _step_internal(player_input, opponent_input)


func toggle_pause() -> void:
	is_paused = not is_paused


func retry_match() -> void:
	attempt_count += 1
	reset_match()
	attempt_count = maxi(2, attempt_count)


func accept_loss() -> ModeResult:
	return final_result if final_result != null else _finish(&"loss")


func canonical_snapshot() -> String:
	return "%d|%d|%d|%d|%d||%s||%s||%s||%s" % [
		encounter_tick,
		phase_index,
		hitstop_ticks,
		camera_impulse,
		_speed_accumulator,
		states[0].canonical_snapshot() if states.size() > 0 else "",
		states[1].canonical_snapshot() if states.size() > 1 else "",
		projectiles.canonical_snapshot(),
		";".join(checkpoints),
	]


func current_hitbox(side: int) -> Rect2i:
	if side < 0 or side >= states.size() or not states[side].active_hitbox:
		return Rect2i()
	var move := fighter_definitions[side].move_by_id(states[side].current_move_id)
	return move.hitbox.global_rect(states[side].origin(definition.ground_y), states[side].facing) if move != null else Rect2i()


func current_hurtbox(side: int) -> Rect2i:
	if side < 0 or side >= states.size():
		return Rect2i()
	return fighter_definitions[side].hurtbox.global_rect(
		states[side].origin(definition.ground_y),
		states[side].facing
	)


func force_damage_for_test(target_side: int, damage: int, attacker_side: int) -> void:
	if target_side not in [0, 1] or attacker_side not in [0, 1]:
		return
	states[target_side].vitality = maxi(0, states[target_side].vitality - maxi(0, damage))
	if states[target_side].vitality <= 0:
		_resolve_spell_break(attacker_side)


func _step_internal(player_input: FighterInputFrame, opponent_input: FighterInputFrame) -> ModeResult:
	var inputs: Array[FighterInputFrame] = [
		player_input if player_input != null else FighterInputFrame.new(),
		opponent_input if opponent_input != null else FighterInputFrame.new(),
	]
	for side: int in range(2):
		input_buffers[side].push(inputs[side])
	encounter_tick += 1
	_speed_accumulator += assists.speed_percent
	if _speed_accumulator < 100:
		_update_vitality_notches()
		return final_result
	_speed_accumulator -= 100
	if hitstop_ticks > 0:
		hitstop_ticks -= 1
		camera_impulse = maxi(0, camera_impulse - 1)
		_update_vitality_notches()
		return final_result
	_update_facing()
	for side: int in range(2):
		_tick_fighter(side, inputs[side])
	_resolve_pushboxes()
	_resolve_melee_hit(0, 1)
	if final_result == null:
		_resolve_melee_hit(1, 0)
	if final_result == null:
		projectiles.step(definition.left_bound * FP, definition.right_bound * FP)
		_resolve_projectile_hits()
	if final_result == null:
		_update_passives(inputs)
	_update_vitality_notches()
	camera_impulse = maxi(0, camera_impulse - 1)
	return final_result


func _new_state(side: int) -> FighterState:
	var state := FighterState.new()
	state.fighter_id = fighter_definitions[side].id
	state.side = side
	state.x_fp = (92 if side == 0 else 228) * FP
	state.facing = 1 if side == 0 else -1
	return state


func _update_facing() -> void:
	for side: int in range(2):
		var state := states[side]
		if not assists.auto_face and state.current_move_id != &"":
			continue
		var delta := states[1 - side].x_fp - state.x_fp
		if delta != 0:
			state.facing = 1 if delta > 0 else -1


func _resolve_pushboxes() -> void:
	# Grounded torsos may touch but never cross or collapse into one silhouette.
	# Airborne fighters can still pass over one another.
	if states[0].height_fp > 0 or states[1].height_fp > 0:
		return
	var delta := states[1].x_fp - states[0].x_fp
	if absi(delta) >= MINIMUM_CENTER_SEPARATION_FP:
		return
	var direction := 1 if delta >= 0 else -1
	var midpoint := floori((states[0].x_fp + states[1].x_fp) / 2.0)
	var half_separation := floori(MINIMUM_CENTER_SEPARATION_FP / 2.0)
	var left_bound_fp := definition.left_bound * FP
	var right_bound_fp := definition.right_bound * FP
	var left_x := clampi(midpoint - half_separation, left_bound_fp, right_bound_fp - MINIMUM_CENTER_SEPARATION_FP)
	var right_x := left_x + MINIMUM_CENTER_SEPARATION_FP
	if direction > 0:
		states[0].x_fp = left_x
		states[1].x_fp = right_x
	else:
		states[1].x_fp = left_x
		states[0].x_fp = right_x


func _tick_fighter(side: int, input: FighterInputFrame) -> void:
	var state := states[side]
	var fighter := fighter_definitions[side]
	if state.invulnerability_ticks > 0:
		state.invulnerability_ticks -= 1
	state.guard_held = (
		input.guard_held
		or (assists.hold_to_guard and input.horizontal_axis * state.facing < 0)
	) and state.current_move_id == &"" and state.hitstun_ticks <= 0
	if state.hitstun_ticks > 0 or state.blockstun_ticks > 0:
		state.hitstun_ticks = maxi(0, state.hitstun_ticks - 1)
		state.blockstun_ticks = maxi(0, state.blockstun_ticks - 1)
		state.current_lock_ticks += 1
		state.longest_lock_ticks = maxi(state.longest_lock_ticks, state.current_lock_ticks)
		state.visual_pose = &"guard" if state.guard_held else &"hit"
		_integrate_height(state)
		return
	state.current_lock_ticks = 0
	if state.current_move_id != &"":
		_advance_move(side)
		_integrate_height(state)
		return
	state.visual_pose = &"guard" if state.guard_held else &"idle"
	var action := input_buffers[side].consume_action(state.facing, assists.simple_inputs)
	var move := fighter.move_for_action(action)
	if move != null and state.temperament >= move.temperament_cost:
		_start_move(side, move)
		_integrate_height(state)
		return
	if state.guard_held:
		state.velocity_x_fp = 0
	else:
		state.velocity_x_fp = clampi(input.horizontal_axis, -1, 1) * fighter.walk_speed_fp
		state.x_fp = clampi(
			state.x_fp + state.velocity_x_fp,
			definition.left_bound * FP,
			definition.right_bound * FP
		)
		if input.vertical_axis < 0 and state.is_grounded():
			state.velocity_y_fp = fighter.jump_speed_fp
			state.visual_pose = &"jump"
	_integrate_height(state)


func _integrate_height(state: FighterState) -> void:
	if state.velocity_y_fp != 0 or state.height_fp > 0:
		state.height_fp += state.velocity_y_fp
		state.velocity_y_fp -= GRAVITY_FP
		if state.height_fp <= 0:
			state.height_fp = 0
			state.velocity_y_fp = 0


func _start_move(side: int, move: FighterMoveDefinition) -> void:
	var state := states[side]
	state.current_move_id = move.id
	state.move_tick = 0
	state.active_hitbox = false
	state.move_connected = false
	state.neutral_ticks = 0
	state.neutral_reset_armed = false
	state.temperament = maxi(0, state.temperament - move.temperament_cost)
	state.velocity_x_fp = 0
	state.visual_pose = &"attack"
	_advance_move(side)


func _advance_move(side: int) -> void:
	var state := states[side]
	var move := fighter_definitions[side].move_by_id(state.current_move_id)
	if move == null:
		_end_move(side)
		return
	for event: FighterFrameEvent in move.events_at(state.move_tick):
		match event.type:
			&"hitbox_on":
				state.active_hitbox = true
			&"hitbox_off":
				state.active_hitbox = false
			&"projectile":
				_spawn_projectile(side, move)
			&"root_motion":
				state.x_fp = clampi(
					state.x_fp + event.value * state.facing * FP,
					definition.left_bound * FP,
					definition.right_bound * FP
				)
			&"invulnerable_on":
				state.invulnerability_ticks = maxi(state.invulnerability_ticks, event.value)
			&"invulnerable_off":
				state.invulnerability_ticks = 0
	state.move_tick += 1
	if state.move_tick >= move.duration_ticks():
		_end_move(side)


func _end_move(side: int) -> void:
	var state := states[side]
	state.current_move_id = &""
	state.move_tick = 0
	state.active_hitbox = false
	state.move_connected = false
	state.visual_pose = &"idle"
	state.neutral_reset_armed = fighter_definitions[side].passive == &"neutral_reset"


func _resolve_melee_hit(attacker_side: int, target_side: int) -> void:
	var attacker := states[attacker_side]
	var target := states[target_side]
	if not attacker.active_hitbox or attacker.move_connected or target.invulnerability_ticks > 0:
		return
	var attack_rect := current_hitbox(attacker_side)
	if attack_rect.size == Vector2i.ZERO or not attack_rect.intersects(current_hurtbox(target_side)):
		return
	var move := fighter_definitions[attacker_side].move_by_id(attacker.current_move_id)
	if move == null:
		return
	attacker.move_connected = true
	_apply_hit(attacker_side, target_side, move.damage, move.guard_damage, move.hitstun_ticks, move.blockstun_ticks, &"melee")


func _spawn_projectile(side: int, move: FighterMoveDefinition) -> void:
	if not move.projectile_enabled:
		return
	var state := states[side]
	var spec := FighterProjectileSpec.new()
	spec.owner_side = side
	spec.x_fp = state.x_fp + state.facing * 12 * FP
	spec.y_fp = state.height_fp + 22 * FP
	spec.velocity_x_fp = move.projectile_speed_fp * state.facing
	spec.damage = move.damage + (state.firepower_level * 12 if fighter_definitions[side].passive == &"momentum" else 0)
	spec.guard_damage = move.guard_damage
	spec.hitstun_ticks = move.hitstun_ticks
	spec.blockstun_ticks = move.blockstun_ticks
	spec.lifetime_ticks = move.projectile_lifetime_ticks
	spec.family = move.projectile_family
	projectiles.spawn(spec)


func _resolve_projectile_hits() -> void:
	for index: int in range(projectiles.capacity):
		if projectiles.used[index] == 0:
			continue
		var attacker_side := int(projectiles.owner_side[index])
		var target_side := 1 - attacker_side
		if states[target_side].invulnerability_ticks > 0:
			continue
		var point := Vector2i(
			roundi(projectiles.x_fp[index] / 256.0),
			definition.ground_y - roundi(projectiles.y_fp[index] / 256.0)
		)
		if not current_hurtbox(target_side).grow(2).has_point(point):
			continue
		_apply_hit(
			attacker_side,
			target_side,
			projectiles.damage[index],
			projectiles.guard_damage[index],
			projectiles.hitstun_ticks[index],
			projectiles.blockstun_ticks[index],
			&"projectile"
		)
		projectiles.retire(index)
		if final_result != null:
			return


func _apply_hit(
	attacker_side: int,
	target_side: int,
	damage: int,
	guard_damage: int,
	hitstun: int,
	blockstun: int,
	hit_kind: StringName
) -> void:
	var attacker := states[attacker_side]
	var target := states[target_side]
	if target.guard_held:
		target.vitality = maxi(0, target.vitality - maxi(1, guard_damage))
		target.blockstun_ticks = mini(MAX_HITSTUN_TICKS, maxi(1, blockstun))
		target.temperament = mini(FighterState.MAX_TEMPERAMENT, target.temperament + 28)
		target.last_hit_kind = &"guard"
	else:
		var identity_damage := damage
		if fighter_definitions[attacker_side].passive == &"momentum":
			identity_damage += attacker.firepower_level * 8
		target.vitality = maxi(0, target.vitality - maxi(1, identity_damage))
		target.hitstun_ticks = mini(MAX_HITSTUN_TICKS, maxi(1, hitstun))
		target.combo_hits_received += 1
		target.last_hit_kind = hit_kind
		target.current_move_id = &""
		target.active_hitbox = false
		if target.combo_hits_received >= COMBO_ESCAPE_HITS:
			target.invulnerability_ticks = COMBO_ESCAPE_INVULNERABILITY
			target.combo_hits_received = 0
	attacker.temperament = mini(FighterState.MAX_TEMPERAMENT, attacker.temperament + 36)
	hitstop_ticks = 2
	camera_impulse = 0 if assists.reduced_motion else 3
	if target.vitality <= 0:
		_resolve_spell_break(attacker_side)


func _update_passives(inputs: Array[FighterInputFrame]) -> void:
	for side: int in range(2):
		var state := states[side]
		var fighter := fighter_definitions[side]
		if fighter.passive == &"neutral_reset":
			if state.neutral_reset_armed and state.current_move_id == &"" and state.is_grounded() and inputs[side].horizontal_axis == 0:
				state.neutral_ticks += 1
				if state.neutral_ticks >= 30:
					state.temperament = mini(FighterState.MAX_TEMPERAMENT, state.temperament + 120)
					state.neutral_ticks = 0
					state.neutral_reset_armed = false
			else:
				state.neutral_ticks = 0
		elif fighter.passive == &"momentum":
			var moving_forward := inputs[side].horizontal_axis * state.facing > 0 and state.current_move_id == &""
			if moving_forward:
				state.momentum_ticks = mini(180, state.momentum_ticks + 1)
				state.temperament = mini(FighterState.MAX_TEMPERAMENT, state.temperament + 2)
			else:
				state.momentum_ticks = maxi(0, state.momentum_ticks - 2)
			state.firepower_level = mini(3, floori(state.momentum_ticks / 45.0))
		if state.hitstun_ticks == 0 and state.blockstun_ticks == 0 and state.current_lock_ticks == 0:
			state.combo_hits_received = 0


func _update_vitality_notches() -> void:
	for state: FighterState in states:
		if state.vitality_notch > state.vitality:
			state.vitality_notch = maxi(state.vitality, state.vitality_notch - NOTCH_DELAY_PER_TICK)
		elif state.vitality_notch < state.vitality:
			state.vitality_notch = state.vitality


func _resolve_spell_break(winner_side: int) -> void:
	var winner_breaks := states[winner_side].breaks_won + 1
	states[winner_side].breaks_won = winner_breaks
	var checkpoint := "break.%d|%d|%d|%d" % [
		phase_index + 1,
		encounter_tick,
		states[0].breaks_won,
		states[1].breaks_won,
	]
	checkpoints.append(checkpoint)
	spell_break.emit(checkpoint)
	if winner_breaks >= definition.breaks_to_win:
		_finish(&"win" if winner_side == 0 else &"loss")
		return
	var player_breaks := states[0].breaks_won
	var opponent_breaks := states[1].breaks_won
	phase_index += 1
	states = [_new_state(0), _new_state(1)]
	states[0].breaks_won = player_breaks
	states[1].breaks_won = opponent_breaks
	input_buffers[0].clear()
	input_buffers[1].clear()
	projectiles.clear(false)
	hitstop_ticks = 0
	camera_impulse = 0
	_speed_accumulator = 0


func _finish(tag: StringName) -> ModeResult:
	if final_result != null:
		return final_result
	var result := ModeResult.new(tag)
	result.performance_band = tag
	result.outcome_tags = [&"fighter", &"story_duel", StringName("phase.%d" % (phase_index + 1))]
	result.used_assist = assists.speed_percent < 100 or assists.hold_to_guard or assists.auto_face
	result.telemetry = ModeTelemetry.new()
	result.telemetry.deterministic_seed = deterministic_seed
	result.telemetry.elapsed_ticks = encounter_tick
	result.telemetry.attempt_count = attempt_count
	final_result = result
	result.telemetry.final_state_hash = canonical_snapshot().sha256_text()
	return result
