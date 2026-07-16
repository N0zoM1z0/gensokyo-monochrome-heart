class_name QuietChoreMode
extends GameMode
## One-bit shrine routine where the final mechanic is deliberately doing nothing.

const ACTION_CONTRACT := ["move", "confirm", "cancel", "pause"]
const FIXED_DELTA := 1.0 / 60.0

@export_enum("tutorial", "sweep", "mend", "sit", "interrupted", "result") var fixture_state := "tutorial"
@export var fixture_story_pacing: bool = false

var host := MinigameHost.new()
var chore := QuietChoreSimulation.new()
var assist_settings := MinigameAssistSettings.new()
var final_result: ModeResult

var _profile: PresentationProfile = PresentationProfileRegistry.resolve(&"A")
var _locale: StringName = &"en"
var _catalog := UiTextCatalog.new()
var _latin_font: Font
var _japanese_font: Font
var _accumulator := 0.0
var _completion_emitted := false


func _ready() -> void:
	InputMapInstaller.install_defaults()
	_latin_font = UiFontRegistry.latin()
	_japanese_font = UiFontRegistry.japanese()
	_catalog.load_default()
	custom_minimum_size = Vector2(320, 180)
	size = Vector2(320, 180)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if fixture_story_pacing:
		assist_settings.slower_pace = true
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
	_is_reduced_motion: bool = false,
	_is_safe_flash: bool = false
) -> void:
	_profile = PresentationProfileRegistry.resolve(forced_profile if forced_profile != &"" else requested_profile)
	_locale = locale if locale in [&"en", &"ja"] else &"en"
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
	if fixture_state == "interrupted":
		return
	if is_suspended or chore == null or chore.is_paused:
		return
	if chore.state.phase not in [QuietChoreState.Phase.SWEEP, QuietChoreState.Phase.MEND, QuietChoreState.Phase.SIT]:
		return
	_accumulator = minf(_accumulator + delta, FIXED_DELTA * 4.0)
	while _accumulator >= FIXED_DELTA:
		host.step(MinigameInputFrame.new())
		_accumulator -= FIXED_DELTA
	queue_redraw()


func handle_semantic_action(action: StringName) -> bool:
	if chore == null:
		return false
	if chore.is_paused:
		if action in [GameInput.CONFIRM, GameInput.CANCEL, GameInput.PAUSE]:
			host.toggle_pause()
			queue_redraw()
			return true
		return false
	match chore.state.phase:
		QuietChoreState.Phase.TUTORIAL:
			if action == GameInput.CONFIRM:
				_step_action(action)
				return true
		QuietChoreState.Phase.SWEEP:
			if action in [GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT]:
				_step_action(action)
				return true
		QuietChoreState.Phase.MEND:
			if action == GameInput.CONFIRM:
				_step_action(action)
				return true
		QuietChoreState.Phase.SIT:
			if action in [GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT, GameInput.MOVE_UP, GameInput.MOVE_DOWN, GameInput.CONFIRM]:
				_step_action(action)
				return true
		QuietChoreState.Phase.RESULT:
			if action == GameInput.CONFIRM:
				_emit_completion_once()
				return true
			if action == GameInput.CANCEL:
				host.retry()
				final_result = null
				queue_redraw()
				return true
	if action in [GameInput.PAUSE, GameInput.CANCEL] and chore.state.phase != QuietChoreState.Phase.RESULT:
		host.toggle_pause()
		queue_redraw()
		return true
	return false


func resolve_input_candidates(candidates: Array[StringName]) -> StringName:
	return GameInput.first_matching(candidates, [
		GameInput.PAUSE, GameInput.CONFIRM, GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT,
		GameInput.MOVE_UP, GameInput.MOVE_DOWN, GameInput.CANCEL,
	])


func action_contract() -> PackedStringArray:
	return PackedStringArray(ACTION_CONTRACT)


func resolved_profile_id() -> StringName:
	return _profile.profile_id


func capture_debug_state() -> Dictionary:
	var state := super.capture_debug_state()
	state.merge({
		"phase": chore.state.phase if chore != null else -1,
		"sweep_strokes": chore.state.sweep_strokes if chore != null else 0,
		"mended_seams": chore.state.mended_seams if chore != null else 0,
		"silence_ticks": chore.state.silence_ticks if chore != null else 0,
		"interruptions": chore.state.interruptions if chore != null else 0,
		"result": String(final_result.result_tag) if final_result != null else "",
	}, true)
	return state


func _default_context() -> ModeContext:
	var context := ModeContext.new()
	context.mode_type = &"start_minigame"
	context.mode_id = &"mini.hkr.quiet_chore"
	context.event_id = &"evt.hkr.day_nothing_happens"
	context.node_id = &"n_quiet_chore"
	context.deterministic_seed = 14031
	return context


func _load_runtime() -> void:
	host = MinigameHost.new()
	host.result_ready.connect(_on_result_ready)
	chore = QuietChoreSimulation.new()
	host.load_minigame(chore, mode_context if mode_context != null else _default_context(), assist_settings)
	final_result = null
	_accumulator = 0.0
	_completion_emitted = false
	_prepare_fixture_state()
	queue_redraw()


func _prepare_fixture_state() -> void:
	if fixture_state == "tutorial":
		return
	_step_action(GameInput.CONFIRM)
	if fixture_state == "sweep":
		for action: StringName in [GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT, GameInput.MOVE_LEFT]:
			_step_action(action)
		return
	for action: StringName in [GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT, GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT, GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT]:
		_step_action(action)
	if fixture_state == "mend":
		_step_action(GameInput.CONFIRM)
		return
	for _seam: int in range(QuietChoreSimulation.REQUIRED_MENDED_SEAMS):
		_step_action(GameInput.CONFIRM)
	if fixture_state == "interrupted":
		for _tick: int in range(75):
			host.step(MinigameInputFrame.new())
		_step_action(GameInput.CONFIRM)
	elif fixture_state == "result":
		var required := QuietChoreSimulation.STORY_SILENCE_TICKS if assist_settings.slower_pace else QuietChoreSimulation.STANDARD_SILENCE_TICKS
		for _tick: int in range(required):
			host.step(MinigameInputFrame.new())


func _step_action(action: StringName) -> ModeResult:
	var frame := MinigameInputFrame.new()
	frame.confirm_pressed = action == GameInput.CONFIRM
	if action == GameInput.MOVE_LEFT:
		frame.grid_direction.x = -1
	elif action == GameInput.MOVE_RIGHT:
		frame.grid_direction.x = 1
	elif action == GameInput.MOVE_UP:
		frame.grid_direction.y = -1
	elif action == GameInput.MOVE_DOWN:
		frame.grid_direction.y = 1
	var result := host.step(frame)
	queue_redraw()
	return result


func _on_result_ready(result: ModeResult) -> void:
	final_result = result
	checkpoint_requested.emit(&"minigame_result")
	queue_redraw()


func _emit_completion_once() -> void:
	if final_result != null and not _completion_emitted:
		_completion_emitted = true
		mode_completed.emit(final_result)


func _draw() -> void:
	var background := _profile.ink if _profile.is_inverted else _profile.paper
	var foreground := _profile.paper if _profile.is_inverted else _profile.ink
	draw_rect(Rect2(0, 0, 320, 180), background)
	draw_rect(Rect2(4, 3, 312, 174), foreground, false, 1.0)
	draw_string(_font(), Vector2(10, 17), _t(&"ui.minigame.quiet_chore.title"), HORIZONTAL_ALIGNMENT_LEFT, 300, _title_size(), foreground)
	if chore.state.phase == QuietChoreState.Phase.TUTORIAL:
		_draw_tutorial(foreground, background)
	elif chore.state.phase == QuietChoreState.Phase.RESULT:
		_draw_result(foreground, background)
	else:
		_draw_room(foreground, background)
	if chore.is_paused:
		_draw_pause(foreground, background)


func _draw_tutorial(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(18, 30, 284, 118), foreground, false, 2.0)
	draw_string(_font(), Vector2(28, 51), _t(&"ui.minigame.quiet_chore.tutorial.header"), HORIZONTAL_ALIGNMENT_CENTER, 264, _title_size(), foreground)
	_draw_wrapped(&"ui.minigame.quiet_chore.tutorial.body", Rect2(34, 62, 252, 45), 4, foreground)
	for index: int in range(3):
		_draw_step_icon(Vector2(83 + index * 77, 124), index, foreground, background)
	draw_string(_font(), Vector2(20, 167), _t(&"ui.minigame.quiet_chore.tutorial.footer"), HORIZONTAL_ALIGNMENT_CENTER, 280, _body_size(), foreground)


func _draw_room(foreground: Color, background: Color) -> void:
	# Three empty architectural bands keep the room visually quieter as the routine progresses.
	draw_line(Vector2(12, 44), Vector2(308, 44), foreground, 1.0)
	draw_line(Vector2(12, 139), Vector2(308, 139), foreground, 1.0)
	for x: int in [38, 116, 194, 272]:
		draw_line(Vector2(x, 44), Vector2(x, 139), foreground, 1.0)
	_draw_reimu(Vector2(244, 104), foreground, background)
	_draw_player(Vector2(85, 108), foreground, background)
	var phase_index := clampi(int(chore.state.phase) - 1, 0, 2)
	for index: int in range(3):
		var rect := Rect2(12 + index * 101, 24, 94, 15)
		draw_rect(rect, foreground if index < phase_index else background)
		draw_rect(rect, foreground, false, 1.0)
		var ink := background if index < phase_index else foreground
		draw_string(_font(), rect.position + Vector2(3, 11), _t(StringName("ui.minigame.quiet_chore.step.%d" % index)), HORIZONTAL_ALIGNMENT_CENTER, 88, _compact_size(), ink)
	match chore.state.phase:
		QuietChoreState.Phase.SWEEP:
			draw_line(Vector2(66, 105), Vector2(45, 134), foreground, 2.0)
			for stroke: int in range(QuietChoreSimulation.REQUIRED_SWEEP_STROKES):
				var mark := Rect2(128 + stroke * 11, 124, 7, 7)
				if stroke < chore.state.sweep_strokes:
					draw_rect(mark, foreground)
				else:
					draw_rect(mark, foreground, false, 1.0)
			draw_string(_font(), Vector2(12, 153), _t(&"ui.minigame.quiet_chore.sweep"), HORIZONTAL_ALIGNMENT_CENTER, 296, _body_size(), foreground)
		QuietChoreState.Phase.MEND:
			for seam: int in range(chore.state.mended_seams):
				draw_line(Vector2(116 + seam * 6, 66), Vector2(116 + seam * 6, 88), foreground, 1.0)
			draw_string(_font(), Vector2(12, 153), _t(&"ui.minigame.quiet_chore.mend"), HORIZONTAL_ALIGNMENT_CENTER, 296, _body_size(), foreground)
		QuietChoreState.Phase.SIT:
			var required := QuietChoreSimulation.STORY_SILENCE_TICKS if assist_settings.slower_pace else QuietChoreSimulation.STANDARD_SILENCE_TICKS
			var width := int(220.0 * float(chore.state.silence_ticks) / float(required))
			draw_rect(Rect2(50, 126, 220, 5), foreground, false, 1.0)
			draw_rect(Rect2(50, 126, width, 5), foreground)
			var sit_key := &"ui.minigame.quiet_chore.sit"
			if chore.state.interruptions > 0 and chore.state.silence_ticks < 90:
				sit_key = &"ui.minigame.quiet_chore.sit.story" if assist_settings.slower_pace else &"ui.minigame.quiet_chore.sit.interrupted"
			draw_string(_font(), Vector2(12, 153), _t(sit_key), HORIZONTAL_ALIGNMENT_CENTER, 296, _body_size(), foreground)
	draw_string(_font(), Vector2(12, 171), _t(&"ui.minigame.quiet_chore.active.footer"), HORIZONTAL_ALIGNMENT_CENTER, 296, _body_size(), foreground)


func _draw_result(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(31, 37, 258, 111), foreground, false, 2.0)
	draw_string(_font(), Vector2(42, 59), _t(&"ui.minigame.quiet_chore.result.header"), HORIZONTAL_ALIGNMENT_CENTER, 236, _title_size(), foreground)
	_draw_reimu(Vector2(230, 108), foreground, background)
	_draw_player(Vector2(91, 112), foreground, background)
	_draw_wrapped(&"ui.minigame.quiet_chore.result.body", Rect2(112, 76, 92, 45), 4, foreground)
	draw_string(_font(), Vector2(20, 167), _t(&"ui.minigame.quiet_chore.result.footer"), HORIZONTAL_ALIGNMENT_CENTER, 280, _body_size(), foreground)


func _draw_pause(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(58, 62, 204, 56), background)
	draw_rect(Rect2(58, 62, 204, 56), foreground, false, 2.0)
	draw_string(_font(), Vector2(68, 86), _t(&"ui.minigame.quiet_chore.paused"), HORIZONTAL_ALIGNMENT_CENTER, 184, _title_size(), foreground)
	_draw_wrapped(&"ui.minigame.quiet_chore.pause.body", Rect2(72, 93, 176, 20), 2, foreground)


func _draw_step_icon(center: Vector2, index: int, foreground: Color, background: Color) -> void:
	draw_circle(center, 20, foreground, false, 1.0)
	if index == 0:
		draw_line(center + Vector2(-9, -11), center + Vector2(8, 13), foreground, 2.0)
		draw_line(center + Vector2(8, 13), center + Vector2(16, 8), foreground, 1.0)
	elif index == 1:
		draw_rect(Rect2(center + Vector2(-11, -13), Vector2(22, 26)), foreground, false, 1.0)
		draw_line(center + Vector2(0, -10), center + Vector2(0, 10), foreground, 1.0)
	else:
		draw_circle(center, 5, foreground)
		draw_line(center + Vector2(-11, 12), center + Vector2(11, 12), foreground, 2.0)


func _draw_reimu(center: Vector2, foreground: Color, background: Color) -> void:
	draw_colored_polygon(PackedVector2Array([center + Vector2(-14, -18), center + Vector2(14, -18), center + Vector2(18, 24), center + Vector2(-18, 24)]), foreground)
	draw_circle(center + Vector2(0, -27), 10, foreground)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-17, -37), center + Vector2(0, -28), center + Vector2(-17, -22)]), foreground)
	draw_colored_polygon(PackedVector2Array([center + Vector2(17, -37), center + Vector2(0, -28), center + Vector2(17, -22)]), foreground)
	draw_rect(Rect2(center + Vector2(-8, -12), Vector2(16, 23)), background)


func _draw_player(center: Vector2, foreground: Color, background: Color) -> void:
	draw_circle(center + Vector2(0, -24), 9, foreground)
	draw_rect(Rect2(center + Vector2(-11, -14), Vector2(22, 37)), foreground)
	draw_rect(Rect2(center + Vector2(-7, -10), Vector2(14, 25)), background)


func _draw_wrapped(key: StringName, rect: Rect2, maximum_lines: int, color: Color) -> void:
	var lines := PixelTextWrapper.wrap(_t(key), _font(), int(rect.size.x), _body_size(), _locale, maximum_lines)
	for index: int in range(lines.size()):
		draw_string(_font(), rect.position + Vector2(0, _body_size() + index * _line_height()), lines[index], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, _body_size(), color)


func _font() -> Font:
	return _japanese_font if _locale == &"ja" else _latin_font


func _t(key: StringName) -> String:
	return _catalog.text(key, _locale)


func _title_size() -> int:
	return 10 if _locale == &"ja" else 9


func _body_size() -> int:
	return 9 if _locale == &"ja" else 8


func _compact_size() -> int:
	return 8 if _locale == &"ja" else 7


func _line_height() -> int:
	return 11 if _locale == &"ja" else 10
