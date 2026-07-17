class_name HalfPhantomBalanceMode
extends GameMode
## One-bit paired-body puzzle; players swap control rather than forcing one half to follow.

const ACTION_CONTRACT := ["move", "confirm", "cancel", "pause"]
const BALANCE_SIMULATION := preload("res://src/application/minigames/HalfPhantomBalanceSimulation.gd")
const BALANCE_STATE := preload("res://src/application/minigames/HalfPhantomBalanceState.gd")
const TUTORIAL_TEXT_WIDTH := 276
const TUTORIAL_MAX_LINES := 3
const TUTORIAL_TEXT_TOP := 54

var host := MinigameHost.new()
var balance = BALANCE_SIMULATION.new()
var assist_settings := MinigameAssistSettings.new()
var final_result: ModeResult
var _profile := PresentationProfileRegistry.resolve(&"A")
var _locale: StringName = &"en"
var _catalog := UiTextCatalog.new()
var _latin_font: Font
var _japanese_font: Font
var _completion_emitted := false


func _ready() -> void:
	InputMapInstaller.install_defaults()
	_latin_font = UiFontRegistry.latin()
	_japanese_font = UiFontRegistry.japanese()
	_catalog.load_default()
	custom_minimum_size = Vector2(320, 180)
	size = Vector2(320, 180)
	if mode_context == null:
		mode_context = _default_context()
		_load_runtime()
		ready_for_input.emit()


func configure(context: ModeContext) -> void:
	super.configure(context)
	if is_node_ready():
		_load_runtime()


func configure_fixture(requested_profile: StringName, locale: StringName, forced_profile: StringName = &"", _reduced: bool = false, _safe: bool = false) -> void:
	_profile = PresentationProfileRegistry.resolve(forced_profile if forced_profile != &"" else requested_profile)
	_locale = locale if locale in [&"en", &"ja"] else &"en"
	if is_node_ready():
		_load_runtime()


func configure_assists(settings: MinigameAssistSettings) -> void:
	assist_settings = settings.duplicate_settings() if settings != null else MinigameAssistSettings.new()
	if is_node_ready():
		_load_runtime()


func handle_semantic_action(action: StringName) -> bool:
	if balance == null:
		return false
	if balance.is_paused:
		if action in [GameInput.CONFIRM, GameInput.PAUSE]:
			host.toggle_pause()
			queue_redraw()
			return true
		if action == GameInput.CANCEL:
			host.toggle_pause()
			host.accept_loss()
			queue_redraw()
			return true
		return false
	if balance.state.phase == BALANCE_STATE.Phase.TUTORIAL and action == GameInput.CONFIRM:
		_step(0, true)
		return true
	if balance.state.phase == BALANCE_STATE.Phase.ACTIVE:
		if action == GameInput.CONFIRM:
			_step(0, true)
			return true
		if action == GameInput.MOVE_LEFT:
			_step(-1)
			return true
		if action == GameInput.MOVE_RIGHT:
			_step(1)
			return true
		if action in [GameInput.PAUSE, GameInput.CANCEL]:
			host.toggle_pause()
			queue_redraw()
			return true
	if balance.state.phase == BALANCE_STATE.Phase.RESULT and action == GameInput.CONFIRM and final_result != null and not _completion_emitted:
		_completion_emitted = true
		mode_completed.emit(final_result)
		return true
	return false


func action_contract() -> PackedStringArray:
	return PackedStringArray(ACTION_CONTRACT)


func resolved_profile_id() -> StringName:
	return _profile.profile_id


func _default_context() -> ModeContext:
	var context := ModeContext.new()
	context.mode_type = &"start_minigame"
	context.mode_id = &"mini.hgy.half_phantom_balance"
	context.event_id = &"evt.hgy.two_bodies_one_embarrassment"
	context.node_id = &"n_balance"
	context.deterministic_seed = 1642
	return context


func _load_runtime() -> void:
	host = MinigameHost.new()
	host.result_ready.connect(func(result: ModeResult) -> void:
		final_result = result
		checkpoint_requested.emit(&"minigame_result")
		queue_redraw()
	)
	balance = BALANCE_SIMULATION.new()
	host.load_minigame(balance, mode_context if mode_context != null else _default_context(), assist_settings)
	final_result = null
	_completion_emitted = false
	queue_redraw()


func _step(direction: int, confirm: bool = false) -> void:
	var frame := MinigameInputFrame.new()
	frame.grid_direction.x = direction
	frame.confirm_pressed = confirm
	host.step(frame)
	queue_redraw()


func _draw() -> void:
	var bg := _profile.ink if _profile.is_inverted else _profile.paper
	var fg := _profile.paper if _profile.is_inverted else _profile.ink
	draw_rect(Rect2(0, 0, 320, 180), bg)
	draw_rect(Rect2(4, 3, 312, 174), fg, false, 1.0)
	_text(&"ui.minigame.half_phantom.title", Vector2(10, 17), 300, fg)
	if balance.state.phase == BALANCE_STATE.Phase.TUTORIAL:
		_draw_tutorial_text(fg)
		_text(&"ui.minigame.half_phantom.begin", Vector2(22, 165), 276, fg)
		return
	for index: int in range(BALANCE_SIMULATION.COLUMN_COUNT):
		var x := 44 + index * 58
		draw_line(Vector2(x, 48), Vector2(x, 138), fg, 1.0)
		draw_circle(Vector2(x, 144), 4, fg, false, 1.0)
	_draw_body(Vector2(44 + balance.state.youmu_column * 58, 77), fg, bg, true, balance.state.selected_body == BALANCE_STATE.Body.YOUMU)
	_draw_body(Vector2(44 + balance.state.phantom_column * 58, 112), fg, bg, false, balance.state.selected_body == BALANCE_STATE.Body.PHANTOM)
	draw_rect(Rect2(44 + BALANCE_SIMULATION.YOUMU_TARGET * 58 - 10, 55, 20, 7), fg, false, 1.0)
	draw_rect(Rect2(44 + BALANCE_SIMULATION.PHANTOM_TARGET * 58 - 10, 126, 20, 7), fg, false, 1.0)
	if balance.is_paused:
		_text(&"ui.minigame.half_phantom.paused", Vector2(18, 82), 284, fg)
		_text(&"ui.minigame.half_phantom.pause_help", Vector2(18, 104), 284, fg)
	elif balance.state.phase == BALANCE_STATE.Phase.RESULT:
		_text(&"ui.minigame.half_phantom.result.%s" % balance.state.result_tag, Vector2(18, 164), 284, fg)
	else:
		_text(&"ui.minigame.half_phantom.active", Vector2(18, 164), 284, fg, [_t(&"ui.minigame.half_phantom.body.%s" % balance.selected_label())])


func _draw_body(center: Vector2, fg: Color, bg: Color, human: bool, selected: bool) -> void:
	if selected:
		draw_rect(Rect2(center - Vector2(14, 14), Vector2(28, 28)), fg, false, 1.0)
	if human:
		draw_circle(center + Vector2(0, -4), 6, fg)
		draw_rect(Rect2(center + Vector2(-5, 2), Vector2(10, 9)), fg)
		draw_line(center + Vector2(5, 3), center + Vector2(11, 10), fg, 1.0)
	else:
		draw_circle(center, 9, fg, false, 2.0)
		draw_circle(center, 6, bg)
		draw_line(center + Vector2(-5, 7), center + Vector2(5, 13), fg, 2.0)


func _draw_tutorial_text(color: Color) -> void:
	var font := _font()
	var font_size := tutorial_font_size(_locale)
	var lines := wrap_tutorial_text(_t(&"ui.minigame.half_phantom.tutorial"), font, _locale)
	var line_height := font_size + 1
	for index: int in range(lines.size()):
		draw_string(
			font,
			Vector2(22, TUTORIAL_TEXT_TOP + font_size + index * line_height),
			lines[index],
			HORIZONTAL_ALIGNMENT_CENTER,
			TUTORIAL_TEXT_WIDTH,
			font_size,
			color
		)


static func wrap_tutorial_text(text: String, font: Font, locale: StringName) -> Array[String]:
	return PixelTextWrapper.wrap(
		text,
		font,
		TUTORIAL_TEXT_WIDTH,
		tutorial_font_size(locale),
		locale,
		TUTORIAL_MAX_LINES
	)


static func tutorial_font_size(locale: StringName) -> int:
	return 10 if locale == &"ja" else 8


func _text(key: StringName, at: Vector2, width: float, color: Color, values: Array = []) -> void:
	var text := _t(key)
	for index: int in range(values.size()):
		text = text.replace("{%d}" % index, str(values[index]))
	draw_string(_font(), at, text, HORIZONTAL_ALIGNMENT_CENTER, width, tutorial_font_size(_locale), color)


func _font() -> Font:
	return _japanese_font if _locale == &"ja" else _latin_font


func _t(key: StringName) -> String:
	return _catalog.text(key, _locale)
