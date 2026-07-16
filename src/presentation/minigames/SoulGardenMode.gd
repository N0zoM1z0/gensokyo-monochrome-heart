class_name SoulGardenMode
extends GameMode
## One-bit Soul Orchard shell: identify, carry, match, and deliberately release.

const ACTION_CONTRACT := ["move", "confirm", "cancel", "pause"]
const FIXED_DELTA := 1.0 / 60.0

@export_enum("tutorial", "active", "carried", "mismatch", "paused", "result") var fixture_state := "tutorial"

var host := MinigameHost.new()
var garden := SoulGardenSimulation.new()
var assist_settings := MinigameAssistSettings.new()
var final_result: ModeResult

var _profile: PresentationProfile = PresentationProfileRegistry.resolve(&"A")
var _locale: StringName = &"en"
var _catalog := UiTextCatalog.new()
var _latin_font: Font
var _japanese_font: Font
var _accumulator: float = 0.0
var _note_key: StringName
var _completion_emitted: bool = false


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
	if is_suspended or garden == null or garden.is_paused or garden.state.phase != SoulGardenState.Phase.ACTIVE:
		return
	_accumulator = minf(_accumulator + delta, FIXED_DELTA * 4.0)
	while _accumulator >= FIXED_DELTA:
		host.step(MinigameInputFrame.new())
		_accumulator -= FIXED_DELTA
	queue_redraw()


func handle_semantic_action(action: StringName) -> bool:
	if garden == null:
		return false
	if garden.is_paused:
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
	match garden.state.phase:
		SoulGardenState.Phase.TUTORIAL:
			if action == GameInput.CONFIRM:
				_start_for_test()
				return true
		SoulGardenState.Phase.ACTIVE:
			if action in [GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT]:
				_step_for_test(-1 if action == GameInput.MOVE_LEFT else 1, false)
				return true
			if action == GameInput.CONFIRM:
				_confirm_for_test()
				return true
			if action in [GameInput.PAUSE, GameInput.CANCEL]:
				host.toggle_pause()
				queue_redraw()
				return true
		SoulGardenState.Phase.RESULT:
			if action == GameInput.CONFIRM:
				_emit_completion_once()
				return true
			if action == GameInput.CANCEL:
				host.retry()
				final_result = null
				_note_key = &""
				queue_redraw()
				return true
	return false


func action_contract() -> PackedStringArray:
	return PackedStringArray(ACTION_CONTRACT)


func resolved_profile_id() -> StringName:
	return _profile.profile_id


func capture_debug_state() -> Dictionary:
	var state := super.capture_debug_state()
	state.merge({
		"phase": garden.state.phase if garden != null else -1,
		"cursor": garden.state.cursor_column if garden != null else -1,
		"carried": garden.state.carried_spirit if garden != null else -1,
		"released": garden.state.released_count if garden != null else 0,
		"mismatches": garden.state.mismatch_count if garden != null else 0,
		"result": String(final_result.result_tag) if final_result != null else "",
	}, true)
	return state


func move_cursor_for_test(target: int) -> void:
	while garden.state.cursor_column != clampi(target, 0, 4):
		_step_for_test(signi(target - garden.state.cursor_column), false)


func confirm_for_test() -> ModeResult:
	return _confirm_for_test()


func _default_context() -> ModeContext:
	var context := ModeContext.new()
	context.mode_type = &"start_minigame"
	context.mode_id = &"mini.hgy.soul_garden"
	context.event_id = &"evt.hgy.petal_on_hold"
	context.node_id = &"n_soul_garden"
	context.deterministic_seed = 13021
	return context


func _load_runtime() -> void:
	host = MinigameHost.new()
	host.result_ready.connect(_on_result_ready)
	garden = SoulGardenSimulation.new()
	host.load_minigame(garden, mode_context if mode_context != null else _default_context(), assist_settings)
	final_result = null
	_accumulator = 0.0
	_note_key = &""
	_completion_emitted = false
	_prepare_fixture_state()
	queue_redraw()


func _prepare_fixture_state() -> void:
	if fixture_state == "tutorial":
		return
	_start_for_test()
	match fixture_state:
		"carried":
			move_cursor_for_test(garden.state.spirit_columns[0])
			_confirm_for_test()
		"mismatch":
			move_cursor_for_test(garden.state.spirit_columns[0])
			_confirm_for_test()
			move_cursor_for_test(SoulGardenSimulation.TREE_COLUMNS[1])
			_confirm_for_test()
		"paused":
			host.toggle_pause()
		"result":
			for index: int in range(3):
				move_cursor_for_test(garden.state.spirit_columns[index])
				_confirm_for_test()
				move_cursor_for_test(SoulGardenSimulation.TREE_COLUMNS[index])
				_confirm_for_test()


func _start_for_test() -> void:
	var frame := MinigameInputFrame.new()
	frame.confirm_pressed = true
	host.step(frame)
	queue_redraw()


func _step_for_test(direction: int, confirm: bool) -> ModeResult:
	if direction != 0:
		_note_key = &""
	var frame := MinigameInputFrame.new()
	frame.grid_direction.x = direction
	frame.confirm_pressed = confirm
	var result := host.step(frame)
	queue_redraw()
	return result


func _confirm_for_test() -> ModeResult:
	var carried_before := garden.state.carried_spirit
	var released_before := garden.state.released_count
	var mismatch_before := garden.state.mismatch_count
	var result := _step_for_test(0, true)
	if garden.state.mismatch_count > mismatch_before:
		_note_key = &"ui.minigame.soul_garden.note.mismatch"
	elif garden.state.released_count > released_before:
		_note_key = &"ui.minigame.soul_garden.note.released"
	elif carried_before < 0 and garden.state.carried_spirit >= 0:
		_note_key = &"ui.minigame.soul_garden.note.collected"
	elif carried_before >= 0:
		_note_key = &"ui.minigame.soul_garden.note.no_memorial"
	elif carried_before < 0:
		_note_key = &"ui.minigame.soul_garden.note.empty"
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
	_draw_header(foreground, background)
	if garden.state.phase == SoulGardenState.Phase.TUTORIAL:
		_draw_tutorial(foreground, background)
	elif garden.state.phase == SoulGardenState.Phase.RESULT:
		_draw_result(foreground, background)
	else:
		_draw_garden(foreground, background)
	if garden.is_paused:
		_draw_pause(foreground, background)


func _draw_header(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(4, 2, 312, 18), background)
	draw_rect(Rect2(4, 2, 312, 18), foreground, false, 1.0)
	draw_string(_font(), Vector2(8, 15), _t(&"ui.minigame.soul_garden.title"), HORIZONTAL_ALIGNMENT_LEFT, 205, _compact_size(), foreground)
	var count := garden.state.released_count if garden != null else 0
	draw_string(_font(), Vector2(215, 15), "%s %d/3" % [_t(&"ui.minigame.soul_garden.released"), count], HORIZONTAL_ALIGNMENT_RIGHT, 93, _compact_size(), foreground)


func _draw_tutorial(foreground: Color, background: Color) -> void:
	_draw_youmu(Vector2(270, 89), foreground, background)
	draw_string(_font(), Vector2(16, 40), _t(&"ui.minigame.soul_garden.tutorial.header"), HORIZONTAL_ALIGNMENT_LEFT, 218, _title_size(), foreground)
	_draw_wrapped(&"ui.minigame.soul_garden.tutorial.body", Rect2(16, 50, 215, 48), 4, foreground)
	for index: int in range(3):
		var center := Vector2(48 + index * 72, 128)
		_draw_signature(index, center, foreground, background)
		draw_line(center + Vector2(-14, 15), center + Vector2(14, 15), foreground, 1.0)
	_draw_footer(&"ui.minigame.soul_garden.tutorial.footer", foreground, background)


func _draw_garden(foreground: Color, background: Color) -> void:
	for y: int in [97, 104, 111]:
		draw_line(Vector2(8, y), Vector2(312, y), foreground, 1.0)
	for index: int in range(3):
		_draw_memorial_tree(index, _column_x(SoulGardenSimulation.TREE_COLUMNS[index]), foreground, background)
	for index: int in range(3):
		if not garden.state.released[index] and index != garden.state.carried_spirit:
			_draw_spirit(index, Vector2(_column_x(garden.state.spirit_columns[index]), 52 + index * 6), foreground, background)
	var cursor_x := _column_x(garden.state.cursor_column)
	draw_line(Vector2(cursor_x - 12, 27), Vector2(cursor_x - 12, 142), foreground, 1.0)
	draw_line(Vector2(cursor_x + 12, 27), Vector2(cursor_x + 12, 142), foreground, 1.0)
	draw_line(Vector2(cursor_x - 12, 27), Vector2(cursor_x - 5, 27), foreground, 2.0)
	draw_line(Vector2(cursor_x + 5, 27), Vector2(cursor_x + 12, 27), foreground, 2.0)
	if garden.state.carried_spirit >= 0:
		_draw_spirit(garden.state.carried_spirit, Vector2(cursor_x, 82), foreground, background)
	var instruction_key := &"ui.minigame.soul_garden.instruction.release" if garden.state.carried_spirit >= 0 else &"ui.minigame.soul_garden.instruction.collect"
	if _note_key != &"":
		draw_string(_font(), Vector2(8, 158), _t(_note_key), HORIZONTAL_ALIGNMENT_CENTER, 304, _compact_size(), foreground)
	else:
		draw_string(_font(), Vector2(8, 158), _t(instruction_key), HORIZONTAL_ALIGNMENT_CENTER, 304, _compact_size(), foreground)
	_draw_footer(&"ui.minigame.soul_garden.active.footer", foreground, background)


func _draw_result(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(20, 29, 280, 124), foreground, false, 2.0)
	draw_string(_font(), Vector2(30, 49), _t(&"ui.minigame.soul_garden.result.header"), HORIZONTAL_ALIGNMENT_CENTER, 260, _title_size(), foreground)
	for index: int in range(3):
		var center := Vector2(80 + index * 80, 85)
		_draw_spirit(index, center, foreground, background)
		draw_line(center + Vector2(-16, 20), center + Vector2(16, 20), foreground, 1.0)
	_draw_wrapped(&"ui.minigame.soul_garden.result.body", Rect2(40, 116, 240, 28), 2, foreground, true)
	_draw_footer(&"ui.minigame.soul_garden.result.footer", foreground, background)


func _draw_pause(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(52, 55, 216, 67), background)
	draw_rect(Rect2(52, 55, 216, 67), foreground, false, 2.0)
	draw_string(_font(), Vector2(68, 83), _t(&"ui.minigame.soul_garden.paused"), HORIZONTAL_ALIGNMENT_CENTER, 184, _title_size(), foreground)
	_draw_wrapped(&"ui.minigame.soul_garden.pause.body", Rect2(64, 89, 192, 28), 2, foreground, true)


func _draw_memorial_tree(index: int, x: float, foreground: Color, background: Color) -> void:
	draw_rect(Rect2(x - 4, 116, 8, 29), foreground)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x, 105), Vector2(x - 18, 122), Vector2(x + 18, 122),
	]), foreground)
	draw_circle(Vector2(x, 122), 8, background)
	_draw_signature(index, Vector2(x, 128), foreground, background, 5)


func _draw_spirit(index: int, center: Vector2, foreground: Color, background: Color) -> void:
	draw_circle(center, 10, foreground, false, 2.0)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-6, 7), center + Vector2(-2, 17), center + Vector2(3, 9), center + Vector2(7, 16), center + Vector2(7, 5),
	]), foreground)
	draw_circle(center, 7, background)
	_draw_signature(index, center, foreground, background, 4)


func _draw_signature(index: int, center: Vector2, foreground: Color, background: Color, radius: int = 7) -> void:
	match index:
		0:
			for spoke: int in range(4):
				draw_line(center, center + Vector2(-radius + spoke * 4, -radius + spoke), foreground, 2.0)
			draw_arc(center, radius, PI, TAU, 8, foreground, 2.0)
		1:
			draw_rect(Rect2(center - Vector2(radius, 3), Vector2(radius * 2 - 2, 7)), foreground, false, 1.0)
			draw_arc(center + Vector2(radius - 2, 0), 4, -PI / 2.0, PI / 2.0, 6, foreground, 1.0)
		2:
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-radius, 3), center + Vector2(-radius + 2, -radius), center + Vector2(radius - 2, -radius), center + Vector2(radius, 3),
			]), foreground)
			draw_rect(Rect2(center - Vector2(radius - 2, radius - 2), Vector2(radius * 2 - 4, radius - 1)), background)


func _draw_youmu(center: Vector2, foreground: Color, background: Color) -> void:
	draw_circle(center + Vector2(-5, -25), 9, foreground)
	draw_rect(Rect2(center + Vector2(-13, -15), Vector2(17, 42)), foreground)
	draw_line(center + Vector2(2, -13), center + Vector2(17, 27), foreground, 2.0)
	draw_line(center + Vector2(7, -12), center + Vector2(23, 22), foreground, 1.0)
	draw_circle(center + Vector2(18, -12), 11, foreground, false, 2.0)
	draw_circle(center + Vector2(22, -15), 7, background)


func _column_x(column: int) -> float:
	return 32.0 + column * 64.0


func _draw_footer(key: StringName, foreground: Color, background: Color) -> void:
	draw_rect(Rect2(4, 164, 312, 14), background)
	draw_rect(Rect2(4, 164, 312, 14), foreground, false, 1.0)
	draw_string(_font(), Vector2(8, 175), _t(key), HORIZONTAL_ALIGNMENT_CENTER, 304, _compact_size(), foreground)


func _draw_wrapped(key: StringName, rect: Rect2, maximum_lines: int, foreground: Color, centered: bool = false) -> void:
	var lines := PixelTextWrapper.wrap(_t(key), _font(), rect.size.x, _body_size(), _locale, maximum_lines)
	for index: int in range(lines.size()):
		draw_string(_font(), rect.position + Vector2(0, _body_size() + index * _line_height()), lines[index], HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, _body_size(), foreground)


func _t(key: StringName) -> String:
	return _catalog.text(key, _locale)


func _font() -> Font:
	return _japanese_font if _locale == &"ja" else _latin_font


func _compact_size() -> int:
	return 10 if _locale == &"ja" else 8


func _body_size() -> int:
	return 10 if _locale == &"ja" else 8


func _title_size() -> int:
	return 11 if _locale == &"ja" else 10


func _line_height() -> int:
	return 11 if _locale == &"ja" else 9
