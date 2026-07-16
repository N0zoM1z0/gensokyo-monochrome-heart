class_name FiveImpossibleErrandsMode
extends GameMode
## One-bit shell for five modular requests with three equally valid stances.

const ACTION_CONTRACT := ["move", "confirm", "cancel", "pause"]

@export_enum("tutorial", "active", "refusal", "result") var fixture_state := "tutorial"

var host := MinigameHost.new()
var errands := FiveImpossibleErrandsSimulation.new()
var final_result: ModeResult

var _profile: PresentationProfile = PresentationProfileRegistry.resolve(&"C")
var _locale: StringName = &"en"
var _catalog := UiTextCatalog.new()
var _latin_font: Font
var _japanese_font: Font
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


func switch_locale(next_locale: StringName) -> void:
	if next_locale in [&"en", &"ja"]:
		_locale = next_locale
		queue_redraw()


func handle_semantic_action(action: StringName) -> bool:
	if errands == null:
		return false
	if errands.is_paused:
		if action in [GameInput.CONFIRM, GameInput.CANCEL, GameInput.PAUSE]:
			host.toggle_pause()
			queue_redraw()
			return true
		return false
	match errands.state.phase:
		FiveImpossibleErrandsState.Phase.TUTORIAL:
			if action == GameInput.CONFIRM:
				_start_for_test()
				return true
		FiveImpossibleErrandsState.Phase.ACTIVE:
			if action in [GameInput.MOVE_LEFT, GameInput.MOVE_UP]:
				_step_choice(-1, false)
				return true
			if action in [GameInput.MOVE_RIGHT, GameInput.MOVE_DOWN]:
				_step_choice(1, false)
				return true
			if action == GameInput.CONFIRM:
				_step_choice(0, true)
				return true
			if action in [GameInput.PAUSE, GameInput.CANCEL]:
				host.toggle_pause()
				queue_redraw()
				return true
		FiveImpossibleErrandsState.Phase.RESULT:
			if action == GameInput.CONFIRM:
				_emit_completion_once()
				return true
			if action == GameInput.CANCEL:
				host.retry()
				final_result = null
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
		"phase": errands.state.phase if errands != null else -1,
		"errand_index": errands.state.errand_index if errands != null else -1,
		"option_cursor": errands.state.option_cursor if errands != null else -1,
		"choices": errands.state.choices.duplicate() if errands != null else [],
		"paused": errands.is_paused if errands != null else false,
		"result": String(final_result.result_tag) if final_result != null else "",
	}, true)
	return state


func select_approach_for_test(approach_index: int) -> ModeResult:
	if errands.state.phase == FiveImpossibleErrandsState.Phase.TUTORIAL:
		_start_for_test()
	while errands.state.option_cursor < clampi(approach_index, 0, 2):
		_step_choice(1, false)
	while errands.state.option_cursor > clampi(approach_index, 0, 2):
		_step_choice(-1, false)
	return _step_choice(0, true)


func _default_context() -> ModeContext:
	var context := ModeContext.new()
	context.mode_type = &"start_minigame"
	context.mode_id = &"mini.ein.five_impossible_errands"
	context.event_id = &"evt.ein.five_impossibilities"
	context.node_id = &"n_errands"
	context.deterministic_seed = 13003
	return context


func _load_runtime() -> void:
	host = MinigameHost.new()
	host.result_ready.connect(_on_result_ready)
	errands = FiveImpossibleErrandsSimulation.new()
	host.load_minigame(errands, mode_context if mode_context != null else _default_context(), MinigameAssistSettings.new())
	final_result = null
	_completion_emitted = false
	_prepare_fixture_state()
	queue_redraw()


func _prepare_fixture_state() -> void:
	if fixture_state == "tutorial":
		return
	_start_for_test()
	match fixture_state:
		"refusal":
			select_approach_for_test(0)
			select_approach_for_test(1)
			_step_choice(1, false)
			_step_choice(1, false)
		"result":
			for choice: int in [0, 1, 2, 1, 0]:
				select_approach_for_test(choice)


func _start_for_test() -> void:
	var frame := MinigameInputFrame.new()
	frame.confirm_pressed = true
	host.step(frame)
	queue_redraw()


func _step_choice(direction: int, confirm: bool) -> ModeResult:
	var frame := MinigameInputFrame.new()
	frame.choice_direction = direction
	frame.confirm_pressed = confirm
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
	_draw_header(foreground, background)
	if errands == null:
		return
	if errands.state.phase == FiveImpossibleErrandsState.Phase.TUTORIAL:
		_draw_tutorial(foreground, background)
	elif errands.state.phase == FiveImpossibleErrandsState.Phase.RESULT:
		_draw_result(foreground, background)
	else:
		_draw_active(foreground, background)
	if errands.is_paused:
		_draw_pause(foreground, background)


func _draw_header(foreground: Color, background: Color) -> void:
	var rect := Rect2(4, 2, 312, 18)
	draw_rect(rect, background)
	draw_rect(rect, foreground, false, 1.0)
	draw_string(_font(), Vector2(8, 15), _t(&"ui.minigame.errands.title"), HORIZONTAL_ALIGNMENT_LEFT, 214, _compact_size(), foreground)
	var current := 0
	if errands != null:
		current = errands.state.errand_index
		if errands.state.phase == FiveImpossibleErrandsState.Phase.ACTIVE:
			current += 1
	draw_string(_font(), Vector2(274, 15), "%d/5" % current, HORIZONTAL_ALIGNMENT_RIGHT, 34, _body_size(), foreground)
	if errands != null:
		for index: int in range(5):
			_draw_progress_mark(Vector2(226 + index * 9, 7), index, foreground, background)


func _draw_tutorial(foreground: Color, background: Color) -> void:
	_draw_kaguya(Vector2(266, 89), foreground, background)
	draw_string(_font(), Vector2(16, 39), _t(&"ui.minigame.errands.tutorial.header"), HORIZONTAL_ALIGNMENT_LEFT, 210, _title_size(), foreground)
	_draw_wrapped(&"ui.minigame.errands.tutorial.body", Rect2(16, 49, 205, 47), 4, foreground)
	for index: int in range(3):
		var rect := Rect2(10 + index * 101, 105, 96, 41)
		_draw_approach_card(rect, index, false, foreground, background, false)
	_draw_footer(&"ui.minigame.errands.tutorial.footer", foreground, background)


func _draw_active(foreground: Color, background: Color) -> void:
	var errand := errands.current_errand()
	if errand == null:
		return
	draw_rect(Rect2(8, 24, 304, 74), foreground, false, 1.0)
	_draw_treasure_icon(errand.trial_kind, Vector2(48, 61), foreground, background)
	draw_string(_font(), Vector2(84, 39), _t(errand.treasure_key), HORIZONTAL_ALIGNMENT_LEFT, 216, _title_size(), foreground)
	_draw_wrapped(errand.request_key, Rect2(84, 45, 216, 28), 2, foreground)
	draw_string(_font(), Vector2(84, 91), _t(errand.rule_key), HORIZONTAL_ALIGNMENT_LEFT, 216, _compact_size(), foreground)
	for index: int in range(3):
		var rect := Rect2(10 + index * 101, 103, 96, 43)
		_draw_approach_card(rect, index, index == errands.state.option_cursor, foreground, background, true)
	var option := errands.current_option()
	if option != null:
		draw_string(_font(), Vector2(10, 158), _t(option.consequence_key), HORIZONTAL_ALIGNMENT_CENTER, 300, _compact_size(), foreground)
	_draw_footer(&"ui.minigame.errands.active.footer", foreground, background)


func _draw_result(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(20, 29, 280, 124), foreground, false, 2.0)
	draw_string(_font(), Vector2(30, 48), _t(&"ui.minigame.errands.result.header"), HORIZONTAL_ALIGNMENT_CENTER, 260, _title_size(), foreground)
	_draw_kaguya(Vector2(262, 96), foreground, background)
	for index: int in range(errands.state.choices.size()):
		var center := Vector2(48 + index * 42, 82)
		var approach_index := FiveImpossibleErrandsCatalog.APPROACHES.find(errands.state.choices[index])
		_draw_approach_symbol(center, approach_index, foreground, background)
		var approach_key := StringName("ui.minigame.errands.approach.%s" % FiveImpossibleErrandsCatalog.APPROACHES[approach_index])
		var short_label := _t(approach_key).substr(0, 1)
		draw_string(_font(), center + Vector2(-14, 23), "%d%s" % [index + 1, short_label], HORIZONTAL_ALIGNMENT_CENTER, 28, _compact_size(), foreground)
	draw_string(_font(), Vector2(35, 114), _t(&"ui.minigame.errands.result.legend"), HORIZONTAL_ALIGNMENT_CENTER, 195, _compact_size(), foreground)
	_draw_wrapped(&"ui.minigame.errands.result.body", Rect2(35, 118, 195, 31), 3, foreground, true)
	_draw_footer(&"ui.minigame.errands.result.footer", foreground, background)


func _draw_pause(foreground: Color, background: Color) -> void:
	draw_rect(Rect2(56, 57, 208, 62), background)
	draw_rect(Rect2(56, 57, 208, 62), foreground, false, 2.0)
	draw_string(_font(), Vector2(66, 79), _t(&"ui.minigame.errands.paused"), HORIZONTAL_ALIGNMENT_CENTER, 188, _title_size(), foreground)
	_draw_wrapped(&"ui.minigame.errands.pause.body", Rect2(66, 88, 188, 23), 2, foreground)


func _draw_approach_card(rect: Rect2, index: int, selected: bool, foreground: Color, background: Color, show_action: bool) -> void:
	draw_rect(rect, background)
	draw_rect(rect, foreground, false, 2.0 if selected else 1.0)
	if selected:
		draw_rect(rect.grow(-3), foreground, false, 1.0)
	_draw_approach_symbol(rect.position + Vector2(12, 12), index, foreground, background)
	var approach := FiveImpossibleErrandsCatalog.APPROACHES[index]
	draw_string(_font(), rect.position + Vector2(24, 14), _t(StringName("ui.minigame.errands.approach.%s" % approach)), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28, _compact_size(), foreground)
	if show_action:
		var errand := errands.current_errand()
		var lines := PixelTextWrapper.wrap(_t(errand.options[index].action_key), _font(), rect.size.x - 10, _compact_size(), _locale, 2)
		for line_index: int in range(lines.size()):
			draw_string(_font(), rect.position + Vector2(5, 28 + line_index * _line_height()), lines[line_index], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 10, _compact_size(), foreground)
	else:
		var guide_key := StringName("ui.minigame.errands.approach.%s.guide" % approach)
		var guide_lines := PixelTextWrapper.wrap(_t(guide_key), _font(), rect.size.x - 10, _compact_size(), _locale, 2)
		for line_index: int in range(guide_lines.size()):
			draw_string(_font(), rect.position + Vector2(5, 28 + line_index * _line_height()), guide_lines[line_index], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 10, _compact_size(), foreground)


func _draw_progress_mark(origin: Vector2, index: int, foreground: Color, background: Color) -> void:
	if index >= errands.state.choices.size():
		draw_rect(Rect2(origin, Vector2(6, 6)), foreground, false, 1.0)
		return
	var approach_index := FiveImpossibleErrandsCatalog.APPROACHES.find(errands.state.choices[index])
	_draw_approach_symbol(origin + Vector2(3, 3), approach_index, foreground, background, 3)


func _draw_approach_symbol(center: Vector2, index: int, foreground: Color, background: Color, radius: int = 7) -> void:
	match index:
		0:
			draw_rect(Rect2(center - Vector2(radius, radius), Vector2(radius * 2, radius * 2)), foreground, false, 1.0)
		1:
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(0, -radius), center + Vector2(radius, radius), center + Vector2(-radius, radius),
			]), foreground)
			draw_circle(center + Vector2(0, 2), maxi(1, radius - 3), background)
		2:
			draw_circle(center, radius, foreground, false, 1.0)
			draw_line(center + Vector2(-radius + 2, radius - 2), center + Vector2(radius - 2, -radius + 2), foreground, 1.0)


func _draw_treasure_icon(kind: StringName, center: Vector2, foreground: Color, background: Color) -> void:
	match kind:
		&"balance":
			draw_line(center + Vector2(-18, -12), center + Vector2(18, -12), foreground, 2.0)
			draw_line(center + Vector2(0, -22), center + Vector2(0, 18), foreground, 2.0)
			draw_arc(center + Vector2(-13, -2), 10, 0.0, PI, 12, foreground, 2.0)
		&"arrange":
			draw_line(center + Vector2(-15, 18), center + Vector2(12, -19), foreground, 2.0)
			for offset: Vector2 in [Vector2(-9, 8), Vector2(0, -4), Vector2(9, -15)]:
				draw_circle(center + offset, 5, foreground, false, 1.0)
		&"test":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-17, -15), center + Vector2(-7, -22), center + Vector2(0, -14),
				center + Vector2(7, -22), center + Vector2(17, -15), center + Vector2(12, 19), center + Vector2(-12, 19),
			]), foreground)
			draw_rect(Rect2(center + Vector2(-9, -11), Vector2(18, 25)), background)
		&"align":
			draw_circle(center, 19, foreground, false, 2.0)
			draw_circle(center, 7, foreground)
			draw_line(center + Vector2(-25, 0), center + Vector2(25, 0), foreground, 1.0)
		&"wait":
			draw_arc(center, 18, 0.0, PI, 16, foreground, 2.0)
			draw_circle(center + Vector2(0, -2), 6, foreground, false, 1.0)
			draw_line(center + Vector2(0, -2), center + Vector2(4, -7), foreground, 1.0)


func _draw_kaguya(center: Vector2, foreground: Color, background: Color) -> void:
	# Absolute vertical hair column and one-step fan keep her readable at pocket scale.
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-16, -38), center + Vector2(10, -38), center + Vector2(17, 35),
		center + Vector2(-20, 35),
	]), foreground)
	draw_circle(center + Vector2(-2, -25), 10, background)
	draw_rect(Rect2(center + Vector2(-9, -10), Vector2(18, 38)), background)
	draw_arc(center + Vector2(-15, 0), 15, -1.2, 0.6, 10, foreground, 2.0)
	for spoke: int in range(4):
		draw_line(center + Vector2(-15, 0), center + Vector2(-3 + spoke * 4, -10 + spoke * 2), foreground, 1.0)


func _draw_footer(key: StringName, foreground: Color, background: Color) -> void:
	draw_rect(Rect2(4, 164, 312, 14), background)
	draw_rect(Rect2(4, 164, 312, 14), foreground, false, 1.0)
	draw_string(_font(), Vector2(8, 175), _t(key), HORIZONTAL_ALIGNMENT_CENTER, 304, _compact_size(), foreground)


func _draw_wrapped(key: StringName, rect: Rect2, maximum_lines: int, foreground: Color, centered: bool = false) -> void:
	var lines := PixelTextWrapper.wrap(_t(key), _font(), rect.size.x, _body_size(), _locale, maximum_lines)
	for index: int in range(lines.size()):
		draw_string(
			_font(), rect.position + Vector2(0, _body_size() + index * _line_height()), lines[index],
			HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT,
			rect.size.x, _body_size(), foreground
		)


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
