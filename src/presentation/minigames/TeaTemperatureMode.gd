class_name TeaTemperatureMode
extends GameMode
## Shared minigame shell presenting the deterministic two-cup Tea Temperature runtime.

const ACTION_CONTRACT := [
	"move",
	"confirm",
	"cancel",
	"focus",
	"pause",
]
const FIXED_DELTA := 1.0 / float(TeaTemperatureSimulation.TICKS_PER_SECOND)

@export_enum("tutorial", "active", "paused", "result") var fixture_state: String = "tutorial"
@export_enum("none", "all") var fixture_assist_profile: String = "none"

var host := MinigameHost.new()
var tea := TeaTemperatureSimulation.new()
var assist_settings := MinigameAssistSettings.new()
var final_result: ModeResult

var _profile: PresentationProfile = PresentationProfileRegistry.resolve(&"A")
var _locale: StringName = &"en"
var _catalog := UiTextCatalog.new()
var _latin_font: Font
var _japanese_font: Font
var _fixed_accumulator: float = 0.0
var _pour_queued: bool = false
var _pause_focus: int = 0
var _completion_emitted: bool = false
var _visual_cue_key: StringName
var _visual_cue_seconds: float = 0.0

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
	# Visual rhythm stays static under reduced motion/safe flash; scoring is identical.
	if is_reduced_motion or is_safe_flash:
		_visual_cue_seconds = 0.0
	if is_node_ready():
		_load_runtime()


func configure_assists(settings: MinigameAssistSettings) -> void:
	assist_settings = settings.duplicate_settings() if settings != null else MinigameAssistSettings.new()
	if is_node_ready():
		_load_runtime()


func switch_locale(next_locale: StringName) -> void:
	if next_locale in [&"en", &"ja"]:
		_locale = next_locale
		queue_redraw()


func _physics_process(delta: float) -> void:
	if is_suspended or tea == null or tea.is_paused or tea.state.phase != TeaTemperatureState.Phase.ACTIVE:
		return
	_fixed_accumulator = minf(_fixed_accumulator + delta, FIXED_DELTA * 4.0)
	while _fixed_accumulator >= FIXED_DELTA:
		var frame := MinigameInputFrame.new()
		frame.heat_direction = roundi(Input.get_axis(GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT))
		frame.patience_held = Input.is_action_pressed(GameInput.FOCUS)
		frame.pour_pressed = _pour_queued
		_pour_queued = false
		host.step(frame)
		_fixed_accumulator -= FIXED_DELTA
	queue_redraw()


func _process(delta: float) -> void:
	_visual_cue_seconds = maxf(0.0, _visual_cue_seconds - maxf(0.0, delta))
	queue_redraw()


func handle_semantic_action(action: StringName) -> bool:
	if tea == null:
		return false
	if tea.is_paused:
		return _handle_pause_action(action)
	match tea.state.phase:
		TeaTemperatureState.Phase.TUTORIAL:
			if action == GameInput.CONFIRM:
				var start := MinigameInputFrame.new()
				start.confirm_pressed = true
				host.step(start)
				queue_redraw()
				return true
		TeaTemperatureState.Phase.ACTIVE:
			if action == GameInput.CONFIRM:
				_pour_queued = true
				return true
			if action in [GameInput.PAUSE, GameInput.CANCEL]:
				host.toggle_pause()
				_pause_focus = 0
				queue_redraw()
				return true
		TeaTemperatureState.Phase.RESULT:
			if action == GameInput.CONFIRM:
				_emit_completion_once()
				return true
			if action == GameInput.CANCEL:
				_retry_attempt()
				return true
	return false


func start_for_test() -> void:
	var frame := MinigameInputFrame.new()
	frame.confirm_pressed = true
	host.step(frame)
	queue_redraw()


func step_fixture(ticks: int, heat_direction: int = 0, patience_held: bool = false) -> void:
	for _tick: int in range(maxi(0, ticks)):
		var frame := MinigameInputFrame.new()
		frame.heat_direction = heat_direction
		frame.patience_held = patience_held
		host.step(frame)
	queue_redraw()


func pour_for_test() -> ModeResult:
	var frame := MinigameInputFrame.new()
	frame.pour_pressed = true
	var result := host.step(frame)
	queue_redraw()
	return result


func pause_for_test() -> void:
	host.toggle_pause()
	_pause_focus = 0
	queue_redraw()


func retry_for_test() -> void:
	_retry_attempt()


func accept_loss_for_test() -> ModeResult:
	return host.accept_loss()


func current_result() -> ModeResult:
	return final_result


func state_snapshot() -> String:
	return tea.state.canonical_snapshot() if tea != null else ""


func is_paused_state() -> bool:
	return tea != null and tea.is_paused


func resolved_profile_id() -> StringName:
	return _profile.profile_id


func action_contract() -> PackedStringArray:
	return PackedStringArray(ACTION_CONTRACT)


func resolve_input_candidates(candidates: Array[StringName]) -> StringName:
	if tea == null:
		return GameInput.first_matching(candidates, [GameInput.CONFIRM, GameInput.CANCEL])
	if tea.is_paused or tea.state.phase in [TeaTemperatureState.Phase.TUTORIAL, TeaTemperatureState.Phase.RESULT]:
		return GameInput.first_matching(candidates, [
			GameInput.MOVE_UP, GameInput.MOVE_DOWN, GameInput.CONFIRM,
			GameInput.CANCEL, GameInput.PAUSE,
		])
	return GameInput.first_matching(candidates, [
		GameInput.PAUSE,
		GameInput.FOCUS,
		GameInput.CONFIRM,
		GameInput.MOVE_LEFT,
		GameInput.MOVE_RIGHT,
		GameInput.CANCEL,
	])


func capture_debug_state() -> Dictionary:
	var state := super.capture_debug_state()
	state.merge({
		"phase": tea.state.phase if tea != null else -1,
		"tea_state": state_snapshot(),
		"paused": tea.is_paused if tea != null else false,
		"attempt": host.attempt_count,
		"pour_queued": _pour_queued,
		"result": String(final_result.result_tag) if final_result != null else "",
	}, true)
	return state


func _default_context() -> ModeContext:
	var context := ModeContext.new()
	context.mode_type = &"start_minigame"
	context.mode_id = &"mini.shrine.tea_temperature"
	context.event_id = &"evt.hkr.empty_cushion"
	context.node_id = &"n005"
	context.target_band = &"warm"
	context.cups = 2
	context.deterministic_seed = 6060
	return context


func _load_runtime() -> void:
	assist_settings = _fixture_assists() if fixture_assist_profile == "all" else assist_settings
	host = MinigameHost.new()
	host.result_ready.connect(_on_result_ready)
	tea = TeaTemperatureSimulation.new()
	host.load_minigame(tea, mode_context if mode_context != null else _default_context(), assist_settings)
	final_result = null
	_fixed_accumulator = 0.0
	_pour_queued = false
	_pause_focus = 0
	_completion_emitted = false
	_visual_cue_key = &""
	_visual_cue_seconds = 0.0
	_prepare_fixture_state()
	queue_redraw()


func _fixture_assists() -> MinigameAssistSettings:
	var settings := MinigameAssistSettings.new()
	settings.slower_heat_change = true
	settings.wider_target_band = true
	settings.no_timer = true
	return settings


func _prepare_fixture_state() -> void:
	match fixture_state:
		"active":
			start_for_test()
			step_fixture(60, 1, true)
		"paused":
			start_for_test()
			step_fixture(60, 1, true)
			host.toggle_pause()
		"result":
			start_for_test()
			var heat_ticks := 220 if assist_settings.slower_heat_change else 110
			var patient_heat_ticks := mini(heat_ticks, TeaTemperatureSimulation.TARGET_STEEP_TICKS)
			step_fixture(patient_heat_ticks, 1, true)
			if heat_ticks < TeaTemperatureSimulation.TARGET_STEEP_TICKS:
				step_fixture(TeaTemperatureSimulation.TARGET_STEEP_TICKS - heat_ticks, 0, true)
			else:
				step_fixture(heat_ticks - TeaTemperatureSimulation.TARGET_STEEP_TICKS, 1, false)
			pour_for_test()
			step_fixture(TeaTemperatureSimulation.POUR_LOCK_TICKS)
			pour_for_test()


func _handle_pause_action(action: StringName) -> bool:
	if action in [GameInput.MOVE_UP, GameInput.MOVE_LEFT]:
		_pause_focus = posmod(_pause_focus - 1, 3)
		queue_redraw()
		return true
	if action in [GameInput.MOVE_DOWN, GameInput.MOVE_RIGHT]:
		_pause_focus = posmod(_pause_focus + 1, 3)
		queue_redraw()
		return true
	if action in [GameInput.CANCEL, GameInput.PAUSE]:
		host.toggle_pause()
		queue_redraw()
		return true
	if action != GameInput.CONFIRM:
		return false
	match _pause_focus:
		0:
			host.toggle_pause()
		1:
			_retry_attempt()
		2:
			host.accept_loss()
	queue_redraw()
	return true


func _retry_attempt() -> void:
	host.retry()
	final_result = null
	_fixed_accumulator = 0.0
	_pour_queued = false
	_completion_emitted = false
	_visual_cue_key = &""
	_visual_cue_seconds = 0.0
	queue_redraw()


func _on_result_ready(result: ModeResult) -> void:
	final_result = result
	checkpoint_requested.emit(&"minigame_result")
	var excellent := result.result_tag == &"excellent"
	sfx_player.play_cue(AudioCueIntent.new(
		&"sfx.minigame.tea.result",
		&"ui.minigame.tea.visual.pour",
		520.0 if excellent else 260.0,
		0.16
	))
	_visual_cue_key = &"ui.minigame.tea.visual.pour"
	_visual_cue_seconds = 1.0
	queue_redraw()


func _emit_completion_once() -> void:
	if final_result == null or _completion_emitted:
		return
	_completion_emitted = true
	mode_completed.emit(final_result)


func _draw() -> void:
	var background := _profile.ink if _profile.is_inverted else _profile.paper
	var foreground := _profile.paper if _profile.is_inverted else _profile.ink
	draw_rect(Rect2(0, 0, 320, 180), background)
	_draw_shell(foreground, background)
	if tea == null:
		return
	if tea.is_paused:
		_draw_pause(foreground, background)
	elif tea.state.phase == TeaTemperatureState.Phase.TUTORIAL:
		_draw_tutorial(foreground, background)
	elif tea.state.phase == TeaTemperatureState.Phase.ACTIVE:
		_draw_active(foreground, background)
	else:
		_draw_result(foreground, background)


func _draw_shell(foreground: Color, background: Color) -> void:
	var font := _japanese_font if _locale == &"ja" else _latin_font
	draw_rect(Rect2(4, 2, 312, 17), background)
	draw_rect(Rect2(4, 2, 312, 17), foreground, false, 1.0)
	draw_string(font, Vector2(8, 15), _catalog.text(&"ui.minigame.tea.title", _locale), HORIZONTAL_ALIGNMENT_LEFT, 230, _compact_font_size(), foreground)
	var step := 1
	if tea != null:
		step = 3 if tea.is_paused else tea.state.phase + 1
		draw_string(font, Vector2(256, 15), "%d/3" % mini(step, 3), HORIZONTAL_ALIGNMENT_RIGHT, 54, _compact_font_size(), foreground)
	draw_rect(Rect2(4, 160, 312, 18), background)
	draw_rect(Rect2(4, 160, 312, 18), foreground, false, 1.0)
	var footer := (
		input_hint(GameInput.CONFIRM, _catalog.text(&"ui.minigame.tea.result.continue", _locale))
		if tea != null and tea.state.phase == TeaTemperatureState.Phase.RESULT
		else "  ".join([
			"%s %s" % [input_axis_binding(GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT), _catalog.text(&"ui.input.heat", _locale)],
			input_hint(GameInput.FOCUS, _catalog.text(&"ui.input.steep", _locale)),
			input_hint(GameInput.CONFIRM, _catalog.text(&"ui.input.pour", _locale)),
		])
	)
	draw_string(font, Vector2(8, 174), footer, HORIZONTAL_ALIGNMENT_CENTER, 304, _compact_font_size(), foreground)


func _draw_tutorial(foreground: Color, background: Color) -> void:
	var font := _japanese_font if _locale == &"ja" else _latin_font
	draw_rect(Rect2(10, 24, 300, 130), background)
	draw_rect(Rect2(10, 24, 300, 130), foreground, false, 2.0)
	draw_string(font, Vector2(18, 41), _catalog.text(&"ui.minigame.tea.objective", _locale), HORIZONTAL_ALIGNMENT_CENTER, 284, _body_font_size(), foreground)
	var body := PixelTextWrapper.wrap(_catalog.text(&"ui.minigame.tea.tutorial.body", _locale), font, 270, _body_font_size(), _locale, 3)
	for index: int in range(body.size()):
		draw_string(font, Vector2(25, 59 + index * _body_line_height()), body[index], HORIZONTAL_ALIGNMENT_CENTER, 270, _body_font_size(), foreground)
	if ui_scale_percent() == 100:
		_draw_three_cups(Vector2(77, 87), foreground, background)
	var controls := PixelTextWrapper.wrap(_catalog.text(&"ui.minigame.tea.tutorial.controls", _locale), font, 280, _compact_font_size(), _locale, 2)
	for index: int in range(controls.size()):
		draw_string(font, Vector2(20, (111 if ui_scale_percent() > 100 else 132) + index * (_compact_font_size() + 1)), controls[index], HORIZONTAL_ALIGNMENT_CENTER, 280, _compact_font_size(), foreground)
	_draw_assist_marks(Vector2(16, 152), foreground, 288, _compact_font_size())


func _draw_active(foreground: Color, background: Color) -> void:
	var font := _japanese_font if _locale == &"ja" else _latin_font
	draw_rect(Rect2(9, 24, 302, 132), background)
	draw_rect(Rect2(9, 24, 302, 132), foreground, false, 2.0)
	draw_string(font, Vector2(17, 40), _catalog.text(&"ui.minigame.tea.objective", _locale), HORIZONTAL_ALIGNMENT_CENTER, 286, _body_font_size(), foreground)
	_draw_instrument(Rect2(42, 54, 64, 44), _catalog.text(&"ui.minigame.tea.heat", _locale), tea.state.kettle_heat, foreground, background)
	_draw_instrument(Rect2(128, 54, 64, 44), _catalog.text(&"ui.minigame.tea.cup_one", _locale), tea.state.cup_temperatures[0], foreground, background)
	_draw_instrument(Rect2(214, 54, 64, 44), _catalog.text(&"ui.minigame.tea.cup_two", _locale), tea.state.cup_temperatures[1], foreground, background)
	_draw_steam(Vector2(74, 50), foreground)
	_draw_assist_marks(Vector2(94, 51), foreground, 208, _compact_font_size())
	_draw_gauge(Rect2(48, 111, 224, 8), tea.state.kettle_heat, TeaTemperatureSimulation.MIN_HEAT, TeaTemperatureSimulation.MAX_HEAT, foreground, background, true)
	draw_string(font, Vector2(8, 119), _catalog.text(&"ui.minigame.tea.heat", _locale), HORIZONTAL_ALIGNMENT_LEFT, 38, _compact_font_size(), foreground)
	_draw_gauge(Rect2(48, 126, 224, 8), tea.state.steep_ticks, 0, 360, foreground, background, false)
	draw_string(font, Vector2(8, 134), _catalog.text(&"ui.minigame.tea.steep", _locale), HORIZONTAL_ALIGNMENT_LEFT, 38, _compact_font_size(), foreground)
	var pour_key := &"ui.minigame.tea.pour_ready" if tea.can_pour() else &"ui.minigame.tea.pour_wait"
	draw_string(font, Vector2(18, 150), _catalog.text(pour_key, _locale), HORIZONTAL_ALIGNMENT_LEFT, 190, _compact_font_size(), foreground)
	var timer_text := (
		_catalog.text(&"ui.minigame.tea.timer.off", _locale)
		if tea.assists.no_timer
		else "TIME %02d" % ceili(tea.state.remaining_ticks / 60.0)
	)
	draw_string(font, Vector2(216, 150), timer_text, HORIZONTAL_ALIGNMENT_RIGHT, 84, _compact_font_size(), foreground)
	if _visual_cue_seconds > 0.0:
		draw_string(font, Vector2(105, 106), _catalog.text(_visual_cue_key, _locale), HORIZONTAL_ALIGNMENT_CENTER, 110, _compact_font_size(), foreground)


func _draw_pause(foreground: Color, background: Color) -> void:
	_draw_active(foreground, background)
	var font := _japanese_font if _locale == &"ja" else _latin_font
	draw_rect(Rect2(62, 38, 196, 111), background)
	draw_rect(Rect2(62, 38, 196, 111), foreground, false, 2.0)
	draw_string(font, Vector2(70, 56), _catalog.text(&"ui.minigame.tea.paused", _locale), HORIZONTAL_ALIGNMENT_CENTER, 180, _body_font_size(), foreground)
	var keys: Array[StringName] = [
		&"ui.minigame.tea.pause.resume",
		&"ui.minigame.tea.pause.retry",
		&"ui.minigame.tea.pause.accept_loss",
	]
	for index: int in range(keys.size()):
		var rect := Rect2(80, 69 + index * 23, 160, 18)
		draw_rect(rect, foreground, false, 1.0)
		if index == _pause_focus:
			draw_rect(rect.grow(-2), foreground, false, 1.0)
		draw_string(font, Vector2(86, rect.position.y + 13), _catalog.text(keys[index], _locale), HORIZONTAL_ALIGNMENT_CENTER, 148, _body_font_size(), foreground)


func _draw_result(foreground: Color, background: Color) -> void:
	var font := _japanese_font if _locale == &"ja" else _latin_font
	draw_rect(Rect2(18, 30, 284, 122), background)
	draw_rect(Rect2(18, 30, 284, 122), foreground, false, 2.0)
	var tag := final_result.result_tag if final_result != null else tea.state.result_tag
	var title_key := StringName("ui.dialogue.result.%s" % tag)
	draw_string(font, Vector2(28, 50), _catalog.text(title_key, _locale), HORIZONTAL_ALIGNMENT_CENTER, 264, _body_font_size(), foreground)
	_draw_result_stamp(Vector2(160, 79), tag, foreground, background)
	var result_key := StringName("ui.minigame.tea.result.%s" % tag)
	var lines := PixelTextWrapper.wrap(_catalog.text(result_key, _locale), font, 248, _body_font_size(), _locale, 3)
	for index: int in range(lines.size()):
		draw_string(font, Vector2(36, 113 + index * _body_line_height()), lines[index], HORIZONTAL_ALIGNMENT_CENTER, 248, _body_font_size(), foreground)
	if final_result != null and final_result.used_assist:
		_draw_assist_marks(Vector2(30, 145), foreground)


func _draw_instrument(rect: Rect2, label: String, value: int, foreground: Color, background: Color) -> void:
	var font := _japanese_font if _locale == &"ja" else _latin_font
	draw_string(font, rect.position + Vector2(0, 10), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, _compact_font_size(), foreground)
	var vessel := Rect2(rect.position + Vector2(7, 14), Vector2(rect.size.x - 14, 25))
	draw_rect(vessel, foreground, false, 2.0)
	if value < 0:
		return
	var ratio := clampf((value - TeaTemperatureSimulation.MIN_HEAT) / float(TeaTemperatureSimulation.MAX_HEAT - TeaTemperatureSimulation.MIN_HEAT), 0.0, 1.0)
	var fill_height := floori((vessel.size.y - 4) * ratio)
	var fill := Rect2(vessel.position + Vector2(3, vessel.size.y - 2 - fill_height), Vector2(vessel.size.x - 6, fill_height))
	_draw_dither_fill(fill, foreground, background)


func _draw_gauge(rect: Rect2, value: int, minimum: int, maximum: int, foreground: Color, background: Color, show_target: bool) -> void:
	draw_rect(rect, foreground, false, 1.0)
	var ratio := clampf((value - minimum) / float(maximum - minimum), 0.0, 1.0)
	draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2((rect.size.x - 4) * ratio, rect.size.y - 4)), foreground)
	if show_target:
		var target_ratio := (TeaTemperatureSimulation.TARGET_HEAT - minimum) / float(maximum - minimum)
		var band := 0.08 if tea.assists.wider_target_band else 0.045
		var left := rect.position.x + rect.size.x * (target_ratio - band)
		var right := rect.position.x + rect.size.x * (target_ratio + band)
		draw_line(Vector2(left, rect.position.y - 2), Vector2(left, rect.end.y + 2), foreground, 1.0)
		draw_line(Vector2(right, rect.position.y - 2), Vector2(right, rect.end.y + 2), foreground, 1.0)


func _draw_dither_fill(rect: Rect2, foreground: Color, _background: Color) -> void:
	for y: int in range(floori(rect.position.y), ceili(rect.end.y)):
		for x: int in range(floori(rect.position.x), ceili(rect.end.x)):
			if (x + y) % 2 == 0:
				draw_rect(Rect2(x, y, 1, 1), foreground)


func _draw_steam(origin: Vector2, foreground: Color) -> void:
	var phase := tea.state.steam_phase if tea != null else 0
	for index: int in range(3):
		var x := origin.x + index * 5
		var lift := (phase + index * 3) % 6
		draw_line(Vector2(x, origin.y - lift), Vector2(x + 2, origin.y - 5 - lift), foreground, 1.0)


func _draw_three_cups(origin: Vector2, foreground: Color, background: Color) -> void:
	for index: int in range(3):
		var position := origin + Vector2(index * 82, 0)
		draw_rect(Rect2(position, Vector2(42, 22)), foreground, false, 2.0)
		_draw_dither_fill(Rect2(position + Vector2(4, 5), Vector2(34, 13)), foreground, background)
		draw_line(position + Vector2(43, 7), position + Vector2(51, 4), foreground, 1.0)


func _draw_assist_marks(
	origin: Vector2,
	foreground: Color,
	width: float = 276.0,
	font_size: int = 8
) -> void:
	var font := _japanese_font if _locale == &"ja" else _latin_font
	var resolved_font_size := maxi(10, font_size) if _locale == &"ja" else font_size
	var labels: Array[StringName] = []
	if assist_settings.slower_heat_change:
		labels.append(&"ui.minigame.tea.assist.slower_heat")
	if assist_settings.wider_target_band:
		labels.append(&"ui.minigame.tea.assist.wider_band")
	if assist_settings.no_timer:
		labels.append(&"ui.minigame.tea.assist.no_timer")
	if labels.is_empty():
		return
	var text_parts: Array[String] = []
	for key: StringName in labels:
		text_parts.append(_catalog.text(key, _locale))
	draw_string(font, origin, " / ".join(text_parts), HORIZONTAL_ALIGNMENT_LEFT, width, resolved_font_size, foreground)


func _draw_result_stamp(origin: Vector2, tag: StringName, foreground: Color, background: Color) -> void:
	draw_circle(origin, 20, foreground)
	draw_circle(origin, 16, background)
	match tag:
		&"excellent":
			draw_colored_polygon(PackedVector2Array([origin + Vector2(0, -11), origin + Vector2(4, -3), origin + Vector2(12, 0), origin + Vector2(4, 3), origin + Vector2(0, 11), origin + Vector2(-4, 3), origin + Vector2(-12, 0), origin + Vector2(-4, -3)]), foreground)
		&"clear":
			draw_rect(Rect2(origin - Vector2(9, 6), Vector2(18, 12)), foreground, false, 2.0)
			draw_line(origin + Vector2(-6, 9), origin + Vector2(6, 9), foreground, 2.0)
		_:
			draw_line(origin + Vector2(-9, -9), origin + Vector2(9, 9), foreground, 2.0)
			draw_line(origin + Vector2(9, -9), origin + Vector2(-9, 9), foreground, 2.0)


func _body_font_size() -> int:
	return scaled_ui_pixels(12 if _locale == &"ja" else 8)


func _compact_font_size() -> int:
	var base_size := (9 if ui_scale_percent() > 100 else 10) if _locale == &"ja" else (7 if ui_scale_percent() > 100 else 8)
	return scaled_ui_pixels(base_size)


func _body_line_height() -> int:
	return _body_font_size() + (4 if ui_scale_percent() > 100 else 2)
