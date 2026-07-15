class_name BoundaryStainSimulation
extends RefCounted
## Fixed-step pooled three-phase story encounter with deterministic result output.

signal phase_checkpoint(checkpoint: String)

const FP := 256
const TICKS_PER_SECOND := 60
const STORY_MIN_TELEGRAPH_TICKS := 24
const PLAYER_NORMAL_SPEED_FP := 384
const PLAYER_FOCUS_SPEED_FP := 192
const PLAYER_NORMAL_HIT_RADIUS_FP := 2 * FP
const PLAYER_FOCUS_HIT_RADIUS_FP := FP
const GRAZE_RADIUS_FP := 7 * FP
const LARGE_GRAZE_BONUS_FP := 4 * FP
const MAX_MARGIN := 1000
const MARGIN_ACTION_COST := 250
const PLAYER_MIN_X_FP := 4 * FP
const PLAYER_MIN_Y_FP := 22 * FP
const PLAYER_EDGE_PADDING_FP := 4 * FP

var definition: DanmakuPatternDefinition
var mode_context: ModeContext
var assists := DanmakuAssistSettings.new()
var pool := DanmakuBulletPool.new()
var state := DanmakuState.new()
var final_result: ModeResult
var deterministic_seed: int = 1
var is_paused: bool = false
var checkpoints := PackedStringArray()
var emitter_spawn_counts: Dictionary[StringName, int] = {}

var _emitter_indices: Dictionary[StringName, int] = {}
var _phase_open_state := DanmakuState.new()
var _phase_open_spawn_counts: Dictionary[StringName, int] = {}


func configure(
	pattern: DanmakuPatternDefinition,
	context: ModeContext,
	assist_settings: DanmakuAssistSettings = null,
	pool_capacity: int = 512
) -> bool:
	if pattern == null or context == null or not pattern.validation_errors().is_empty():
		return false
	definition = pattern
	mode_context = context
	assists = assist_settings.duplicate_settings() if assist_settings != null else DanmakuAssistSettings.new()
	if not assists.validation_errors().is_empty():
		return false
	deterministic_seed = maxi(1, context.deterministic_seed)
	pool = DanmakuBulletPool.new(pool_capacity)
	_index_emitters()
	reset_encounter()
	return true


func reset_encounter() -> void:
	state = DanmakuState.new()
	state.automatic_saves_remaining = 2 if assists.story_mode else 0
	final_result = null
	is_paused = false
	checkpoints.clear()
	emitter_spawn_counts.clear()
	pool.clear(true)
	_enter_phase(0)


func step(input: DanmakuInputFrame) -> ModeResult:
	if input == null or is_paused or final_result != null:
		return final_result
	state.focus_held = input.focus_held
	_move_player(input)
	if input.bomb_pressed:
		_trigger_bomb(false)
	if input.margin_pressed:
		_spend_margin_corridor()
	_emit_due_patterns()
	pool.step(definition.arena_width * FP, definition.arena_height * FP)
	_consume_collisions_and_graze()
	_apply_player_shot(input.shot_held)
	_tick_margin_decay()
	if state.invulnerability_ticks > 0:
		state.invulnerability_ticks -= 1
	state.phase_tick += 1
	state.encounter_tick += 1
	var phase := definition.phase(state.phase_index)
	if final_result == null and (state.boss_integrity <= 0 or state.phase_tick >= phase.duration_ticks):
		_complete_phase()
	return final_result


func toggle_pause() -> void:
	is_paused = not is_paused


func retry_phase() -> void:
	if definition == null:
		return
	final_result = null
	is_paused = false
	state = _phase_open_state.duplicate_state()
	emitter_spawn_counts = _phase_open_spawn_counts.duplicate()
	pool.clear(false)


func accept_loss() -> ModeResult:
	return final_result if final_result != null else _finish(&"loss")


func assist_clear() -> ModeResult:
	return final_result if final_result != null else _finish(&"assist_clear")


func canonical_snapshot() -> String:
	return "%s||%s||%s" % [
		state.canonical_snapshot(),
		pool.canonical_snapshot(),
		";".join(checkpoints),
	]


func current_phase() -> DanmakuPhaseDefinition:
	return definition.phase(state.phase_index) if definition != null else null


func player_hit_radius_fp() -> int:
	return PLAYER_FOCUS_HIT_RADIUS_FP if state.focus_held else PLAYER_NORMAL_HIT_RADIUS_FP


func graze_radius_fp() -> int:
	return GRAZE_RADIUS_FP + (LARGE_GRAZE_BONUS_FP if assists.larger_graze_radius else 0)


func safe_lane_preview() -> int:
	if not assists.safe_lane_preview or current_phase() == null:
		return -1
	return current_phase().safe_lane


func _move_player(input: DanmakuInputFrame) -> void:
	var horizontal := clampi(input.horizontal_axis, -1, 1)
	var vertical := clampi(input.vertical_axis, -1, 1)
	var speed := PLAYER_FOCUS_SPEED_FP if input.focus_held else PLAYER_NORMAL_SPEED_FP
	if horizontal != 0 and vertical != 0:
		speed = roundi(speed * 0.70710678)
	state.player_x_fp = clampi(
		state.player_x_fp + horizontal * speed,
		PLAYER_MIN_X_FP,
		definition.arena_width * FP - PLAYER_EDGE_PADDING_FP
	)
	state.player_y_fp = clampi(
		state.player_y_fp + vertical * speed,
		PLAYER_MIN_Y_FP,
		definition.arena_height * FP - PLAYER_EDGE_PADDING_FP
	)


func _emit_due_patterns() -> void:
	var phase := current_phase()
	for emitter: DanmakuEmitterDefinition in phase.emitters:
		var delta := state.phase_tick - emitter.start_tick
		if delta < 0 or delta % emitter.interval_ticks != 0:
			continue
		var volley := floori(delta / float(emitter.interval_ticks))
		if volley < 0 or volley >= emitter.volleys:
			continue
		_emit_volley(emitter, volley)


func _emit_volley(emitter: DanmakuEmitterDefinition, volley: int) -> void:
	var slots := emitter.selected_slots(assists.density_percent)
	var spawned := 0
	for slot: int in slots:
		if emitter.pattern_type == &"safe_lane_grid" and slot == emitter.safe_lane:
			continue
		var spec := _make_bullet_spec(emitter, volley, slot)
		if pool.spawn(spec) >= 0:
			spawned += 1
	emitter_spawn_counts[emitter.id] = emitter_spawn_counts.get(emitter.id, 0) + spawned


func _make_bullet_spec(
	emitter: DanmakuEmitterDefinition,
	volley: int,
	slot: int
) -> DanmakuBulletSpec:
	var spec := DanmakuBulletSpec.new()
	var speed := maxi(1, roundi(emitter.speed_fp * assists.bullet_speed_percent / 100.0))
	var slot_ratio := 0.5 if emitter.slot_count <= 1 else slot / float(emitter.slot_count - 1)
	match emitter.pattern_type:
		&"offering_ring":
			var side := -1 if volley % 2 == 0 else 1
			var seed_nudge := posmod(deterministic_seed + volley * 17, 5) - 2
			spec.x_fp = (emitter.origin_x + side * 38 + seed_nudge) * FP
			spec.y_fp = emitter.origin_y * FP
			var angle := deg_to_rad(emitter.angle_millidegrees / 1000.0) + slot * TAU / emitter.slot_count
			spec.velocity_x_fp = roundi(cos(angle) * speed)
			spec.velocity_y_fp = roundi(sin(angle) * speed)
		_:
			spec.x_fp = roundi((8.0 + slot_ratio * (definition.arena_width - 16)) * FP)
			spec.y_fp = emitter.origin_y * FP
			spec.velocity_x_fp = 0
			if emitter.pattern_type == &"lane_fan":
				spec.velocity_x_fp = (posmod(slot + volley + deterministic_seed, 3) - 1) * 28
			spec.velocity_y_fp = speed
	spec.radius_fp = (2 * FP) if emitter.family == DanmakuBulletSpec.Family.OFFERING else FP
	spec.telegraph_ticks = maxi(
		emitter.telegraph_ticks,
		STORY_MIN_TELEGRAPH_TICKS if assists.story_mode else 1
	)
	spec.lifetime_ticks = emitter.lifetime_ticks
	spec.family = emitter.family
	spec.polarity = (
		DanmakuBulletSpec.Polarity.PAPER
		if posmod(slot + volley, 2) == 0
		else emitter.polarity
	)
	spec.emitter_index = _emitter_indices.get(emitter.id, -1)
	spec.phase_index = state.phase_index
	return spec


func _consume_collisions_and_graze() -> void:
	var hit_radius := player_hit_radius_fp()
	var graze_radius := graze_radius_fp()
	for index: int in range(pool.capacity):
		if pool.used[index] == 0 or pool.lifecycle[index] != DanmakuBulletPool.Lifecycle.COMMITTED:
			continue
		var delta_x := pool.x_fp[index] - state.player_x_fp
		var delta_y := pool.y_fp[index] - state.player_y_fp
		var distance_squared := delta_x * delta_x + delta_y * delta_y
		var damage_radius := pool.radius_fp[index] + hit_radius
		if state.invulnerability_ticks <= 0 and distance_squared <= damage_radius * damage_radius:
			_resolve_player_hit()
			return
		var graze_limit := pool.radius_fp[index] + graze_radius
		if pool.grazed[index] == 0 and distance_squared <= graze_limit * graze_limit:
			pool.grazed[index] = 1
			state.graze_count += 1
			state.margin = mini(MAX_MARGIN, state.margin + 12)
			state.score += 50
			state.inactive_margin_ticks = 0


func _resolve_player_hit() -> void:
	if assists.auto_bomb and state.bombs > 0:
		_trigger_bomb(true)
		return
	if state.automatic_saves_remaining > 0:
		state.automatic_saves_remaining -= 1
		state.invulnerability_ticks = 60
		pool.dissolve_all_committed()
		return
	state.lives -= 1
	state.hit_count += 1
	state.invulnerability_ticks = 90
	pool.dissolve_all_committed()
	if state.lives <= 0:
		_finish(&"loss")


func _trigger_bomb(was_automatic: bool) -> void:
	if state.bombs <= 0:
		return
	state.bombs -= 1
	state.bombs_used += 1
	state.automatic_bombs_used += int(was_automatic)
	state.invulnerability_ticks = 75
	state.boss_integrity = maxi(0, state.boss_integrity - 30)
	state.score += 200
	pool.dissolve_all_committed()


func _spend_margin_corridor() -> void:
	if state.margin < MARGIN_ACTION_COST:
		return
	state.margin -= MARGIN_ACTION_COST
	state.margin_spent += MARGIN_ACTION_COST
	state.inactive_margin_ticks = 0
	var half_width := 12 * FP
	for index: int in range(pool.capacity):
		if (
			pool.used[index] != 0
			and pool.lifecycle[index] == DanmakuBulletPool.Lifecycle.COMMITTED
			and absi(pool.x_fp[index] - state.player_x_fp) <= half_width
		):
			pool.begin_dissolve(index)


func _apply_player_shot(is_held: bool) -> void:
	if not is_held or state.phase_tick % 6 != 0:
		return
	state.boss_integrity = maxi(0, state.boss_integrity - 1)
	state.score += 10


func _tick_margin_decay() -> void:
	state.inactive_margin_ticks += 1
	if state.inactive_margin_ticks >= 180 and state.inactive_margin_ticks % 30 == 0:
		state.margin = maxi(0, state.margin - 1)


func _complete_phase() -> void:
	var phase := current_phase()
	var checkpoint := "%s|%d|%d|%d|%d|%d" % [
		phase.id,
		state.encounter_tick,
		state.lives,
		state.bombs,
		state.margin,
		state.graze_count,
	]
	checkpoints.append(checkpoint)
	phase_checkpoint.emit(checkpoint)
	state.completed_phases += 1
	if state.phase_index >= definition.phases.size() - 1:
		_finish(&"clear")
		return
	_enter_phase(state.phase_index + 1)


func _enter_phase(index: int) -> void:
	state.phase_index = index
	state.phase_tick = 0
	var phase := definition.phase(index)
	state.boss_integrity = phase.boss_integrity
	state.boss_integrity_max = phase.boss_integrity
	pool.clear(false)
	_phase_open_state = state.duplicate_state()
	_phase_open_spawn_counts = emitter_spawn_counts.duplicate()


func _finish(result_tag: StringName) -> ModeResult:
	if final_result != null:
		return final_result
	state.result_tag = result_tag
	final_result = ModeResult.new(result_tag)
	final_result.performance_band = (
		&"no_hit" if result_tag == &"clear" and state.hit_count == 0
		else &"messy" if result_tag == &"clear"
		else &"assist" if result_tag == &"assist_clear"
		else &"loss"
	)
	final_result.used_assist = assists.any_enabled() or result_tag == &"assist_clear"
	final_result.outcome_tags = [
		&"danmaku.boundary_stain",
		StringName("danmaku.result.%s" % result_tag),
	]
	var telemetry := ModeTelemetry.new()
	telemetry.deterministic_seed = deterministic_seed
	telemetry.elapsed_ticks = state.encounter_tick
	telemetry.final_state_hash = canonical_snapshot().sha256_text()
	final_result.telemetry = telemetry
	return final_result


func _index_emitters() -> void:
	_emitter_indices.clear()
	var index := 0
	for phase: DanmakuPhaseDefinition in definition.phases:
		for emitter: DanmakuEmitterDefinition in phase.emitters:
			_emitter_indices[emitter.id] = index
			index += 1
