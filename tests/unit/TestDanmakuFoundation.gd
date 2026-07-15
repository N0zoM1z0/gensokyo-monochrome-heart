class_name TestDanmakuFoundation
extends RefCounted
## M07 data, pooling, telegraph, controls, assists, retry, host, and replay contracts.

const PATTERN_PATH := "res://content/danmaku/boundary_stain.json"
const SCHEMA_PATH := "res://schemas/danmaku_pattern.schema.json"
const REPLAY_PATH := "res://tests/fixtures/danmaku/boundary_stain_golden_replay.json"
const KNIFE_PATTERN_PATH := "res://content/danmaku/missing_minute_knives.json"

var _definition: DanmakuPatternDefinition


func run() -> Array[String]:
	var failures: Array[String] = []
	var loader := DanmakuPatternLoader.new()
	_definition = loader.load_path(PATTERN_PATH)
	if _definition == null or not loader.errors.is_empty():
		return ["boundary-stain pattern could not be loaded: %s" % [loader.errors]]
	_expect_pattern_schema_and_identity(failures)
	_expect_packed_pool_and_safe_exhaustion(failures)
	_expect_movement_pause_and_phase_retry(failures)
	_expect_telegraph_graze_and_auto_bomb(failures)
	_expect_host_loss_and_assist_clear(failures)
	_expect_golden_replay(failures)
	_expect_all_assist_tiers_clear(failures)
	_expect_story_state_isolation(failures)
	_expect_missing_minute_components(failures)
	return failures


func _expect_pattern_schema_and_identity(failures: Array[String]) -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATTERN_PATH))
	var schema: Variant = JSON.parse_string(FileAccess.get_file_as_string(SCHEMA_PATH))
	var schema_errors := JsonSchemaValidator.new().validate(raw, schema)
	if not schema_errors.is_empty():
		failures.append("authored boundary-stain JSON failed its schema: %s" % [schema_errors])
	if _definition.phases.size() != 3 or _definition.emitter_signature().size() != 6:
		failures.append("boundary stain did not retain three phases and six data emitters")
	var expected_types := [&"lane_fan", &"offering_ring", &"safe_lane_grid"]
	for expected_type: StringName in expected_types:
		if not _contains_signature(_definition.emitter_signature(), expected_type):
			failures.append("boundary-stain data omitted pattern identity: %s" % expected_type)
	for phase: DanmakuPhaseDefinition in _definition.phases:
		for emitter: DanmakuEmitterDefinition in phase.emitters:
			var full := emitter.selected_slots(100)
			var reduced := emitter.selected_slots(55)
			if reduced.is_empty() or reduced.size() >= full.size():
				failures.append("55%% density did not reduce while preserving emitter %s" % emitter.id)
			elif reduced[0] != 0 or reduced[-1] != emitter.slot_count - 1:
				failures.append("55%% density removed the silhouette anchors for %s" % emitter.id)
	var safe_phase := _definition.phases[2]
	if safe_phase.safe_lane != 6 or safe_phase.emitters[0].safe_lane != 6:
		failures.append("remembered safe lane was not authored one tile off center")


func _expect_packed_pool_and_safe_exhaustion(failures: Array[String]) -> void:
	var pool := DanmakuBulletPool.new(4)
	var spec := DanmakuBulletSpec.new()
	spec.telegraph_ticks = 3
	for _index: int in range(5):
		pool.spawn(spec)
	if pool.active_count != 4 or pool.dropped_spawn_count != 1:
		failures.append("bullet pool exhaustion did not degrade to a counted dropped spawn")
	pool.step(224 * 256, 152 * 256)
	pool.step(224 * 256, 152 * 256)
	if pool.committed_count != 0:
		failures.append("telegraphed bullets became damaging before their warning elapsed")
	pool.step(224 * 256, 152 * 256)
	if pool.committed_count != 4 or pool.untelegraphed_commit_count != 0:
		failures.append("bullet pool did not commit four warned bullets exactly on schedule")
	pool.dissolve_all_committed()
	for _tick: int in range(DanmakuBulletPool.DISSOLVE_TICKS):
		pool.step(224 * 256, 152 * 256)
	if pool.active_count != 0:
		failures.append("dissolved bullets did not return to the fixed pool")
	var stress_pool := DanmakuBulletPool.new(2500)
	for _index: int in range(2501):
		stress_pool.spawn(spec)
	if stress_pool.active_count != 2500 or stress_pool.used.size() != 2500 or stress_pool.dropped_spawn_count != 1:
		failures.append("2,500-bullet packed stress capacity was not exact or exhaustion-safe")
	var source := FileAccess.get_file_as_string("res://src/application/danmaku/DanmakuBulletPool.gd")
	if source.contains("extends Node") or source.contains("Node2D"):
		failures.append("bullet pool introduced a Node per bullet")
	var renderer_source := FileAccess.get_file_as_string(
		"res://src/presentation/danmaku/DanmakuBulletBatchRenderer.gd"
	)
	if (
		DanmakuBulletBatchRenderer.Batch.COUNT != 10
		or not renderer_source.contains("draw_multimesh")
		or not renderer_source.contains("extends RefCounted")
	):
		failures.append("presentation lost its ten-batch MultiMesh/no-bullet-Node contract")


func _expect_missing_minute_components(failures: Array[String]) -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(KNIFE_PATTERN_PATH))
	var schema: Variant = JSON.parse_string(FileAccess.get_file_as_string(SCHEMA_PATH))
	var schema_errors := JsonSchemaValidator.new().validate(raw, schema)
	if not schema_errors.is_empty():
		failures.append("missing-minute knife JSON failed its schema: %s" % [schema_errors])
		return
	var loader := DanmakuPatternLoader.new()
	var knife_definition := loader.load_path(KNIFE_PATTERN_PATH)
	if knife_definition == null or not loader.errors.is_empty():
		failures.append("missing-minute knife pattern could not load: %s" % [loader.errors])
		return
	for component: StringName in [&"knife_lattice", &"clock_hand", &"stopped_release"]:
		if not _contains_signature(knife_definition.emitter_signature(), component):
			failures.append("missing-minute data omitted component %s" % component)
	if knife_definition.phases[0].safe_lane != 5 or knife_definition.phases[0].emitters[0].safe_lane != 5:
		failures.append("knife-lattice teaching data omitted its central appointment gap")
	var simulation := BoundaryStainSimulation.new()
	if not simulation.configure(knife_definition, _context(12121), DanmakuAssistSettings.new(), 512):
		failures.append("generic danmaku simulation rejected missing-minute components")
		return
	for _tick: int in range(250):
		simulation.step(DanmakuInputFrame.new())
	if simulation.pool.total_spawned <= 0 or simulation.pool.untelegraphed_commit_count != 0:
		failures.append("knife components did not emit warned deterministic bullets")
	var accepted := simulation.accept_loss()
	if accepted == null or accepted.outcome_tags[0] != knife_definition.id:
		failures.append("generic danmaku result retained a boundary-specific outcome tag")


func _expect_movement_pause_and_phase_retry(failures: Array[String]) -> void:
	var simulation := _configured_simulation(7001, DanmakuAssistSettings.new())
	var right := DanmakuInputFrame.new()
	right.horizontal_axis = 1
	var opening_x := simulation.state.player_x_fp
	for _tick: int in range(10):
		simulation.step(right)
	var normal_distance := simulation.state.player_x_fp - opening_x
	simulation.reset_encounter()
	var focus_right := DanmakuInputFrame.new()
	focus_right.horizontal_axis = 1
	focus_right.focus_held = true
	opening_x = simulation.state.player_x_fp
	for _tick: int in range(10):
		simulation.step(focus_right)
	var focus_distance := simulation.state.player_x_fp - opening_x
	if normal_distance <= focus_distance or simulation.player_hit_radius_fp() != BoundaryStainSimulation.PLAYER_FOCUS_HIT_RADIUS_FP:
		failures.append("Focus did not immediately slow movement and expose the 2x2 hitbox contract")
	var before_pause := simulation.canonical_snapshot()
	simulation.toggle_pause()
	for _tick: int in range(60):
		simulation.step(right)
	if simulation.canonical_snapshot() != before_pause:
		failures.append("paused danmaku continued its fixed-step simulation")
	simulation.toggle_pause()
	simulation.reset_encounter()
	var held_focus := DanmakuInputFrame.new()
	held_focus.focus_held = true
	held_focus.shot_held = true
	for _tick: int in range(120):
		simulation.step(held_focus)
	var first_run := simulation.canonical_snapshot()
	simulation.retry_phase()
	for _tick: int in range(120):
		simulation.step(held_focus)
	if simulation.canonical_snapshot() != first_run:
		failures.append("phase retry did not reproduce the same seed/input state exactly")


func _expect_telegraph_graze_and_auto_bomb(failures: Array[String]) -> void:
	var auto_assists := DanmakuAssistSettings.new()
	auto_assists.auto_bomb = true
	var auto_sim := _configured_simulation(7002, auto_assists)
	var direct := DanmakuBulletSpec.new()
	direct.x_fp = auto_sim.state.player_x_fp
	direct.y_fp = auto_sim.state.player_y_fp
	direct.velocity_y_fp = 1
	direct.telegraph_ticks = 2
	direct.lifetime_ticks = 30
	auto_sim.pool.spawn(direct)
	auto_sim.step(DanmakuInputFrame.new())
	if auto_sim.state.bombs != 2 or auto_sim.pool.committed_count != 0:
		failures.append("Story bullet damaged the player during its telegraph")
	auto_sim.step(DanmakuInputFrame.new())
	if auto_sim.state.bombs != 1 or auto_sim.state.automatic_bombs_used != 1 or auto_sim.state.lives != 3:
		failures.append("auto-bomb did not consume one bomb before life loss")
	if auto_sim.pool.untelegraphed_commit_count != 0:
		failures.append("Story simulation recorded an untelegraphed damaging commit")

	var normal_sim := _configured_simulation(7003, DanmakuAssistSettings.new())
	var edge := DanmakuBulletSpec.new()
	edge.x_fp = normal_sim.state.player_x_fp + 640
	edge.y_fp = normal_sim.state.player_y_fp
	edge.velocity_y_fp = 1
	edge.telegraph_ticks = 1
	edge.lifetime_ticks = 30
	normal_sim.pool.spawn(edge)
	normal_sim.step(DanmakuInputFrame.new())
	if normal_sim.state.automatic_saves_remaining != 1:
		failures.append("normal 4x4 hitbox did not resolve the near-center collision")
	var focus_sim := _configured_simulation(7003, DanmakuAssistSettings.new())
	focus_sim.pool.spawn(edge)
	var focus := DanmakuInputFrame.new()
	focus.focus_held = true
	focus_sim.step(focus)
	if focus_sim.state.automatic_saves_remaining != 2 or focus_sim.state.graze_count != 1 or focus_sim.state.margin <= 0:
		failures.append("Focus hitbox did not turn the same near miss into Margin-producing graze")
	focus_sim.state.margin = BoundaryStainSimulation.MARGIN_ACTION_COST
	var spend := DanmakuInputFrame.new()
	spend.focus_held = true
	spend.margin_pressed = true
	focus_sim.step(spend)
	if focus_sim.state.margin != 0 or focus_sim.state.margin_spent != BoundaryStainSimulation.MARGIN_ACTION_COST or focus_sim.pool.committed_count != 0:
		failures.append("Margin corridor did not spend its resource and dissolve nearby bullets")


func _expect_host_loss_and_assist_clear(failures: Array[String]) -> void:
	var host := DanmakuHost.new()
	if not host.load_encounter(
		BoundaryStainSimulation.new(),
		_definition,
		_context(7004),
		DanmakuAssistSettings.new()
	):
		failures.append("DanmakuHost rejected the valid boundary-stain encounter")
		return
	var emitted := [0]
	host.result_ready.connect(func(_result: ModeResult) -> void: emitted[0] += 1)
	for _defeat: int in range(3):
		var loss := host.accept_loss()
		if loss == null or loss.result_tag != &"loss":
			failures.append("Accept Loss did not return a typed story result")
		host.step(DanmakuInputFrame.new())
		host.retry_phase()
	if host.defeat_count != 3 or not host.can_assist_clear() or emitted[0] != 3:
		failures.append("Assist Clear did not unlock after exactly three recorded defeats")
	var assisted := host.assist_clear()
	if assisted == null or assisted.result_tag != &"assist_clear" or not assisted.used_assist:
		failures.append("Assist Clear did not return an explicit assisted ModeResult")
	if assisted.telemetry == null or assisted.telemetry.attempt_count != 4:
		failures.append("danmaku result telemetry lost the phase-attempt count")


func _expect_golden_replay(failures: Array[String]) -> void:
	var tape := DanmakuReplayTape.load_path(REPLAY_PATH)
	if tape == null:
		failures.append("golden boundary-stain replay fixture could not be parsed")
		return
	var playback := DanmakuReplayPlayer.new().play(tape, _definition)
	if not playback.is_valid:
		failures.append("golden boundary-stain replay mismatch: %s" % playback.diagnostic)
		return
	if playback.result == null or playback.result.result_tag != &"clear" or playback.checkpoints.size() != 3:
		failures.append("golden replay did not clear all three checkpointed phases")
	if playback.runtime.pool.untelegraphed_commit_count != 0:
		failures.append("golden Story replay contained a damaging spawn without telegraph")


func _expect_all_assist_tiers_clear(failures: Array[String]) -> void:
	var source := DanmakuReplayTape.load_path(REPLAY_PATH)
	for density: int in DanmakuAssistSettings.DENSITY_TIERS:
		for speed: int in DanmakuAssistSettings.SPEED_TIERS:
			var tape := DanmakuReplayTape.new()
			tape.pattern_id = source.pattern_id
			tape.pattern_data_hash = source.pattern_data_hash
			tape.deterministic_seed = source.deterministic_seed
			tape.assist_signature = "1|%d|%d|1|1|1|70|1" % [speed, density]
			tape.encoded_frames = source.encoded_frames.duplicate()
			var playback := DanmakuReplayPlayer.new().play(tape, _definition)
			if playback.result == null or playback.result.result_tag != &"clear":
				failures.append("density %d / speed %d assist tier was not completable" % [density, speed])


func _expect_story_state_isolation(failures: Array[String]) -> void:
	var content := ContentRepository.new()
	if not content.load_sources().is_success():
		failures.append("content could not be loaded for danmaku story-isolation fixture")
		return
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in content.all_characters():
		character_ids.append(character.id)
	var location_ids: Array[StringName] = []
	for location: LocationRecord in content.all_locations():
		location_ids.append(location.id)
	var story := GameStateFactory.create_new(&"p70", character_ids, location_ids, 7005)
	var before := GameStateCodec.new().canonical_state(story)
	var simulation := _configured_simulation(7005, DanmakuAssistSettings.new())
	for _tick: int in range(180):
		simulation.step(DanmakuInputFrame.new())
	simulation.accept_loss()
	if GameStateCodec.new().canonical_state(story) != before:
		failures.append("boundary-stain simulation mutated GameState instead of returning ModeResult")


func _configured_simulation(seed: int, assists: DanmakuAssistSettings) -> BoundaryStainSimulation:
	var simulation := BoundaryStainSimulation.new()
	simulation.configure(_definition, _context(seed), assists, 512)
	return simulation


func _context(seed: int) -> ModeContext:
	var context := ModeContext.new()
	context.mode_type = &"start_danmaku"
	context.mode_id = &"danmaku.hkr.boundary_stain"
	context.event_id = &"evt.hkr.boundary_stain"
	context.node_id = &"n_danmaku"
	context.deterministic_seed = seed
	return context


func _contains_signature(signatures: PackedStringArray, needle: StringName) -> bool:
	for signature: String in signatures:
		if signature.contains(needle):
			return true
	return false
