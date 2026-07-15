class_name BoundaryStainMode
extends GameMode
## One-bit story danmaku shell backed by the deterministic packed simulation.

const FIXED_DELTA := 1.0 / float(BoundaryStainSimulation.TICKS_PER_SECOND)
const START_RELEASE_TICKS := 3
const FIELD_TITLE_FRAME := Rect2(4, 2, 224, 11)
const FIELD_FRAME := Rect2(4, 13, 224, 151)
const FIELD_ORIGIN := Vector2(4, 13)
const FIELD_SIZE := Vector2(224, 151)
const RAIL_FRAME := Rect2(228, 4, 88, 160)
const FOOTER_FRAME := Rect2(4, 165, 312, 13)
const ACTION_CONTRACT := [
	"move",
	"shot",
	"focus",
	"bomb",
	"companion",
	"pause",
	"confirm",
	"cancel",
]

@export_enum("live", "spell", "phase1", "focus", "bomb", "phase2", "phase3", "paused", "result", "loss", "assist_clear", "stress") var fixture_state: String = "live"
@export_enum("100", "85", "70", "55") var fixture_density: String = "100"
@export_file("*.json") var pattern_path := "res://content/danmaku/boundary_stain.json"
@export var default_mode_id: StringName = &"danmaku.hkr.boundary_stain"
@export var default_event_id: StringName = &"evt.hkr.offerings_without_owners"
@export var pause_title_key: StringName = &"ui.danmaku.paused"
@export var result_text_prefix := "ui.danmaku.result"
@export var teaching_keys: Array[StringName] = [
	&"ui.danmaku.boundary.teach.amulet",
	&"ui.danmaku.boundary.teach.offering",
	&"ui.danmaku.boundary.teach.memory",
]

var host := DanmakuHost.new()
var runtime: BoundaryStainSimulation
var definition: DanmakuPatternDefinition
var assist_settings := DanmakuAssistSettings.new()
var final_result: ModeResult

var _profile: PresentationProfile = PresentationProfileRegistry.resolve(&"D")
var _locale: StringName = &"en"
var _catalog := UiTextCatalog.new()
var _latin_font: Font
var _japanese_font: Font
var _batch_renderer := DanmakuBulletBatchRenderer.new()
var _fixed_accumulator: float = 0.0
var _intro_ticks_remaining: int = 60
var _tutorial_waiting: bool = true
var _start_release_ticks: int = 0
var _bomb_queued: bool = false
var _margin_queued: bool = false
var _pause_focus: int = 0
var _resume_countdown_ticks: int = 0
var _completion_emitted: bool = false
var _fixture_frozen: bool = false
var _visual_cue_key: StringName
var _visual_cue_seconds: float = 0.0
var _border_pulse_seconds: float = 0.0
var _is_reduced_motion: bool = false
var _is_safe_flash: bool = false
var _no_flash_active: bool = false
var _last_shot_held: bool = false

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


func configure_assists(settings: DanmakuAssistSettings) -> void:
	assist_settings = settings.duplicate_settings() if settings != null else DanmakuAssistSettings.new()
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
		if _tutorial_waiting:
			pass
		elif _start_release_ticks > 0:
			if Input.is_action_pressed(GameInput.CONFIRM) or Input.is_action_pressed(GameInput.SHOT):
				_start_release_ticks = START_RELEASE_TICKS
			else:
				_start_release_ticks -= 1
		elif _resume_countdown_ticks > 0:
			_resume_countdown_ticks -= 1
		elif _intro_ticks_remaining > 0:
			_intro_ticks_remaining -= 1
		else:
			var frame := DanmakuInputFrame.new()
			frame.horizontal_axis = roundi(Input.get_axis(GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT))
			frame.vertical_axis = roundi(Input.get_axis(GameInput.MOVE_UP, GameInput.MOVE_DOWN))
			frame.focus_held = Input.is_action_pressed(GameInput.FOCUS)
			frame.shot_held = Input.is_action_pressed(GameInput.SHOT)
			frame.bomb_pressed = _bomb_queued
			frame.margin_pressed = _margin_queued
			_bomb_queued = false
			_margin_queued = false
			_step_runtime(frame)
		_fixed_accumulator -= FIXED_DELTA
	queue_redraw()


func _process(delta: float) -> void:
	_visual_cue_seconds = maxf(0.0, _visual_cue_seconds - maxf(0.0, delta))
	_border_pulse_seconds = maxf(0.0, _border_pulse_seconds - maxf(0.0, delta))
	queue_redraw()


func handle_semantic_action(action: StringName) -> bool:
	if runtime == null:
		return false
	if final_result != null:
		if action == GameInput.CONFIRM:
			_emit_completion_once()
			return true
		if action == GameInput.CANCEL:
			_retry_phase()
			return true
		return false
	if runtime.is_paused:
		return _handle_pause_action(action)
	if _tutorial_waiting:
		if action == GameInput.CONFIRM:
			_tutorial_waiting = false
			_start_release_ticks = START_RELEASE_TICKS
			_intro_ticks_remaining = 0
			queue_redraw()
			return true
		if action in [GameInput.PAUSE, GameInput.CANCEL]:
			host.toggle_pause()
			_pause_focus = 0
			queue_redraw()
			return true
		return action in [
			GameInput.SHOT, GameInput.FOCUS, GameInput.BOMB, GameInput.COMPANION,
			GameInput.MOVE_UP, GameInput.MOVE_DOWN, GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT,
		]
	if action == GameInput.BOMB:
		_bomb_queued = true
		return true
	if action == GameInput.COMPANION:
		_margin_queued = true
		return true
	if action in [GameInput.PAUSE, GameInput.CANCEL]:
		host.toggle_pause()
		_pause_focus = 0
		queue_redraw()
		return true
	return false


func step_fixture(ticks: int, frame: DanmakuInputFrame = null) -> ModeResult:
	var sample := frame if frame != null else DanmakuInputFrame.new()
	var result: ModeResult
	for _tick: int in range(maxi(0, ticks)):
		result = _step_runtime(sample)
		if result != null:
			break
	queue_redraw()
	return result


func pause_for_test() -> void:
	host.toggle_pause()
	_pause_focus = 0
	queue_redraw()


func retry_phase_for_test() -> void:
	_retry_phase()


func accept_loss_for_test() -> ModeResult:
	return host.accept_loss()


func assist_clear_for_test() -> ModeResult:
	return host.assist_clear()


func action_contract() -> PackedStringArray:
	return PackedStringArray(ACTION_CONTRACT)


func resolve_input_candidates(candidates: Array[StringName]) -> StringName:
	if _tutorial_waiting:
		return GameInput.first_matching(candidates, [
			GameInput.CONFIRM, GameInput.SHOT, GameInput.FOCUS, GameInput.BOMB,
			GameInput.COMPANION, GameInput.PAUSE, GameInput.CANCEL,
		])
	if final_result != null or (runtime != null and runtime.is_paused):
		return GameInput.first_matching(candidates, [
			GameInput.MOVE_UP, GameInput.MOVE_DOWN, GameInput.CONFIRM,
			GameInput.CANCEL, GameInput.PAUSE,
		])
	return GameInput.first_matching(candidates, [
		GameInput.PAUSE,
		GameInput.SHOT,
		GameInput.FOCUS,
		GameInput.BOMB,
		GameInput.COMPANION,
		GameInput.MOVE_UP,
		GameInput.MOVE_DOWN,
		GameInput.MOVE_LEFT,
		GameInput.MOVE_RIGHT,
		GameInput.CONFIRM,
		GameInput.CANCEL,
	])


func current_result() -> ModeResult:
	return final_result


func state_snapshot() -> String:
	return runtime.canonical_snapshot() if runtime != null else ""


func is_paused_state() -> bool:
	return runtime != null and runtime.is_paused


func resolved_profile_id() -> StringName:
	return _profile.profile_id


func rendered_bullet_count() -> int:
	return _batch_renderer.rendered_bullet_count


func capture_debug_state() -> Dictionary:
	var debug := super.capture_debug_state()
	debug.merge({
		"pattern_id": String(definition.id) if definition != null else "",
		"phase": runtime.state.phase_index if runtime != null else -1,
		"phase_tick": runtime.state.phase_tick if runtime != null else -1,
		"bullets": runtime.pool.active_count if runtime != null else 0,
		"committed": runtime.pool.committed_count if runtime != null else 0,
		"pool_capacity": runtime.pool.capacity if runtime != null else 0,
		"intro_ticks": _intro_ticks_remaining,
		"tutorial_waiting": _tutorial_waiting,
		"start_release_ticks": _start_release_ticks,
		"resume_countdown_ticks": _resume_countdown_ticks,
		"paused": runtime.is_paused if runtime != null else false,
		"no_flash": _no_flash_active,
		"flash_border_active": _border_pulse_seconds > 0.0,
		"flash_border_seconds": _border_pulse_seconds,
		"result": String(final_result.result_tag) if final_result != null else "",
	}, true)
	return debug


func _default_context() -> ModeContext:
	var context := ModeContext.new()
	context.mode_type = &"start_danmaku"
	context.mode_id = default_mode_id
	context.event_id = default_event_id
	context.node_id = &"n_danmaku"
	context.deterministic_seed = 7070
	return context


func _load_runtime() -> void:
	var loader := DanmakuPatternLoader.new()
	definition = loader.load_path(pattern_path)
	if definition == null or not loader.errors.is_empty():
		push_error("Danmaku pattern could not load: %s" % [loader.errors])
		return
	var settings := _resolved_assists()
	_no_flash_active = settings.no_flash
	host = DanmakuHost.new()
	host.result_ready.connect(_on_result_ready)
	host.phase_checkpoint.connect(_on_phase_checkpoint)
	runtime = BoundaryStainSimulation.new()
	var capacity := 2500 if fixture_state == "stress" else 512
	if not host.load_encounter(runtime, definition, mode_context, settings, capacity):
		push_error("Danmaku runtime rejected its configuration")
		return
	final_result = null
	_fixed_accumulator = 0.0
	_tutorial_waiting = fixture_state == "live"
	_start_release_ticks = 0
	_intro_ticks_remaining = 0 if _tutorial_waiting else 60
	_bomb_queued = false
	_margin_queued = false
	_pause_focus = 0
	_resume_countdown_ticks = 0
	_completion_emitted = false
	_visual_cue_key = &""
	_visual_cue_seconds = 0.0
	_border_pulse_seconds = 0.0
	_last_shot_held = false
	_fixture_frozen = fixture_state != "live"
	_prepare_fixture_state()
	queue_redraw()


func _resolved_assists() -> DanmakuAssistSettings:
	var settings := assist_settings.duplicate_settings()
	if fixture_state != "live":
		settings.density_percent = int(fixture_density)
	settings.no_flash = settings.no_flash or _is_safe_flash
	if fixture_state in ["phase3", "result", "assist_clear"]:
		settings.safe_lane_preview = true
		settings.auto_bomb = true
		settings.larger_graze_radius = true
	if fixture_state == "stress":
		settings.story_mode = false
	return settings


func _prepare_fixture_state() -> void:
	if runtime == null:
		return
	var held := _fixture_input(0, 0, true, true)
	match fixture_state:
		"spell":
			_intro_ticks_remaining = 60
		"phase1":
			_intro_ticks_remaining = 0
			step_fixture(150, _fixture_input(0, 0, false, true))
		"focus":
			_intro_ticks_remaining = 0
			step_fixture(170, held)
		"bomb":
			_intro_ticks_remaining = 0
			step_fixture(165, held)
			var bomb := held.duplicate_frame()
			bomb.bomb_pressed = true
			_step_runtime(bomb)
		"phase2":
			_intro_ticks_remaining = 0
			step_fixture(510, held)
			_intro_ticks_remaining = 0
			_visual_cue_seconds = 0.0
		"phase3":
			_intro_ticks_remaining = 0
			step_fixture(720, held)
			step_fixture(28, _fixture_input(1, 0, true, true))
			step_fixture(120, held)
			_intro_ticks_remaining = 0
			_visual_cue_seconds = 0.0
		"paused":
			_intro_ticks_remaining = 0
			step_fixture(165, held)
			host.toggle_pause()
		"result":
			_intro_ticks_remaining = 0
			step_fixture(720, held)
			step_fixture(28, _fixture_input(1, 0, true, true))
			step_fixture(332, held)
		"loss":
			_intro_ticks_remaining = 0
			host.accept_loss()
		"assist_clear":
			_intro_ticks_remaining = 0
			host.defeat_count = 3
			host.assist_clear()
		"stress":
			_intro_ticks_remaining = 0
			_prepare_stress_pool()


func _fixture_input(
	horizontal: int,
	vertical: int,
	focus: bool,
	shot: bool
) -> DanmakuInputFrame:
	var frame := DanmakuInputFrame.new()
	frame.horizontal_axis = horizontal
	frame.vertical_axis = vertical
	frame.focus_held = focus
	frame.shot_held = shot
	return frame


func _prepare_stress_pool() -> void:
	runtime.pool.clear(true)
	for index: int in range(2500):
		var spec := DanmakuBulletSpec.new()
		spec.x_fp = (4 + (index % 100) * 2) * 256
		spec.y_fp = (4 + (floori(index / 100.0) % 25) * 5) * 256
		spec.velocity_y_fp = 1
		spec.telegraph_ticks = 1
		spec.lifetime_ticks = 600
		spec.family = index % 3
		spec.polarity = index % 2
		runtime.pool.spawn(spec)
	runtime.pool.step(definition.arena_width * 256, definition.arena_height * 256)


func _step_runtime(frame: DanmakuInputFrame) -> ModeResult:
	_last_shot_held = frame.shot_held
	var previous_graze := runtime.state.graze_count
	var previous_bombs := runtime.state.bombs_used
	var result := host.step(frame)
	if runtime.state.graze_count > previous_graze and runtime.state.graze_count % 5 == 1:
		_show_cue(&"ui.danmaku.visual.graze", &"sfx.danmaku.graze", 620.0, 0.045)
	if runtime.state.bombs_used > previous_bombs:
		_show_cue(&"ui.danmaku.visual.bomb", &"sfx.danmaku.bomb", 170.0, 0.18)
		_border_pulse_seconds = 0.0 if _no_flash_active else 0.24
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
		queue_redraw()
		return true
	if action != GameInput.CONFIRM:
		return false
	match _pause_focus:
		0:
			_resume_from_pause()
		1:
			_retry_phase()
		2:
			host.accept_loss()
		3:
			if host.can_assist_clear():
				host.assist_clear()
	queue_redraw()
	return true


func _resume_from_pause() -> void:
	host.toggle_pause()
	_resume_countdown_ticks = 3


func _retry_phase() -> void:
	host.retry_phase()
	final_result = null
	_fixed_accumulator = 0.0
	_intro_ticks_remaining = 24
	_tutorial_waiting = false
	_start_release_ticks = 0
	_bomb_queued = false
	_margin_queued = false
	_resume_countdown_ticks = 0
	_completion_emitted = false
	_visual_cue_key = &""
	_visual_cue_seconds = 0.0
	_border_pulse_seconds = 0.0
	_last_shot_held = false
	queue_redraw()


func _on_phase_checkpoint(_checkpoint: String) -> void:
	checkpoint_requested.emit(&"danmaku_phase")
	_intro_ticks_remaining = 24


func _on_result_ready(result: ModeResult) -> void:
	final_result = result
	checkpoint_requested.emit(&"danmaku_result")
	_show_cue(
		&"ui.danmaku.visual.bomb" if result.result_tag == &"clear" else &"ui.danmaku.telegraph",
		&"sfx.danmaku.result",
		480.0 if result.result_tag == &"clear" else 220.0,
		0.16
	)
	queue_redraw()


func _show_cue(key: StringName, cue_id: StringName, pitch: float, duration: float) -> void:
	_visual_cue_key = key
	_visual_cue_seconds = 0.8
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
	_draw_field_shell(foreground, background)
	_batch_renderer.draw_safe_lane(self, runtime, FIELD_ORIGIN, FIELD_SIZE, foreground)
	_batch_renderer.draw_field(self, runtime, FIELD_ORIGIN, FIELD_SIZE, foreground, background)
	_draw_boss_and_player(foreground, background)
	_draw_status_rail(foreground, background)
	if _tutorial_waiting or _intro_ticks_remaining > 0:
		_draw_intro(foreground, background)
	if _resume_countdown_ticks > 0:
		_draw_resume_countdown(foreground, background)
	if _visual_cue_seconds > 0.0:
		_draw_visual_cue(foreground, background)
	if runtime.is_paused:
		_draw_pause(foreground, background)


func _draw_field_shell(foreground: Color, background: Color) -> void:
	draw_rect(FIELD_FRAME, background)
	draw_rect(FIELD_FRAME, foreground, false, 1.0)
	draw_rect(FIELD_TITLE_FRAME, background)
	draw_rect(FIELD_TITLE_FRAME, foreground, false, 1.0)
	draw_rect(RAIL_FRAME, background)
	draw_rect(RAIL_FRAME, foreground, false, 1.0)
	draw_rect(FOOTER_FRAME, background)
	draw_rect(FOOTER_FRAME, foreground, false, 1.0)
	if not runtime.state.focus_held and runtime.assists.background_dim_percent < 80:
		# Sparse shrine geometry never shares the bullets' compact frequency.
		draw_line(Vector2(22, 151), Vector2(210, 151), foreground, 1.0)
		draw_line(Vector2(34, 151), Vector2(34, 119), foreground, 1.0)
		draw_line(Vector2(198, 151), Vector2(198, 119), foreground, 1.0)
		draw_line(Vector2(26, 122), Vector2(206, 122), foreground, 1.0)
	var font := _font()
	draw_string(font, Vector2(8, 11), _catalog.text(runtime.current_phase().title_key, _locale), HORIZONTAL_ALIGNMENT_LEFT, 190, _hud_font_size(), foreground)
	draw_string(_latin_font, Vector2(198, 11), "%d/3" % (runtime.state.phase_index + 1), HORIZONTAL_ALIGNMENT_RIGHT, 24, 7, foreground)
	var controls := "%s %s  %s %s  %s %s" % [
		_movement_binding(), _catalog.text(&"ui.minigame.time_grid.select", _locale),
		input_binding(GameInput.CONFIRM), _catalog.text(&"ui.common.confirm", _locale),
		input_binding(GameInput.CANCEL), _catalog.text(&"ui.common.cancel", _locale),
	] if runtime.is_paused else " ".join([
		input_hint(GameInput.SHOT, _catalog.text(&"ui.input.shot", _locale)),
		input_hint(GameInput.FOCUS, _catalog.text(&"ui.input.focus", _locale)),
		input_hint(GameInput.BOMB, _catalog.text(&"ui.input.bomb", _locale)),
		input_hint(GameInput.COMPANION, _catalog.text(&"ui.input.margin", _locale)),
		"%s %s" % [_compact_pause_binding(), _catalog.text(&"ui.input.pause", _locale)],
	])
	draw_string(font, Vector2(8, 176), controls, HORIZONTAL_ALIGNMENT_CENTER, 304, _hud_font_size(), foreground)
	if _border_pulse_seconds > 0.0 and not _no_flash_active:
		draw_rect(FIELD_FRAME.grow(-2), foreground, false, 2.0)


func _draw_boss_and_player(foreground: Color, background: Color) -> void:
	var boss := Vector2(116, 28)
	var player := _display_position(runtime.state.player_x_fp, runtime.state.player_y_fp)
	if _last_shot_held:
		for y: int in range(roundi(boss.y + 7), roundi(player.y - 6), 6):
			draw_line(Vector2(player.x, y), Vector2(player.x, mini(y + 2, player.y - 6)), foreground, 1.0)
	draw_rect(Rect2(boss - Vector2(5, 2), Vector2(11, 5)), foreground, false, 1.0)
	draw_rect(Rect2(boss - Vector2(1, 4), Vector2(3, 9)), foreground, false, 1.0)
	draw_rect(Rect2(player - Vector2(2, 3), Vector2(5, 6)), foreground, false, 1.0)
	draw_rect(Rect2(player + Vector2(-4, 3), Vector2(9, 2)), foreground)
	draw_rect(Rect2(player + Vector2(-1, -5), Vector2(3, 2)), foreground)
	if runtime.state.focus_held:
		draw_rect(Rect2(player - Vector2(4, 4), Vector2(9, 9)), foreground, false, 1.0)
		draw_rect(Rect2(player, Vector2(2, 2)), foreground)
		draw_rect(Rect2(player + Vector2(1, 1), Vector2.ONE), background)


func _draw_status_rail(foreground: Color, background: Color) -> void:
	var font := _font()
	var title_lines := PixelTextWrapper.wrap(_catalog.text(definition.title_key, _locale), font, 80, _hud_font_size(), _locale, 2)
	for index: int in range(title_lines.size()):
		draw_string(font, Vector2(232, 15 + index * 12), title_lines[index], HORIZONTAL_ALIGNMENT_CENTER, 80, _hud_font_size(), foreground)
	_draw_gauge(Rect2(234, 30, 76, 6), runtime.state.boss_integrity, runtime.state.boss_integrity_max, foreground, background)
	draw_string(font, Vector2(233, 50), _catalog.text(&"ui.danmaku.life", _locale), HORIZONTAL_ALIGNMENT_LEFT, 34, _hud_font_size(), foreground)
	for index: int in range(3):
		draw_circle(Vector2(278 + index * 9, 46), 3, foreground if index < runtime.state.lives else background)
		draw_circle(Vector2(278 + index * 9, 46), 3, foreground, false, 1.0)
	draw_string(font, Vector2(233, 65), _catalog.text(&"ui.danmaku.bomb", _locale), HORIZONTAL_ALIGNMENT_LEFT, 34, _hud_font_size(), foreground)
	for index: int in range(2):
		var bomb_rect := Rect2(279 + index * 12, 56, 8, 8)
		if index < runtime.state.bombs:
			draw_rect(bomb_rect, foreground)
		else:
			draw_rect(bomb_rect, foreground, false, 1.0)
	var remaining := maxi(0, runtime.current_phase().duration_ticks - runtime.state.phase_tick)
	draw_string(font, Vector2(233, 81), "%s %02d" % [_catalog.text(&"ui.danmaku.time", _locale), ceili(remaining / 60.0)], HORIZONTAL_ALIGNMENT_LEFT, 78, _hud_font_size(), foreground)
	draw_string(font, Vector2(233, 95), "%s %03d" % [_catalog.text(&"ui.danmaku.graze", _locale), runtime.state.graze_count], HORIZONTAL_ALIGNMENT_LEFT, 78, _hud_font_size(), foreground)
	draw_string(font, Vector2(233, 109), _catalog.text(&"ui.danmaku.score", _locale), HORIZONTAL_ALIGNMENT_LEFT, 78, _hud_font_size(), foreground)
	draw_string(font, Vector2(233, 121), "%07d" % runtime.state.score, HORIZONTAL_ALIGNMENT_RIGHT, 78, _hud_font_size(), foreground)
	draw_string(font, Vector2(233, 134), _catalog.text(&"ui.danmaku.margin", _locale), HORIZONTAL_ALIGNMENT_LEFT, 78, _hud_font_size(), foreground)
	_draw_gauge(Rect2(234, 138, 76, 7), runtime.state.margin, BoundaryStainSimulation.MAX_MARGIN, foreground, background)
	draw_string(font, Vector2(233, 158), "%d%% / %d%%" % [runtime.assists.density_percent, runtime.assists.bullet_speed_percent], HORIZONTAL_ALIGNMENT_CENTER, 78, _hud_font_size(), foreground)


func _draw_intro(foreground: Color, background: Color) -> void:
	var font := _font()
	if ui_scale_percent() > 100 and _tutorial_waiting:
		_draw_large_text_tutorial(font, foreground, background)
		return
	var panel := Rect2(10, 18, 212, 126) if _tutorial_waiting else Rect2(14, 31, 204, 82)
	draw_rect(panel, background)
	draw_rect(panel, foreground, false, 2.0)
	draw_string(font, Vector2(18, 37 if _tutorial_waiting else 43), _catalog.text(&"ui.danmaku.telegraph", _locale), HORIZONTAL_ALIGNMENT_CENTER, 196, _hud_font_size(), foreground)
	var title_lines := PixelTextWrapper.wrap(_catalog.text(runtime.current_phase().title_key, _locale), font, 196, _title_font_size(), _locale, 2)
	for index: int in range(title_lines.size()):
		draw_string(font, Vector2(18, (57 if _tutorial_waiting else 63) + index * _title_line_height()), title_lines[index], HORIZONTAL_ALIGNMENT_CENTER, 196, _title_font_size(), foreground)
	var teaching_key := _teaching_key()
	var teaching_lines := PixelTextWrapper.wrap(_catalog.text(teaching_key, _locale), font, 196, _body_font_size(), _locale, 2)
	for index: int in range(teaching_lines.size()):
		draw_string(font, Vector2(18, (84 if _tutorial_waiting else 94) + index * _body_line_height()), teaching_lines[index], HORIZONTAL_ALIGNMENT_CENTER, 196, _body_font_size(), foreground)
	if _tutorial_waiting:
		var move_hint := "%s %s" % [_movement_binding(), _catalog.text(&"ui.input.move", _locale)]
		draw_string(font, Vector2(18, 120), move_hint, HORIZONTAL_ALIGNMENT_CENTER, 196, _hud_font_size(), foreground)
		draw_string(font, Vector2(18, 139), input_hint(GameInput.CONFIRM, _catalog.text(&"ui.danmaku.tutorial.start", _locale)), HORIZONTAL_ALIGNMENT_CENTER, 196, _body_font_size(), foreground)


func _draw_large_text_tutorial(font: Font, foreground: Color, background: Color) -> void:
	draw_rect(Rect2(0, 0, 320, 180), background)
	draw_rect(Rect2(5, 5, 310, 170), foreground, false, 2.0)
	draw_string(font, Vector2(12, 23), _catalog.text(&"ui.danmaku.telegraph", _locale), HORIZONTAL_ALIGNMENT_CENTER, 296, _hud_font_size(), foreground)
	var title_lines := PixelTextWrapper.wrap(_catalog.text(runtime.current_phase().title_key, _locale), font, 290, _title_font_size(), _locale, 2)
	for index: int in range(title_lines.size()):
		draw_string(font, Vector2(15, 43 + index * _title_line_height()), title_lines[index], HORIZONTAL_ALIGNMENT_CENTER, 290, _title_font_size(), foreground)
	var teaching_key := _teaching_key()
	var teaching_lines := PixelTextWrapper.wrap(_catalog.text(teaching_key, _locale), font, 286, _body_font_size(), _locale, 2)
	for index: int in range(teaching_lines.size()):
		draw_string(font, Vector2(17, 69 + index * _body_line_height()), teaching_lines[index], HORIZONTAL_ALIGNMENT_CENTER, 286, _body_font_size(), foreground)
	draw_line(Vector2(14, 96), Vector2(306, 96), foreground, 1.0)
	var control_size := scaled_ui_pixels(7 if _locale == &"en" else 8)
	var move_hint := "%s %s" % [_movement_binding(), _catalog.text(&"ui.input.move", _locale)]
	draw_string(font, Vector2(16, 111), move_hint, HORIZONTAL_ALIGNMENT_CENTER, 288, control_size, foreground)
	draw_string(font, Vector2(16, 129), input_hint(GameInput.SHOT, _catalog.text(&"ui.input.shot", _locale)), HORIZONTAL_ALIGNMENT_CENTER, 140, control_size, foreground)
	draw_string(font, Vector2(164, 129), input_hint(GameInput.FOCUS, _catalog.text(&"ui.input.focus", _locale)), HORIZONTAL_ALIGNMENT_CENTER, 140, control_size, foreground)
	draw_string(font, Vector2(16, 147), input_hint(GameInput.BOMB, _catalog.text(&"ui.input.bomb", _locale)), HORIZONTAL_ALIGNMENT_CENTER, 140, control_size, foreground)
	draw_string(font, Vector2(164, 147), input_hint(GameInput.COMPANION, _catalog.text(&"ui.input.margin", _locale)), HORIZONTAL_ALIGNMENT_CENTER, 140, control_size, foreground)
	draw_string(font, Vector2(16, 169), input_hint(GameInput.CONFIRM, _catalog.text(&"ui.danmaku.tutorial.start", _locale)), HORIZONTAL_ALIGNMENT_CENTER, 288, control_size, foreground)


func _draw_visual_cue(foreground: Color, background: Color) -> void:
	var font := _font()
	draw_rect(Rect2(45, 95, 142, 18), background)
	draw_rect(Rect2(45, 95, 142, 18), foreground, false, 1.0)
	draw_string(font, Vector2(50, 109), _catalog.text(_visual_cue_key, _locale), HORIZONTAL_ALIGNMENT_CENTER, 132, _hud_font_size(), foreground)


func _draw_resume_countdown(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(91, 69, 58, 42), background)
	draw_rect(Rect2(91, 69, 58, 42), foreground, false, 2.0)
	draw_string(_font(), Vector2(96, 100), str(_resume_countdown_ticks), HORIZONTAL_ALIGNMENT_CENTER, 48, 24, foreground)


func _draw_pause(foreground: Color, background: Color) -> void:
	var font := _font()
	draw_rect(Rect2(12, 14, 208, 148), background)
	draw_rect(Rect2(12, 14, 208, 148), foreground, false, 2.0)
	draw_string(font, Vector2(20, 38), _catalog.text(pause_title_key, _locale), HORIZONTAL_ALIGNMENT_CENTER, 192, _title_font_size(), foreground)
	var keys: Array[StringName] = [
		&"ui.danmaku.pause.resume",
		&"ui.danmaku.pause.retry",
		&"ui.danmaku.pause.accept_loss",
		&"ui.danmaku.pause.assist_clear",
	]
	for index: int in range(keys.size()):
		var rect := Rect2(28, 48 + index * 26, 176, 21)
		draw_rect(rect, foreground, false, 1.0)
		if index == _pause_focus:
			draw_rect(rect.grow(-2), foreground, false, 1.0)
		var label := _catalog.text(keys[index], _locale)
		if index == 3 and not host.can_assist_clear():
			label = "%s / %s" % [label, _catalog.text(&"ui.danmaku.pause.assist_locked", _locale)]
		draw_string(font, Vector2(33, rect.position.y + 16), label, HORIZONTAL_ALIGNMENT_CENTER, 166, _body_font_size(), foreground)


func _draw_result(foreground: Color, background: Color) -> void:
	var font := _font()
	draw_rect(Rect2(14, 14, 292, 148), background)
	draw_rect(Rect2(14, 14, 292, 148), foreground, false, 2.0)
	var tag := final_result.result_tag
	var title_key := StringName("%s.%s.title" % [result_text_prefix, tag])
	var reason_key := StringName("%s.%s.reason" % [result_text_prefix, tag])
	draw_string(font, Vector2(24, 38), _catalog.text(title_key, _locale), HORIZONTAL_ALIGNMENT_CENTER, 272, _title_font_size(), foreground)
	_draw_result_stamp(Vector2(160, 67), tag, foreground, background)
	var reason_lines := PixelTextWrapper.wrap(_catalog.text(reason_key, _locale), font, 260, _body_font_size(), _locale, 2)
	for index: int in range(reason_lines.size()):
		draw_string(font, Vector2(30, 99 + index * _body_line_height()), reason_lines[index], HORIZONTAL_ALIGNMENT_CENTER, 260, _body_font_size(), foreground)
	draw_string(font, Vector2(30, 129), "%s %03d    %s %d" % [_catalog.text(&"ui.danmaku.graze", _locale), runtime.state.graze_count, _catalog.text(&"ui.danmaku.bombs_used", _locale), runtime.state.bombs_used], HORIZONTAL_ALIGNMENT_CENTER, 260, _hud_font_size(), foreground)
	draw_string(font, Vector2(26, 147), input_hint(GameInput.CONFIRM, _catalog.text(&"ui.danmaku.result.continue", _locale)), HORIZONTAL_ALIGNMENT_LEFT, 166, _hud_font_size(), foreground)
	draw_string(font, Vector2(176, 147), input_hint(GameInput.CANCEL, _catalog.text(&"ui.danmaku.result.retry", _locale)), HORIZONTAL_ALIGNMENT_RIGHT, 118, _hud_font_size(), foreground)


func _draw_result_stamp(origin: Vector2, tag: StringName, foreground: Color, background: Color) -> void:
	draw_rect(Rect2(origin - Vector2(15, 15), Vector2(30, 30)), foreground, false, 2.0)
	if tag == &"clear":
		draw_rect(Rect2(origin - Vector2(8, 8), Vector2(16, 16)), foreground)
		draw_rect(Rect2(origin - Vector2(2, 2), Vector2(4, 4)), background)
	elif tag == &"assist_clear":
		draw_line(origin + Vector2(-9, 0), origin + Vector2(9, 0), foreground, 2.0)
		draw_line(origin + Vector2(0, -9), origin + Vector2(0, 9), foreground, 2.0)
	else:
		draw_line(origin + Vector2(-8, -8), origin + Vector2(8, 8), foreground, 2.0)
		draw_line(origin + Vector2(8, -8), origin + Vector2(-8, 8), foreground, 2.0)


func _draw_gauge(
	rect: Rect2,
	value: int,
	maximum: int,
	foreground: Color,
	background: Color
) -> void:
	draw_rect(rect, foreground, false, 1.0)
	var ratio := clampf(value / float(maxi(1, maximum)), 0.0, 1.0)
	draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(floori((rect.size.x - 4) * ratio), rect.size.y - 4)), foreground)
	if ratio < 1.0:
		draw_rect(Rect2(rect.position + Vector2(2 + floori((rect.size.x - 4) * ratio), 2), Vector2(1, rect.size.y - 4)), background)


func _display_position(x_fp: int, y_fp: int) -> Vector2:
	return Vector2(
		FIELD_ORIGIN.x + roundi(x_fp / 256.0),
		FIELD_ORIGIN.y + roundi(y_fp / 256.0 * FIELD_SIZE.y / definition.arena_height)
	)


func _teaching_key() -> StringName:
	if runtime == null or teaching_keys.is_empty():
		return &"ui.danmaku.telegraph"
	return teaching_keys[clampi(runtime.state.phase_index, 0, teaching_keys.size() - 1)]


func _movement_binding() -> String:
	var glyph_service := get_node_or_null("/root/InputGlyphService")
	if glyph_service != null:
		return _catalog.text(glyph_service.glyph_key(GameInput.MOVE_UP), _locale)
	return "[ARROWS]"


func _compact_pause_binding() -> String:
	var binding := input_binding(GameInput.PAUSE)
	return "[ESC]" if binding == "[ESCAPE]" else binding


func _font() -> Font:
	return _japanese_font if _locale == &"ja" else _latin_font


func _body_font_size() -> int:
	if ui_scale_percent() > 100:
		return scaled_ui_pixels(10 if _locale == &"ja" else 7)
	return 12 if _locale == &"ja" else 7


func _body_line_height() -> int:
	return _body_font_size() + (4 if ui_scale_percent() > 100 else 2)


func _title_font_size() -> int:
	return scaled_ui_pixels(12 if _locale == &"ja" else 8) if ui_scale_percent() > 100 else (14 if _locale == &"ja" else 8)


func _title_line_height() -> int:
	return _title_font_size() + 2


func _hud_font_size() -> int:
	return 10 if _locale == &"ja" else 7
