class_name CompactFighterMode
extends GameMode
## One-bit Reimu/Marisa story duel with data-owned timing and combat boxes.

const DUEL_PATH := "res://content/fighter/reimu_marisa_duel.json"
const FIXED_DELTA := 1.0 / float(FighterDuelSimulation.TICKS_PER_SECOND)
const ARENA_FRAME := Rect2(4, 39, 312, 114)
const FOOTER_FRAME := Rect2(4, 155, 312, 21)
const ACTION_CONTRACT := [
	"move", "light", "heavy", "skill", "spell", "guard", "pause", "confirm", "cancel",
]
const REIMU_SHEET: Texture2D = preload("res://assets/art/fighter/reimu_m_sheet.png")
const REIMU_SHEET_INVERTED: Texture2D = preload("res://assets/art/fighter/reimu_m_sheet_inverted.png")
const MARISA_SHEET: Texture2D = preload("res://assets/art/fighter/marisa_m_sheet.png")
const MARISA_SHEET_INVERTED: Texture2D = preload("res://assets/art/fighter/marisa_m_sheet_inverted.png")

@export_enum("live", "intro", "active", "hitbox", "spell_break", "down", "paused", "training", "result_win", "result_loss", "stress") var fixture_state: String = "live"

var host := FighterHost.new()
var runtime: FighterDuelSimulation
var definition: FighterDuelDefinition
var assist_settings := FighterAssistSettings.new()
var final_result: ModeResult

var _profile: PresentationProfile = PresentationProfileRegistry.resolve(&"A")
var _batch_renderer := FighterBatchRenderer.new()
var _locale: StringName = &"en"
var _catalog := UiTextCatalog.new()
var _latin_font: Font
var _japanese_font: Font
var _fixed_accumulator: float = 0.0
var _intro_ticks_remaining: int = 45
var _break_banner_ticks: int = 0
var _resume_countdown_ticks: int = 0
var _pause_focus: int = 0
var _training_tab: int = 0
var _training_overlay: bool = false
var _show_combat_boxes: bool = false
var _completion_emitted: bool = false
var _fixture_frozen: bool = false
var _queued_action: StringName
var _visual_cue_key: StringName
var _visual_cue_seconds: float = 0.0
var _border_stamp_seconds: float = 0.0
var _input_history := PackedInt32Array()
var _stress_effects: int = 0
var _is_reduced_motion: bool = false
var _is_safe_flash: bool = false
var _no_flash_active: bool = false

@onready var sfx_player: ProceduralSfxPlayer = %ProceduralSfxPlayer


func _ready() -> void:
	InputMapInstaller.install_defaults()
	_latin_font = UiFontRegistry.latin()
	_japanese_font = UiFontRegistry.japanese()
	_catalog.load_default()
	custom_minimum_size = Vector2(320, 180)
	size = Vector2(320, 180)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if mode_context == null:
		mode_context = _default_context()
	_load_runtime()
	ready_for_input.emit()


func configure(context: ModeContext) -> void:
	super.configure(context)
	if is_node_ready():
		_load_runtime()


func configure_fixture(
	requested_profile: StringName,
	locale: StringName,
	forced_profile: StringName = &"",
	is_reduced_motion: bool = false,
	is_safe_flash: bool = false
) -> void:
	_profile = PresentationProfileRegistry.resolve(
		forced_profile if forced_profile != &"" else requested_profile
	)
	_locale = locale if locale in [&"en", &"ja"] else &"en"
	_is_reduced_motion = is_reduced_motion
	_is_safe_flash = is_safe_flash
	if is_node_ready():
		_load_runtime()


func configure_assists(settings: FighterAssistSettings) -> void:
	assist_settings = settings.duplicate_settings() if settings != null else FighterAssistSettings.new()
	if is_node_ready():
		_load_runtime()


func switch_locale(next_locale: StringName) -> void:
	if next_locale in [&"en", &"ja"]:
		_locale = next_locale
		queue_redraw()


func _physics_process(delta: float) -> void:
	if _fixture_frozen or is_suspended or runtime == null or runtime.is_paused or final_result != null:
		return
	_fixed_accumulator = minf(_fixed_accumulator + delta, FIXED_DELTA * 4.0)
	while _fixed_accumulator >= FIXED_DELTA:
		if _resume_countdown_ticks > 0:
			_resume_countdown_ticks -= 1
		elif _intro_ticks_remaining > 0:
			_intro_ticks_remaining -= 1
		elif _break_banner_ticks > 0:
			_break_banner_ticks -= 1
		else:
			_step_runtime(_capture_input())
		_fixed_accumulator -= FIXED_DELTA
	queue_redraw()


func _process(delta: float) -> void:
	_visual_cue_seconds = maxf(0.0, _visual_cue_seconds - maxf(0.0, delta))
	_border_stamp_seconds = maxf(0.0, _border_stamp_seconds - maxf(0.0, delta))
	if fixture_state == "live" or _visual_cue_seconds > 0.0 or _border_stamp_seconds > 0.0:
		queue_redraw()


func handle_semantic_action(action: StringName) -> bool:
	if runtime == null:
		return false
	if final_result != null:
		if action == GameInput.CONFIRM:
			_emit_completion_once()
			return true
		if action == GameInput.CANCEL:
			_retry_duel()
			return true
		return false
	if _training_overlay:
		return _handle_training_action(action)
	if runtime.is_paused:
		return _handle_pause_action(action)
	if action in [GameInput.LIGHT, GameInput.HEAVY, GameInput.SKILL, GameInput.SPELL]:
		_queued_action = action
		return true
	if action in [GameInput.PAUSE, GameInput.CANCEL]:
		host.toggle_pause()
		_pause_focus = 0
		queue_redraw()
		return true
	return false


func step_fixture(
	ticks: int,
	player_frame: FighterInputFrame = null,
	opponent_frame: FighterInputFrame = null
) -> ModeResult:
	var player := player_frame if player_frame != null else FighterInputFrame.new()
	var opponent := opponent_frame if opponent_frame != null else FighterInputFrame.new()
	var result: ModeResult
	for _tick: int in range(maxi(0, ticks)):
		result = _step_runtime(player, opponent)
		if result != null:
			break
	queue_redraw()
	return result


func pause_for_test() -> void:
	host.toggle_pause()
	_pause_focus = 0
	queue_redraw()


func retry_for_test() -> void:
	_retry_duel()


func accept_loss_for_test() -> ModeResult:
	return host.accept_loss()


func force_spell_break_for_test(winner_side: int = 0) -> void:
	runtime.force_damage_for_test(1 - winner_side, FighterState.MAX_VITALITY, winner_side)
	if runtime.final_result != null:
		# Forced damage bypasses FighterHost.step(), so hand the terminal result back
		# through the host once to preserve the normal single-emission lifecycle.
		host.step(FighterInputFrame.new())


func training_frame_step_for_test(frame: FighterInputFrame = null) -> ModeResult:
	return host.training_frame_step(
		frame if frame != null else FighterInputFrame.new(),
		FighterInputFrame.new()
	)


func set_hitbox_viewer(enabled: bool) -> void:
	_show_combat_boxes = enabled
	queue_redraw()


func action_contract() -> PackedStringArray:
	return PackedStringArray(ACTION_CONTRACT)


func resolve_input_candidates(candidates: Array[StringName]) -> StringName:
	if final_result != null or _training_overlay or (runtime != null and runtime.is_paused):
		return GameInput.first_matching(candidates, [
			GameInput.MOVE_UP, GameInput.MOVE_DOWN, GameInput.MOVE_LEFT,
			GameInput.MOVE_RIGHT, GameInput.CONFIRM, GameInput.CANCEL, GameInput.PAUSE,
		])
	return GameInput.first_matching(candidates, [
		GameInput.PAUSE,
		GameInput.LIGHT,
		GameInput.HEAVY,
		GameInput.SKILL,
		GameInput.SPELL,
		GameInput.GUARD,
		GameInput.MOVE_UP,
		GameInput.MOVE_DOWN,
		GameInput.MOVE_LEFT,
		GameInput.MOVE_RIGHT,
		GameInput.CONFIRM,
		GameInput.CANCEL,
	])


func state_snapshot() -> String:
	return runtime.canonical_snapshot() if runtime != null else ""


func current_result() -> ModeResult:
	return final_result


func is_paused_state() -> bool:
	return runtime != null and runtime.is_paused


func resolved_profile_id() -> StringName:
	return _profile.profile_id


func rendered_projectile_count() -> int:
	return runtime.projectiles.active_count if runtime != null else 0


func rendered_effect_count() -> int:
	return _stress_effects


func rendered_fighter_count() -> int:
	return 2 if runtime != null and runtime.states.size() == 2 else 0


func capture_debug_state() -> Dictionary:
	var debug := super.capture_debug_state()
	debug.merge({
		"duel_id": String(definition.id) if definition != null else "",
		"tick": runtime.encounter_tick if runtime != null else -1,
		"phase": runtime.phase_index if runtime != null else -1,
		"projectiles": runtime.projectiles.active_count if runtime != null else -1,
		"effects": _stress_effects,
		"fighters": rendered_fighter_count(),
		"player_move": String(runtime.states[0].current_move_id) if runtime != null else "",
		"opponent_move": String(runtime.states[1].current_move_id) if runtime != null else "",
		"hitbox": runtime.current_hitbox(0) if runtime != null else Rect2i(),
		"hurtbox": runtime.current_hurtbox(0) if runtime != null else Rect2i(),
		"paused": runtime.is_paused if runtime != null else false,
		"training": _training_overlay,
			"resume_countdown_ticks": _resume_countdown_ticks,
			"no_flash": _no_flash_active,
			"flash_border_active": _border_stamp_seconds > 0.0,
			"result": String(final_result.result_tag) if final_result != null else "",
	}, true)
	return debug


func _default_context() -> ModeContext:
	var context := ModeContext.new()
	context.mode_type = &"start_duel"
	context.mode_id = &"duel.hkr.spell_card_terms"
	context.event_id = &"evt.hkr.spell_card_terms"
	context.node_id = &"n_duel"
	context.deterministic_seed = 8088
	return context


func _load_runtime() -> void:
	var loader := FighterDefinitionLoader.new()
	definition = loader.load_path(DUEL_PATH)
	if definition == null or not loader.errors.is_empty():
		push_error("Compact fighter data could not load: %s" % [loader.errors])
		return
	var settings := assist_settings.duplicate_settings()
	settings.no_flash = settings.no_flash or _is_safe_flash
	_no_flash_active = settings.no_flash
	settings.reduced_motion = settings.reduced_motion or _is_reduced_motion
	if fixture_state in ["training", "stress"]:
		settings.simple_inputs = true
		settings.hold_to_guard = true
	host = FighterHost.new()
	host.result_ready.connect(_on_result_ready)
	host.spell_break.connect(_on_spell_break)
	var next_runtime := FighterDuelSimulation.new()
	if not host.load_duel(next_runtime, definition, mode_context, settings, &"story"):
		runtime = null
		push_error("Compact fighter host rejected its configuration")
		return
	runtime = next_runtime
	final_result = null
	_fixed_accumulator = 0.0
	_intro_ticks_remaining = 45
	_break_banner_ticks = 0
	_resume_countdown_ticks = 0
	_pause_focus = 0
	_training_tab = 0
	_training_overlay = false
	_show_combat_boxes = false
	_completion_emitted = false
	_queued_action = &""
	_visual_cue_key = &""
	_visual_cue_seconds = 0.0
	_border_stamp_seconds = 0.0
	_input_history.clear()
	_stress_effects = 0
	_fixture_frozen = fixture_state != "live"
	_prepare_fixture_state()
	queue_redraw()


func _prepare_fixture_state() -> void:
	if runtime == null:
		return
	match fixture_state:
		"intro":
			_intro_ticks_remaining = 45
		"active":
			_intro_ticks_remaining = 0
			step_fixture(42, _input_frame(1, 0), _input_frame(-1, 0))
			var player_heavy := _input_frame(0, 0)
			player_heavy.heavy_pressed = true
			step_fixture(1, player_heavy, FighterInputFrame.new())
			step_fixture(18)
		"hitbox":
			_intro_ticks_remaining = 0
			runtime.states[0].x_fp = 126 * FighterDuelSimulation.FP
			runtime.states[1].x_fp = 153 * FighterDuelSimulation.FP
			var heavy := FighterInputFrame.new()
			heavy.heavy_pressed = true
			step_fixture(1, heavy)
			step_fixture(8)
			_show_combat_boxes = true
		"spell_break":
			_intro_ticks_remaining = 0
			force_spell_break_for_test(0)
		"down":
			_intro_ticks_remaining = 0
			runtime.states[0].vitality = 180
			runtime.states[0].vitality_notch = 680
			runtime.states[0].hitstun_ticks = 12
			runtime.states[0].visual_pose = &"hit"
		"paused":
			_intro_ticks_remaining = 0
			step_fixture(34, _input_frame(1, 0), _input_frame(-1, 0))
			host.toggle_pause()
		"training":
			_intro_ticks_remaining = 0
			runtime.states[0].x_fp = 128 * FighterDuelSimulation.FP
			runtime.states[1].x_fp = 154 * FighterDuelSimulation.FP
			var light := FighterInputFrame.new()
			light.light_pressed = true
			step_fixture(1, light)
			step_fixture(4)
			host.toggle_pause()
			_training_overlay = true
			_show_combat_boxes = true
			_input_history = PackedInt32Array([5, 6, 69, 5, 21])
		"result_win":
			_intro_ticks_remaining = 0
			force_spell_break_for_test(0)
			force_spell_break_for_test(0)
		"result_loss":
			_intro_ticks_remaining = 0
			host.accept_loss()
		"stress":
			_intro_ticks_remaining = 0
			_prepare_projectile_stress()


func _prepare_projectile_stress() -> void:
	runtime.projectiles.clear(true)
	for side: int in range(2):
		for index: int in range(64):
			var spec := FighterProjectileSpec.new()
			spec.owner_side = side
			spec.x_fp = (16 + (index % 16) * 18 + side * 4) * FighterDuelSimulation.FP
			spec.y_fp = (14 + floori(index / 16.0) * 20 + side * 7) * FighterDuelSimulation.FP
			spec.velocity_x_fp = 1 if side == 0 else -1
			spec.damage = 1
			spec.guard_damage = 1
			spec.hitstun_ticks = 1
			spec.blockstun_ticks = 1
			spec.lifetime_ticks = 600
			spec.family = [&"amulet", &"star", &"laser"][index % 3]
			runtime.projectiles.spawn(spec)
	_stress_effects = 40


func _capture_input() -> FighterInputFrame:
	var frame := FighterInputFrame.new()
	frame.horizontal_axis = roundi(Input.get_axis(GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT))
	frame.vertical_axis = roundi(Input.get_axis(GameInput.MOVE_UP, GameInput.MOVE_DOWN))
	frame.guard_held = Input.is_action_pressed(GameInput.GUARD)
	frame.light_pressed = Input.is_action_just_pressed(GameInput.LIGHT) or _queued_action == GameInput.LIGHT
	frame.heavy_pressed = Input.is_action_just_pressed(GameInput.HEAVY) or _queued_action == GameInput.HEAVY
	frame.skill_pressed = Input.is_action_just_pressed(GameInput.SKILL) or _queued_action == GameInput.SKILL
	frame.spell_pressed = Input.is_action_just_pressed(GameInput.SPELL) or _queued_action == GameInput.SPELL
	_queued_action = &""
	return frame


func _input_frame(horizontal: int, vertical: int) -> FighterInputFrame:
	var frame := FighterInputFrame.new()
	frame.horizontal_axis = horizontal
	frame.vertical_axis = vertical
	return frame


func _step_runtime(
	player: FighterInputFrame,
	opponent: FighterInputFrame = null
) -> ModeResult:
	var old_vitality := runtime.states[1].vitality
	var old_player_temperament := runtime.states[0].temperament
	var old_marisa_firepower := runtime.states[1].firepower_level
	var result := (
		host.step_with_inputs(player, opponent if opponent != null else FighterInputFrame.new())
		if opponent != null
		else host.step(player)
	)
	_input_history.append(player.encoded())
	while _input_history.size() > 12:
		_input_history.remove_at(0)
	if runtime.states[1].vitality < old_vitality:
		_show_cue(
			&"ui.fighter.cue.guard" if runtime.states[1].last_hit_kind == &"guard" else &"ui.fighter.cue.hit",
			&"sfx.fighter.impact",
			210.0,
			0.07
		)
		_border_stamp_seconds = 0.0 if _no_flash_active else 0.18
	if runtime.states[0].temperament >= old_player_temperament + 100:
		_show_cue(&"ui.fighter.cue.neutral_reset", &"sfx.fighter.temperament", 520.0, 0.08)
	if runtime.states[1].firepower_level > old_marisa_firepower:
		_show_cue(&"ui.fighter.cue.momentum", &"sfx.fighter.momentum", 660.0, 0.07)
	return result


func _handle_pause_action(action: StringName) -> bool:
	if action in [GameInput.MOVE_UP, GameInput.MOVE_LEFT]:
		_pause_focus = posmod(_pause_focus - 1, 4)
		queue_redraw()
		return true
	if action in [GameInput.MOVE_DOWN, GameInput.MOVE_RIGHT]:
		_pause_focus = posmod(_pause_focus + 1, 4)
		queue_redraw()
		return true
	if action in [GameInput.CANCEL, GameInput.PAUSE]:
		_resume_from_pause()
		return true
	if action != GameInput.CONFIRM:
		return false
	match _pause_focus:
		0:
			_resume_from_pause()
		1:
			_retry_duel()
		2:
			host.accept_loss()
		3:
			_training_overlay = true
			_show_combat_boxes = true
	queue_redraw()
	return true


func _handle_training_action(action: StringName) -> bool:
	if action in [GameInput.CANCEL, GameInput.PAUSE]:
		_training_overlay = false
		queue_redraw()
		return true
	if action == GameInput.PAGE_LEFT:
		_training_tab = posmod(_training_tab - 1, 4)
		queue_redraw()
		return true
	if action == GameInput.PAGE_RIGHT:
		_training_tab = posmod(_training_tab + 1, 4)
		queue_redraw()
		return true
	if action != GameInput.CONFIRM:
		return false
	if _training_tab == 3:
		_retry_duel()
		host.toggle_pause()
		_training_overlay = true
		_show_combat_boxes = true
	else:
		host.training_frame_step(FighterInputFrame.new(), FighterInputFrame.new())
	queue_redraw()
	return true


func _resume_from_pause() -> void:
	host.toggle_pause()
	_resume_countdown_ticks = 3
	queue_redraw()


func _retry_duel() -> void:
	host.retry_match()
	final_result = null
	_fixed_accumulator = 0.0
	_intro_ticks_remaining = 18
	_break_banner_ticks = 0
	_resume_countdown_ticks = 0
	_pause_focus = 0
	_training_overlay = false
	_completion_emitted = false
	_visual_cue_seconds = 0.0
	_border_stamp_seconds = 0.0
	_input_history.clear()
	queue_redraw()


func _on_spell_break(_checkpoint: String) -> void:
	_break_banner_ticks = 30
	checkpoint_requested.emit(&"fighter_spell_break")
	_show_cue(&"ui.fighter.cue.spell_break", &"sfx.fighter.spell_break", 330.0, 0.15)
	_border_stamp_seconds = 0.0 if _no_flash_active else 0.28
	queue_redraw()


func _on_result_ready(result: ModeResult) -> void:
	final_result = result
	checkpoint_requested.emit(&"fighter_result")
	_show_cue(
		&"ui.fighter.cue.spell_break" if result.result_tag == &"win" else &"ui.fighter.cue.guard",
		&"sfx.fighter.result",
		470.0 if result.result_tag == &"win" else 190.0,
		0.16
	)
	queue_redraw()


func _show_cue(key: StringName, cue_id: StringName, pitch: float, duration: float) -> void:
	_visual_cue_key = key
	_visual_cue_seconds = 0.75
	sfx_player.play_cue(AudioCueIntent.new(cue_id, key, pitch, duration))


func _emit_completion_once() -> void:
	if final_result == null or _completion_emitted:
		return
	_completion_emitted = true
	mode_completed.emit(final_result)


func _draw() -> void:
	var background := _profile.ink if _profile.is_inverted else _profile.paper
	var foreground := _profile.paper if _profile.is_inverted else _profile.ink
	draw_rect(Rect2(0, 0, 320, 180), background)
	if runtime == null:
		return
	if final_result != null:
		_draw_result(foreground, background)
		return
	_draw_hud(foreground, background)
	_draw_arena(foreground, background)
	_draw_projectiles(foreground, background)
	_draw_fighter(0)
	_draw_fighter(1)
	if _show_combat_boxes:
		_draw_combat_boxes(foreground)
	_draw_footer(foreground, background)
	if _intro_ticks_remaining > 0:
		_draw_intro(foreground, background)
	if _break_banner_ticks > 0:
		_draw_break_banner(foreground, background)
	if _visual_cue_seconds > 0.0:
		_draw_visual_cue(foreground, background)
	if runtime.is_paused and not _training_overlay:
		_draw_pause(foreground, background)
	if _training_overlay:
		_draw_training(foreground, background)
	if _resume_countdown_ticks > 0:
		_draw_resume_countdown(foreground, background)
	if _border_stamp_seconds > 0.0 and not _no_flash_active:
		draw_rect(ARENA_FRAME.grow(-2), foreground, false, 2.0)


func _draw_hud(foreground: Color, background: Color) -> void:
	var font := _font()
	var player := runtime.states[0]
	var opponent := runtime.states[1]
	draw_string(font, Vector2(5, 9), _fighter_name(0), HORIZONTAL_ALIGNMENT_LEFT, 126, 7, foreground)
	draw_string(font, Vector2(189, 9), _fighter_name(1), HORIZONTAL_ALIGNMENT_RIGHT, 126, 7, foreground)
	draw_string(font, Vector2(134, 9), _catalog.text(&"ui.fighter.round", _locale), HORIZONTAL_ALIGNMENT_CENTER, 52, 6, foreground)
	_draw_mirrored_meter(Rect2(5, 13, 126, 7), player.vitality, player.vitality_notch, FighterState.MAX_VITALITY, false, foreground, background)
	_draw_mirrored_meter(Rect2(189, 13, 126, 7), opponent.vitality, opponent.vitality_notch, FighterState.MAX_VITALITY, true, foreground, background)
	_draw_mirrored_meter(Rect2(5, 24, 104, 5), player.temperament, player.temperament, FighterState.MAX_TEMPERAMENT, false, foreground, background)
	_draw_mirrored_meter(Rect2(211, 24, 104, 5), opponent.temperament, opponent.temperament, FighterState.MAX_TEMPERAMENT, true, foreground, background)
	for side: int in range(2):
		for pip: int in range(2):
			var x := 113 + pip * 9 if side == 0 else 199 - pip * 9
			var filled := pip < runtime.states[side].breaks_won
			if filled:
				draw_rect(Rect2(x, 23, 7, 7), foreground)
			else:
				draw_rect(Rect2(x, 23, 7, 7), foreground, false, 1.0)
	draw_string(font, Vector2(112, 36), _catalog.text(&"ui.fighter.terms.title", _locale), HORIZONTAL_ALIGNMENT_CENTER, 96, 7, foreground)


func _draw_mirrored_meter(
	rect: Rect2,
	value: int,
	notch: int,
	maximum: int,
	mirrored: bool,
	foreground: Color,
	background: Color
) -> void:
	draw_rect(rect, foreground, false, 1.0)
	var inner_width := rect.size.x - 4
	var ratio := clampf(value / float(maxi(1, maximum)), 0.0, 1.0)
	var fill_width := floori(inner_width * ratio)
	var fill_x := rect.position.x + rect.size.x - 2 - fill_width if mirrored else rect.position.x + 2
	if fill_width > 0:
		draw_rect(Rect2(fill_x, rect.position.y + 2, fill_width, rect.size.y - 4), foreground)
	var notch_ratio := clampf(notch / float(maxi(1, maximum)), 0.0, 1.0)
	var notch_x := (
		rect.position.x + rect.size.x - 2 - floori(inner_width * notch_ratio)
		if mirrored
		else rect.position.x + 2 + floori(inner_width * notch_ratio)
	)
	draw_line(Vector2(notch_x, rect.position.y + 1), Vector2(notch_x, rect.end.y - 1), foreground, 1.0)
	if ratio <= 0.0:
		draw_rect(rect.grow(-2), background)


func _draw_arena(foreground: Color, background: Color) -> void:
	draw_rect(ARENA_FRAME, background)
	draw_rect(ARENA_FRAME, foreground, false, 1.0)
	var dense_effects := runtime.projectiles.active_count + _stress_effects > 40
	if not dense_effects:
		draw_line(Vector2(38, 132), Vector2(38, 77), foreground, 1.0)
		draw_line(Vector2(282, 132), Vector2(282, 77), foreground, 1.0)
		draw_line(Vector2(25, 80), Vector2(295, 80), foreground, 2.0)
		draw_rect(Rect2(145, 113, 30, 20), foreground, false, 1.0)
		draw_line(Vector2(4, 136), Vector2(316, 136), foreground, 1.0)
		draw_line(Vector2(4, 143), Vector2(316, 143), foreground, 2.0)
	else:
		draw_line(Vector2(4, 143), Vector2(316, 143), foreground, 2.0)
	_batch_renderer.draw_effects(self, _stress_effects, foreground)


func _draw_projectiles(foreground: Color, _background: Color) -> void:
	_batch_renderer.draw_projectiles(self, runtime.projectiles, definition.ground_y, foreground)


func _draw_fighter(side: int) -> void:
	var state := runtime.states[side]
	var origin := Vector2(roundi(state.x_fp / 256.0), definition.ground_y - roundi(state.height_fp / 256.0))
	var sheet := _fighter_sheet(side)
	var frame := _fighter_frame(state)
	draw_set_transform(origin, 0.0, Vector2(state.facing, 1))
	draw_texture_rect_region(
		sheet,
		Rect2(-12, -32, 24, 32),
		Rect2(frame * 24, 0, 24, 32)
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _fighter_sheet(side: int) -> Texture2D:
	if side == 0:
		return REIMU_SHEET_INVERTED if _profile.is_inverted else REIMU_SHEET
	return MARISA_SHEET_INVERTED if _profile.is_inverted else MARISA_SHEET


func _fighter_frame(state: FighterState) -> int:
	if state.visual_pose == &"idle":
		return floori(runtime.encounter_tick / 10.0) % 4
	if state.visual_pose in [&"jump", &"guard"] or state.velocity_x_fp != 0:
		return 4 + floori(runtime.encounter_tick / 5.0) % 8
	return 12 + floori(state.move_tick / 3.0) % 4


func _draw_combat_boxes(foreground: Color) -> void:
	for side: int in range(2):
		var hurtbox := runtime.current_hurtbox(side)
		_draw_dashed_rect(Rect2(hurtbox), foreground)
		var hitbox := runtime.current_hitbox(side)
		if hitbox.size != Vector2i.ZERO:
			draw_rect(Rect2(hitbox), foreground, false, 2.0)
	var font := _font()
	draw_string(font, Vector2(8, 50), _catalog.text(&"ui.fighter.hitbox", _locale), HORIZONTAL_ALIGNMENT_LEFT, 70, 6, foreground)
	draw_string(font, Vector2(82, 50), _catalog.text(&"ui.fighter.hurtbox", _locale), HORIZONTAL_ALIGNMENT_LEFT, 70, 6, foreground)


func _draw_dashed_rect(rect: Rect2, color: Color) -> void:
	for x: int in range(roundi(rect.position.x), roundi(rect.end.x), 3):
		draw_rect(Rect2(x, rect.position.y, 2, 1), color)
		draw_rect(Rect2(x, rect.end.y - 1, 2, 1), color)
	for y: int in range(roundi(rect.position.y), roundi(rect.end.y), 3):
		draw_rect(Rect2(rect.position.x, y, 1, 2), color)
		draw_rect(Rect2(rect.end.x - 1, y, 1, 2), color)


func _draw_footer(foreground: Color, background: Color) -> void:
	draw_rect(FOOTER_FRAME, background)
	draw_rect(FOOTER_FRAME, foreground, false, 1.0)
	var mode_key := &"ui.fighter.mode.simple" if runtime.assists.simple_inputs else &"ui.fighter.mode.motion"
	draw_string(_font(), Vector2(8, 164), _catalog.text(&"ui.fighter.controls", _locale), HORIZONTAL_ALIGNMENT_CENTER, 304, 6, foreground)
	draw_string(_font(), Vector2(8, 173), "%s · %d%%" % [_catalog.text(mode_key, _locale), runtime.assists.speed_percent], HORIZONTAL_ALIGNMENT_CENTER, 304, 6, foreground)


func _draw_intro(foreground: Color, background: Color) -> void:
	var font := _font()
	draw_rect(Rect2(29, 60, 262, 67), background)
	draw_rect(Rect2(29, 60, 262, 67), foreground, false, 2.0)
	draw_string(font, Vector2(36, 76), _catalog.text(&"ui.fighter.terms.title", _locale), HORIZONTAL_ALIGNMENT_CENTER, 248, 9, foreground)
	draw_string(font, Vector2(36, 91), _catalog.text(&"ui.fighter.intro.rule", _locale), HORIZONTAL_ALIGNMENT_CENTER, 248, 7, foreground)
	var lines := PixelTextWrapper.wrap(_catalog.text(&"ui.fighter.intro.objective", _locale), font, 240, 7, _locale, 2)
	for index: int in range(lines.size()):
		draw_string(font, Vector2(40, 108 + index * 9), lines[index], HORIZONTAL_ALIGNMENT_CENTER, 240, 7, foreground)


func _draw_break_banner(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(55, 72, 210, 38), background)
	draw_rect(Rect2(55, 72, 210, 38), foreground, false, 2.0)
	draw_string(_font(), Vector2(61, 89), _catalog.text(&"ui.fighter.break", _locale), HORIZONTAL_ALIGNMENT_CENTER, 198, 10, foreground)
	draw_string(_font(), Vector2(61, 102), _catalog.text(&"ui.fighter.cue.spell_break", _locale), HORIZONTAL_ALIGNMENT_CENTER, 198, 7, foreground)


func _draw_visual_cue(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(86, 116, 148, 14), background)
	draw_rect(Rect2(86, 116, 148, 14), foreground, false, 1.0)
	draw_string(_font(), Vector2(90, 126), _catalog.text(_visual_cue_key, _locale), HORIZONTAL_ALIGNMENT_CENTER, 140, 7, foreground)


func _draw_pause(foreground: Color, background: Color) -> void:
	var font := _font()
	draw_rect(Rect2(68, 48, 184, 100), background)
	draw_rect(Rect2(68, 48, 184, 100), foreground, false, 2.0)
	draw_string(font, Vector2(75, 64), _catalog.text(&"ui.fighter.paused", _locale), HORIZONTAL_ALIGNMENT_CENTER, 170, 8, foreground)
	var keys: Array[StringName] = [
		&"ui.fighter.pause.resume", &"ui.fighter.pause.retry",
		&"ui.fighter.pause.accept_loss", &"ui.fighter.pause.training",
	]
	for index: int in range(keys.size()):
		var rect := Rect2(82, 72 + index * 18, 156, 15)
		draw_rect(rect, foreground, false, 1.0)
		if index == _pause_focus:
			draw_rect(rect.grow(-2), foreground, false, 1.0)
		draw_string(font, Vector2(86, rect.position.y + 11), _catalog.text(keys[index], _locale), HORIZONTAL_ALIGNMENT_CENTER, 148, 7, foreground)


func _draw_training(foreground: Color, background: Color) -> void:
	var font := _font()
	draw_rect(Rect2(7, 43, 306, 107), background)
	draw_rect(Rect2(7, 43, 306, 107), foreground, false, 2.0)
	draw_string(font, Vector2(12, 55), _catalog.text(&"ui.fighter.training.title", _locale), HORIZONTAL_ALIGNMENT_CENTER, 296, 7, foreground)
	var tabs: Array[StringName] = [
		&"ui.fighter.training.commands", &"ui.fighter.training.dummy",
		&"ui.fighter.training.display", &"ui.fighter.training.reset",
	]
	for index: int in range(tabs.size()):
		var rect := Rect2(12 + index * 73, 59, 70, 13)
		draw_rect(rect, foreground, false, 1.0)
		if index == _training_tab:
			draw_rect(rect.grow(-2), foreground, false, 1.0)
		draw_string(font, Vector2(rect.position.x + 2, 69), _catalog.text(tabs[index], _locale), HORIZONTAL_ALIGNMENT_CENTER, 66, 6, foreground)
	var command_keys: Array[StringName] = [
		&"ui.fighter.command.move", &"ui.fighter.command.jump", &"ui.fighter.command.light",
		&"ui.fighter.command.heavy", &"ui.fighter.command.skill", &"ui.fighter.command.skill_forward",
		&"ui.fighter.command.spell", &"ui.fighter.command.guard", &"ui.fighter.command.pause",
	]
	for index: int in range(command_keys.size()):
		draw_string(font, Vector2(14, 80 + index * 7), _catalog.text(command_keys[index], _locale), HORIZONTAL_ALIGNMENT_LEFT, 132, 6, foreground)
	draw_line(Vector2(151, 76), Vector2(151, 143), foreground, 1.0)
	var state := runtime.states[0]
	var move := definition.fighters[0].move_by_id(state.current_move_id)
	draw_string(font, Vector2(157, 84), "FRAME %03d" % runtime.encounter_tick, HORIZONTAL_ALIGNMENT_LEFT, 148, 7, foreground)
	draw_string(font, Vector2(157, 95), String(state.current_move_id if state.current_move_id != &"" else &"IDLE"), HORIZONTAL_ALIGNMENT_LEFT, 148, 6, foreground)
	if move != null:
		draw_string(font, Vector2(157, 105), "S %02d  A %02d  R %02d" % [move.startup_ticks, move.active_ticks, move.recovery_ticks], HORIZONTAL_ALIGNMENT_LEFT, 148, 6, foreground)
	draw_string(font, Vector2(157, 116), _catalog.text(&"ui.fighter.training.hitboxes", _locale), HORIZONTAL_ALIGNMENT_LEFT, 148, 6, foreground)
	draw_string(font, Vector2(157, 127), _catalog.text(&"ui.fighter.training.frame_step", _locale), HORIZONTAL_ALIGNMENT_LEFT, 148, 6, foreground)
	draw_string(font, Vector2(157, 138), _catalog.text(&"ui.fighter.training.reset_position", _locale), HORIZONTAL_ALIGNMENT_LEFT, 148, 6, foreground)
	draw_string(font, Vector2(12, 148), "%s  %s" % [_catalog.text(&"ui.fighter.training.input_history", _locale), _input_history_text()], HORIZONTAL_ALIGNMENT_LEFT, 294, 6, foreground)


func _input_history_text() -> String:
	var labels := PackedStringArray()
	for code: int in _input_history:
		var frame := FighterInputFrame.decode(code)
		var label := "·"
		if frame.light_pressed:
			label = "L"
		elif frame.heavy_pressed:
			label = "H"
		elif frame.skill_pressed:
			label = "K"
		elif frame.spell_pressed:
			label = "S"
		elif frame.guard_held:
			label = "G"
		elif frame.horizontal_axis != 0:
			label = ">" if frame.horizontal_axis > 0 else "<"
		labels.append(label)
	return " ".join(labels)


func _draw_resume_countdown(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(132, 78, 56, 42), background)
	draw_rect(Rect2(132, 78, 56, 42), foreground, false, 2.0)
	draw_string(_font(), Vector2(137, 109), str(_resume_countdown_ticks), HORIZONTAL_ALIGNMENT_CENTER, 46, 24, foreground)


func _draw_result(foreground: Color, background: Color) -> void:
	var font := _font()
	draw_rect(Rect2(24, 24, 272, 132), background)
	draw_rect(Rect2(24, 24, 272, 132), foreground, false, 2.0)
	var tag := final_result.result_tag
	var title_key := StringName("ui.fighter.result.%s.title" % tag)
	var reason_key := StringName("ui.fighter.result.%s.reason" % tag)
	draw_string(font, Vector2(32, 42), _catalog.text(title_key, _locale), HORIZONTAL_ALIGNMENT_CENTER, 256, 9, foreground)
	_draw_result_seals(Vector2(160, 68), foreground, background)
	var lines := PixelTextWrapper.wrap(_catalog.text(reason_key, _locale), font, 240, 7, _locale, 2)
	for index: int in range(lines.size()):
		draw_string(font, Vector2(40, 99 + index * 9), lines[index], HORIZONTAL_ALIGNMENT_CENTER, 240, 7, foreground)
	draw_string(font, Vector2(36, 132), _catalog.text(&"ui.fighter.result.continue", _locale), HORIZONTAL_ALIGNMENT_LEFT, 170, 7, foreground)
	draw_string(font, Vector2(176, 144), _catalog.text(&"ui.fighter.result.retry", _locale), HORIZONTAL_ALIGNMENT_RIGHT, 108, 7, foreground)


func _draw_result_seals(origin: Vector2, foreground: Color, background: Color) -> void:
	for index: int in range(2):
		var rect := Rect2(origin.x - 26 + index * 30, origin.y - 12, 24, 24)
		draw_rect(rect, foreground, false, 2.0)
		if final_result.result_tag == &"win":
			draw_rect(rect.grow(-6), foreground)
			draw_rect(rect.grow(-10), background)
		else:
			draw_line(rect.position + Vector2(5, 5), rect.end - Vector2(5, 5), foreground, 2.0)
			draw_line(Vector2(rect.end.x - 5, rect.position.y + 5), Vector2(rect.position.x + 5, rect.end.y - 5), foreground, 2.0)


func _fighter_name(side: int) -> String:
	# Resolve the autoload through the tree so direct SceneTree test scripts do
	# not depend on autoload identifiers being registered before scene parsing.
	var database := get_node_or_null("/root/ContentDB")
	var record: CharacterRecord = (
		database.character(definition.fighters[side].character_id)
		if database != null
		else null
	)
	return record.display_name(_locale) if record != null else String(definition.fighters[side].id).get_slice(".", 1).to_upper()


func _font() -> Font:
	return _japanese_font if _locale == &"ja" else _latin_font
