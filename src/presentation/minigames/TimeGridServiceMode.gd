class_name TimeGridServiceMode
extends GameMode
## One-bit presentation for queuing mansion service tasks while the clock is stopped.

const ACTION_CONTRACT := ["move", "confirm", "cancel", "focus", "pause"]
const FIXED_DELTA := 1.0 / float(TimeGridServiceSimulation.TICKS_PER_SECOND)

@export_enum("tutorial", "active", "stopped", "paused", "result", "loss") var fixture_state := "tutorial"
@export_enum("none", "all") var fixture_assist_profile := "none"

var host := MinigameHost.new()
var service := TimeGridServiceSimulation.new()
var assist_settings := MinigameAssistSettings.new()
var final_result: ModeResult

var _profile: PresentationProfile = PresentationProfileRegistry.resolve(&"A")
var _locale: StringName = &"en"
var _catalog := UiTextCatalog.new()
var _latin_font: Font
var _japanese_font: Font
var _fixed_accumulator := 0.0
var _queued_direction := Vector2i.ZERO
var _queue_pressed := false
var _pause_focus := 0
var _completion_emitted := false


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
	if fixture_state != "tutorial" or is_suspended or service == null or service.is_paused or service.state.phase != TimeGridServiceState.Phase.ACTIVE:
		return
	_fixed_accumulator = minf(_fixed_accumulator + delta, FIXED_DELTA * 4.0)
	while _fixed_accumulator >= FIXED_DELTA:
		var frame := MinigameInputFrame.new()
		frame.grid_direction = _queued_direction
		frame.patience_held = Input.is_action_pressed(GameInput.FOCUS)
		frame.pour_pressed = _queue_pressed
		_queued_direction = Vector2i.ZERO
		_queue_pressed = false
		host.step(frame)
		_fixed_accumulator -= FIXED_DELTA
	queue_redraw()


func handle_semantic_action(action: StringName) -> bool:
	if service == null:
		return false
	if service.is_paused:
		return _handle_pause_action(action)
	if service.state.phase == TimeGridServiceState.Phase.TUTORIAL:
		if action == GameInput.CONFIRM:
			start_for_test()
			return true
		return false
	if service.state.phase == TimeGridServiceState.Phase.ACTIVE:
		match action:
			GameInput.MOVE_LEFT:
				_queued_direction = Vector2i.LEFT
			GameInput.MOVE_RIGHT:
				_queued_direction = Vector2i.RIGHT
			GameInput.MOVE_UP:
				_queued_direction = Vector2i.UP
			GameInput.MOVE_DOWN:
				_queued_direction = Vector2i.DOWN
			GameInput.CONFIRM:
				_queue_pressed = true
			GameInput.PAUSE, GameInput.CANCEL:
				host.toggle_pause()
				_pause_focus = 0
			_:
				return false
		queue_redraw()
		return true
	if service.state.phase == TimeGridServiceState.Phase.RESULT:
		if action == GameInput.CONFIRM:
			_emit_completion_once()
			return true
		if action == GameInput.CANCEL:
			_retry_attempt()
			return true
	return false


func resolve_input_candidates(candidates: Array[StringName]) -> StringName:
	if service == null:
		return GameInput.first_matching(candidates, [GameInput.CONFIRM, GameInput.CANCEL])
	if service.is_paused or service.state.phase != TimeGridServiceState.Phase.ACTIVE:
		return GameInput.first_matching(candidates, [GameInput.MOVE_UP, GameInput.MOVE_DOWN, GameInput.CONFIRM, GameInput.CANCEL, GameInput.PAUSE])
	return GameInput.first_matching(candidates, [GameInput.PAUSE, GameInput.FOCUS, GameInput.CONFIRM, GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT, GameInput.MOVE_UP, GameInput.MOVE_DOWN, GameInput.CANCEL])


func action_contract() -> PackedStringArray:
	return PackedStringArray(ACTION_CONTRACT)


func resolved_profile_id() -> StringName:
	return _profile.profile_id


func state_snapshot() -> String:
	return service.state.canonical_snapshot() if service != null else ""


func capture_debug_state() -> Dictionary:
	var state := super.capture_debug_state()
	state.merge({
		"phase": service.state.phase if service != null else -1,
		"service_state": state_snapshot(),
		"paused": service.is_paused if service != null else false,
		"attempt": host.attempt_count,
		"result": String(final_result.result_tag) if final_result != null else "",
	}, true)
	return state


func start_for_test() -> void:
	var frame := MinigameInputFrame.new()
	frame.confirm_pressed = true
	host.step(frame)
	queue_redraw()


func step_for_test(ticks: int, direction := Vector2i.ZERO, stop_time := false, queue_task := false) -> ModeResult:
	var result: ModeResult
	for tick: int in range(maxi(0, ticks)):
		var frame := MinigameInputFrame.new()
		frame.grid_direction = direction if tick == 0 else Vector2i.ZERO
		frame.patience_held = stop_time
		frame.pour_pressed = queue_task and tick == 0
		result = host.step(frame)
	queue_redraw()
	return result


func _default_context() -> ModeContext:
	var context := ModeContext.new()
	context.mode_type = &"start_minigame"
	context.mode_id = &"mini.sdm.time_grid_service"
	context.event_id = &"evt.sdm.late_by_three_minutes"
	context.node_id = &"n120"
	context.deterministic_seed = 12120
	return context


func _load_runtime() -> void:
	assist_settings = _fixture_assists() if fixture_assist_profile == "all" else assist_settings
	host = MinigameHost.new()
	host.result_ready.connect(_on_result_ready)
	service = TimeGridServiceSimulation.new()
	host.load_minigame(service, mode_context if mode_context != null else _default_context(), assist_settings)
	final_result = null
	_fixed_accumulator = 0.0
	_queued_direction = Vector2i.ZERO
	_queue_pressed = false
	_pause_focus = 0
	_completion_emitted = false
	_prepare_fixture_state()
	queue_redraw()


func _fixture_assists() -> MinigameAssistSettings:
	var settings := MinigameAssistSettings.new()
	settings.slower_pace = true
	settings.wider_timing_window = true
	settings.no_timer = true
	return settings


func _prepare_fixture_state() -> void:
	match fixture_state:
		"active":
			start_for_test()
			_move_fixture_cursor(Vector2i(0, 0))
			step_for_test(1, Vector2i.ZERO, true, true)
			step_for_test(72)
		"stopped":
			start_for_test()
			_move_fixture_cursor(Vector2i(0, 0))
			step_for_test(1, Vector2i.ZERO, true, true)
			step_for_test(38, Vector2i.ZERO, true)
		"paused":
			start_for_test()
			step_for_test(72)
			host.toggle_pause()
		"result":
			_complete_excellent_fixture()
		"loss":
			start_for_test()
			for _task: int in range(TimeGridServiceSimulation.TASK_STATIONS.size()):
				step_for_test(1, Vector2i.ZERO, true, true)
				var due := TimeGridServiceSimulation.TASK_DUE_TICKS[_task]
				while service.state.service_tick < due:
					step_for_test(1)


func _move_fixture_cursor(target: Vector2i) -> void:
	while service.state.cursor.x != target.x:
		step_for_test(1, Vector2i(signi(target.x - service.state.cursor.x), 0), true)
	while service.state.cursor.y != target.y:
		step_for_test(1, Vector2i(0, signi(target.y - service.state.cursor.y)), true)


func _complete_excellent_fixture() -> void:
	start_for_test()
	for task: int in range(TimeGridServiceSimulation.TASK_STATIONS.size()):
		var station := TimeGridServiceSimulation.TASK_STATIONS[task]
		_move_fixture_cursor(Vector2i(station % 3, station / 3))
		step_for_test(1, Vector2i.ZERO, true, true)
		var due := TimeGridServiceSimulation.TASK_DUE_TICKS[task]
		while service.state.service_tick < due:
			step_for_test(1)


func _handle_pause_action(action: StringName) -> bool:
	if action in [GameInput.MOVE_UP, GameInput.MOVE_LEFT]:
		_pause_focus = posmod(_pause_focus - 1, 3)
	elif action in [GameInput.MOVE_DOWN, GameInput.MOVE_RIGHT]:
		_pause_focus = posmod(_pause_focus + 1, 3)
	elif action in [GameInput.CANCEL, GameInput.PAUSE]:
		host.toggle_pause()
	elif action == GameInput.CONFIRM:
		match _pause_focus:
			0: host.toggle_pause()
			1: _retry_attempt()
			2: host.accept_loss()
	else:
		return false
	queue_redraw()
	return true


func _retry_attempt() -> void:
	host.retry()
	final_result = null
	_fixed_accumulator = 0.0
	_queued_direction = Vector2i.ZERO
	_queue_pressed = false
	_completion_emitted = false
	queue_redraw()


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
	_draw_shell(foreground, background)
	if service == null:
		return
	if service.is_paused:
		_draw_active(foreground, background)
		_draw_pause(foreground, background)
	elif service.state.phase == TimeGridServiceState.Phase.TUTORIAL:
		_draw_tutorial(foreground, background)
	elif service.state.phase == TimeGridServiceState.Phase.ACTIVE:
		_draw_active(foreground, background)
	else:
		_draw_result(foreground, background)


func _draw_shell(foreground: Color, background: Color) -> void:
	var font := _font()
	draw_rect(Rect2(4, 2, 312, 17), background)
	draw_rect(Rect2(4, 2, 312, 17), foreground, false, 1.0)
	draw_string(font, Vector2(8, 15), _t(&"ui.minigame.time_grid.title"), HORIZONTAL_ALIGNMENT_LEFT, 245, _compact_font_size(), foreground)
	var count_text := "0/6"
	if service != null:
		count_text = "OK %d/6" % service.state.completed_tasks if service.state.phase == TimeGridServiceState.Phase.RESULT else "%d/6" % service.state.task_index
	draw_string(font, Vector2(250, 15), count_text, HORIZONTAL_ALIGNMENT_RIGHT, 60, _compact_font_size(), foreground)
	draw_rect(Rect2(4, 160, 312, 18), background)
	draw_rect(Rect2(4, 160, 312, 18), foreground, false, 1.0)
	var footer := _footer_text()
	draw_string(font, Vector2(8, 174), footer, HORIZONTAL_ALIGNMENT_CENTER, 304, _compact_font_size(), foreground)


func _draw_tutorial(foreground: Color, background: Color) -> void:
	var font := _font()
	draw_rect(Rect2(10, 25, 300, 129), background)
	draw_rect(Rect2(10, 25, 300, 129), foreground, false, 2.0)
	draw_string(font, Vector2(18, 42), _t(&"ui.minigame.time_grid.objective"), HORIZONTAL_ALIGNMENT_CENTER, 284, _body_font_size(), foreground)
	var lines := PixelTextWrapper.wrap(_t(&"ui.minigame.time_grid.tutorial"), font, 274, _body_font_size(), _locale, 4)
	for index: int in range(lines.size()):
		draw_string(font, Vector2(23, 62 + index * _line_height()), lines[index], HORIZONTAL_ALIGNMENT_CENTER, 274, _body_font_size(), foreground)
	_draw_clock(Vector2(75, 115), true, foreground, background)
	_draw_ticket(Rect2(119, 95, 84, 42), 4, foreground, background)
	_draw_clock(Vector2(245, 115), false, foreground, background)


func _draw_active(foreground: Color, background: Color) -> void:
	var font := _font()
	var stopped := service.state.time_stopped
	draw_rect(Rect2(7, 24, 306, 132), background)
	draw_rect(Rect2(7, 24, 306, 132), foreground, false, 2.0)
	var status_key := &"ui.minigame.time_grid.status.release" if stopped and service.state.queued_station >= 0 else (&"ui.minigame.time_grid.status.stopped" if stopped else &"ui.minigame.time_grid.status.running")
	if ui_scale_percent() > 100:
		status_key = &"ui.minigame.time_grid.status.release.large" if stopped and service.state.queued_station >= 0 else (&"ui.minigame.time_grid.status.stopped.large" if stopped else &"ui.minigame.time_grid.status.running.large")
	var status_size := _body_font_size()
	draw_string(font, Vector2(13, 39), _t(status_key), HORIZONTAL_ALIGNMENT_LEFT, 205, status_size, foreground)
	var timer := "%s %02d" % [_t(&"ui.minigame.time_grid.time"), ceili(service.state.remaining_ticks / 60.0)]
	if service.assists.any_enabled():
		timer = _t(&"ui.minigame.time_grid.assist.summary")
	draw_string(font, Vector2(166, 39), timer, HORIZONTAL_ALIGNMENT_RIGHT, 138, _compact_font_size(), foreground)
	_draw_grid(Rect2(18, 48, 132, 86), foreground, background)
	_draw_order_panel(Rect2(160, 48, 142, 86), foreground, background)
	_draw_stock(Rect2(18, 151, 284, 8), foreground, background)


func _draw_grid(rect: Rect2, foreground: Color, background: Color) -> void:
	var station_labels := ["A", "B", "C", "D", "E", "F", "G", "H", "I"]
	var cell := Vector2(rect.size.x / 3.0, rect.size.y / 3.0)
	for index: int in range(9):
		var position := rect.position + Vector2(index % 3, index / 3) * cell
		var cell_rect := Rect2(position, cell)
		draw_rect(cell_rect, foreground, false, 1.0)
		if index == service.state.queued_station:
			_draw_dither(cell_rect.grow(-3), foreground)
		if Vector2i(index % 3, index / 3) == service.state.cursor:
			draw_rect(cell_rect.grow(-2), background)
			draw_rect(cell_rect.grow(-3), foreground, false, 2.0)
		draw_string(_latin_font, position + Vector2(2, 19), station_labels[index], HORIZONTAL_ALIGNMENT_CENTER, cell.x - 4, 12, foreground)


func _draw_order_panel(rect: Rect2, foreground: Color, background: Color) -> void:
	var font := _font()
	draw_rect(rect, foreground, false, 1.0)
	draw_string(font, rect.position + Vector2(6, 13), _t(&"ui.minigame.time_grid.orders"), HORIZONTAL_ALIGNMENT_LEFT, 82, _compact_font_size(), foreground)
	var due := service.current_due_tick()
	var remaining := maxi(0, due - service.state.service_tick)
	draw_string(font, rect.position + Vector2(82, 13), "%s %02d" % [_t(&"ui.minigame.time_grid.due"), ceili(remaining / 60.0)], HORIZONTAL_ALIGNMENT_RIGHT, 52, _compact_font_size(), foreground)
	if service.current_station() >= 0:
		_draw_ticket(Rect2(rect.position + Vector2(7, 20), Vector2(128, 38)), service.current_station(), foreground, background)
	var queue_key := &"ui.minigame.time_grid.queued" if service.state.queued_station >= 0 else &"ui.minigame.time_grid.not_queued"
	draw_string(font, rect.position + Vector2(7, 72), _t(queue_key), HORIZONTAL_ALIGNMENT_LEFT, 128, _compact_font_size(), foreground)
	draw_string(font, rect.position + Vector2(7, 82), "%s %d  %s %d" % [_t(&"ui.minigame.time_grid.done"), service.state.completed_tasks, _t(&"ui.minigame.time_grid.missed"), service.state.missed_tasks], HORIZONTAL_ALIGNMENT_LEFT, 128, _compact_font_size(), foreground)


func _draw_ticket(rect: Rect2, station: int, foreground: Color, background: Color) -> void:
	var labels := ["A", "B", "C", "D", "E", "F", "G", "H", "I"]
	draw_rect(rect, background)
	draw_rect(rect, foreground, false, 2.0)
	for y: int in range(floori(rect.position.y + 4), floori(rect.end.y - 3), 4):
		draw_line(Vector2(rect.position.x + 5, y), Vector2(rect.position.x + 10, y), foreground, 1.0)
	draw_string(_font(), rect.position + Vector2(14, 15), _t(&"ui.minigame.time_grid.ticket"), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 42, _compact_font_size(), foreground)
	draw_string(_latin_font, rect.position + Vector2(rect.size.x - 28, 29), labels[clampi(station, 0, 8)], HORIZONTAL_ALIGNMENT_CENTER, 20, 18, foreground)


func _draw_stock(rect: Rect2, foreground: Color, background: Color) -> void:
	draw_string(_font(), Vector2(rect.position.x, rect.position.y - 2), _t(&"ui.minigame.time_grid.stock"), HORIZONTAL_ALIGNMENT_LEFT, 65, _compact_font_size(), foreground)
	var bar := Rect2(rect.position + Vector2(68, -8), Vector2(rect.size.x - 68, rect.size.y))
	draw_rect(bar, foreground, false, 1.0)
	var ratio := service.state.stop_stock / float(TimeGridServiceSimulation.MAX_STOP_STOCK)
	if service.state.time_stopped:
		_draw_dither(Rect2(bar.position + Vector2(2, 2), Vector2((bar.size.x - 4) * ratio, bar.size.y - 4)), foreground)
	else:
		draw_rect(Rect2(bar.position + Vector2(2, 2), Vector2((bar.size.x - 4) * ratio, bar.size.y - 4)), foreground)


func _draw_pause(foreground: Color, background: Color) -> void:
	var font := _font()
	draw_rect(Rect2(62, 37, 196, 113), background)
	draw_rect(Rect2(62, 37, 196, 113), foreground, false, 2.0)
	draw_string(font, Vector2(70, 56), _t(&"ui.minigame.time_grid.paused"), HORIZONTAL_ALIGNMENT_CENTER, 180, _body_font_size(), foreground)
	var keys: Array[StringName] = [&"ui.minigame.time_grid.pause.resume", &"ui.minigame.time_grid.pause.retry", &"ui.minigame.time_grid.pause.accept_loss"]
	for index: int in range(keys.size()):
		var rect := Rect2(80, 69 + index * 23, 160, 18)
		draw_rect(rect, foreground, false, 1.0)
		if index == _pause_focus:
			draw_rect(rect.grow(-2), foreground, false, 1.0)
		draw_string(font, rect.position + Vector2(5, 13), _t(keys[index]), HORIZONTAL_ALIGNMENT_CENTER, 150, _body_font_size(), foreground)


func _draw_result(foreground: Color, background: Color) -> void:
	var font := _font()
	var tag := final_result.result_tag if final_result != null else service.state.result_tag
	var title_key := StringName("ui.minigame.time_grid.result.%s.title" % tag)
	var body_key := StringName("ui.minigame.time_grid.result.%s.body" % tag)
	draw_rect(Rect2(18, 29, 284, 123), background)
	draw_rect(Rect2(18, 29, 284, 123), foreground, false, 2.0)
	draw_string(font, Vector2(28, 49), _t(title_key), HORIZONTAL_ALIGNMENT_CENTER, 264, _body_font_size(), foreground)
	_draw_result_stamp(Vector2(160, 78), tag, foreground, background)
	var lines := PixelTextWrapper.wrap(_t(body_key), font, 250, _body_font_size(), _locale, 3)
	for index: int in range(lines.size()):
		draw_string(font, Vector2(35, 112 + index * _line_height()), lines[index], HORIZONTAL_ALIGNMENT_CENTER, 250, _body_font_size(), foreground)
	if final_result != null and final_result.used_assist:
		draw_string(font, Vector2(30, 146), _t(&"ui.minigame.time_grid.assists_used"), HORIZONTAL_ALIGNMENT_LEFT, 260, _compact_font_size(), foreground)


func _draw_clock(origin: Vector2, stopped: bool, foreground: Color, background: Color) -> void:
	draw_circle(origin, 19, foreground)
	draw_circle(origin, 16, background)
	draw_line(origin, origin + Vector2(0, -11), foreground, 2.0)
	draw_line(origin, origin + (Vector2(-8, 6) if stopped else Vector2(8, 6)), foreground, 2.0)
	if stopped:
		draw_rect(Rect2(origin + Vector2(-25, -5), Vector2(5, 10)), foreground)
		draw_rect(Rect2(origin + Vector2(20, -5), Vector2(5, 10)), foreground)


func _draw_result_stamp(origin: Vector2, tag: StringName, foreground: Color, background: Color) -> void:
	draw_circle(origin, 20, foreground)
	draw_circle(origin, 16, background)
	if tag == &"excellent":
		draw_line(origin + Vector2(-10, 1), origin + Vector2(-3, 9), foreground, 3.0)
		draw_line(origin + Vector2(-3, 9), origin + Vector2(11, -9), foreground, 3.0)
	elif tag == &"clear":
		draw_rect(Rect2(origin - Vector2(9, 6), Vector2(18, 12)), foreground, false, 2.0)
	else:
		draw_line(origin + Vector2(-9, -9), origin + Vector2(9, 9), foreground, 2.0)
		draw_line(origin + Vector2(9, -9), origin + Vector2(-9, 9), foreground, 2.0)


func _draw_dither(rect: Rect2, foreground: Color) -> void:
	for y: int in range(floori(rect.position.y), ceili(rect.end.y)):
		for x: int in range(floori(rect.position.x), ceili(rect.end.x)):
			if (x + y) % 2 == 0:
				draw_rect(Rect2(x, y, 1, 1), foreground)


func _footer_text() -> String:
	if service == null:
		return ""
	if service.is_paused:
		return "%s %s  %s %s  %s %s" % [_movement_binding(), _t(&"ui.minigame.time_grid.select"), input_binding(GameInput.CONFIRM), _t(&"ui.common.confirm"), input_binding(GameInput.CANCEL), _t(&"ui.common.cancel")]
	if service.state.phase == TimeGridServiceState.Phase.TUTORIAL:
		return input_hint(GameInput.CONFIRM, _t(&"ui.minigame.time_grid.start"))
	if service.state.phase == TimeGridServiceState.Phase.RESULT:
		return "%s %s  %s %s" % [input_binding(GameInput.CONFIRM), _t(&"ui.minigame.time_grid.continue"), input_binding(GameInput.CANCEL), _t(&"ui.minigame.time_grid.retry")]
	if service.state.time_stopped and service.state.queued_station >= 0:
		return input_hint(GameInput.FOCUS, _t(&"ui.minigame.time_grid.release"))
	return "%s %s  %s %s  %s %s" % [_movement_binding(), _t(&"ui.input.move"), input_binding(GameInput.FOCUS), _t(&"ui.minigame.time_grid.stop"), input_binding(GameInput.CONFIRM), _t(&"ui.minigame.time_grid.queue")]


func _movement_binding() -> String:
	var glyph_service := get_node_or_null("/root/InputGlyphService")
	if glyph_service != null:
		return _catalog.text(glyph_service.glyph_key(GameInput.MOVE_UP), _locale)
	return "[ARROWS]"


func _t(key: StringName) -> String:
	return _catalog.text(key, _locale)


func _font() -> Font:
	return _japanese_font if _locale == &"ja" else _latin_font


func _body_font_size() -> int:
	return scaled_ui_pixels(12 if _locale == &"ja" else 8)


func _compact_font_size() -> int:
	var base := (9 if ui_scale_percent() > 100 else 10) if _locale == &"ja" else (7 if ui_scale_percent() > 100 else 8)
	return scaled_ui_pixels(base)


func _line_height() -> int:
	return _body_font_size() + (4 if ui_scale_percent() > 100 else 2)
