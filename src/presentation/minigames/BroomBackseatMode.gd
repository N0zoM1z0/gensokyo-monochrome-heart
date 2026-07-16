class_name BroomBackseatMode
extends GameMode
## One-bit Forest of Magic cargo run; every landing continues the route.

const ACTION_CONTRACT := ["move", "confirm", "cancel", "pause"]
@export_enum("tutorial", "active", "result") var fixture_state := "tutorial"

var host := MinigameHost.new()
var broom := BroomBackseatSimulation.new()
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
	if is_node_ready(): _load_runtime()

func configure_fixture(requested_profile: StringName, locale: StringName, forced_profile: StringName = &"", _reduced: bool = false, _safe: bool = false) -> void:
	_profile = PresentationProfileRegistry.resolve(forced_profile if forced_profile != &"" else requested_profile)
	_locale = locale if locale in [&"en", &"ja"] else &"en"
	if is_node_ready(): _load_runtime()

func handle_semantic_action(action: StringName) -> bool:
	if broom == null: return false
	if action in [GameInput.PAUSE, GameInput.CANCEL] and broom.state.phase != BroomBackseatState.Phase.RESULT:
		host.toggle_pause(); queue_redraw(); return true
	if broom.is_paused:
		if action in [GameInput.PAUSE, GameInput.CANCEL, GameInput.CONFIRM]: host.toggle_pause(); queue_redraw(); return true
	if broom.state.phase == BroomBackseatState.Phase.TUTORIAL and action == GameInput.CONFIRM:
		_step(0, true); return true
	if broom.state.phase == BroomBackseatState.Phase.ACTIVE:
		if action == GameInput.CONFIRM: _step(0, true); return true
		if action == GameInput.MOVE_LEFT: _step(-1); return true
		if action == GameInput.MOVE_RIGHT: _step(1); return true
	if broom.state.phase == BroomBackseatState.Phase.RESULT and action == GameInput.CONFIRM and final_result != null and not _completion_emitted:
		_completion_emitted = true; mode_completed.emit(final_result); return true
	return false

func resolve_input_candidates(candidates: Array[StringName]) -> StringName:
	return GameInput.first_matching(candidates, [GameInput.PAUSE, GameInput.CONFIRM, GameInput.MOVE_LEFT, GameInput.MOVE_RIGHT, GameInput.CANCEL])

func action_contract() -> PackedStringArray: return PackedStringArray(ACTION_CONTRACT)
func resolved_profile_id() -> StringName: return _profile.profile_id

func _default_context() -> ModeContext:
	var context := ModeContext.new(); context.mode_id = &"mini.mrs.broom_backseat"; context.event_id = &"evt.mrs.crash_landing"; context.node_id = &"n_broom"; context.deterministic_seed = 1501; return context

func _load_runtime() -> void:
	host = MinigameHost.new(); host.result_ready.connect(func(result: ModeResult): final_result = result; checkpoint_requested.emit(&"minigame_result"); queue_redraw())
	broom = BroomBackseatSimulation.new(); host.load_minigame(broom, mode_context if mode_context != null else _default_context(), assist_settings)
	final_result = null; _completion_emitted = false
	if fixture_state == "active": _step(0, true)
	if fixture_state == "result":
		_step(0, true)
		for target: int in BroomBackseatSimulation.TARGET_LANES:
			while broom.state.cargo_lane != target: _step(1 if target > broom.state.cargo_lane else -1)
			_step(0, true)
	queue_redraw()

func _step(direction: int, confirm: bool = false) -> void:
	var frame := MinigameInputFrame.new(); frame.grid_direction.x = direction; frame.confirm_pressed = confirm; host.step(frame); queue_redraw()

func _draw() -> void:
	var bg := _profile.ink if _profile.is_inverted else _profile.paper
	var fg := _profile.paper if _profile.is_inverted else _profile.ink
	draw_rect(Rect2(0, 0, 320, 180), bg); draw_rect(Rect2(4, 3, 312, 174), fg, false, 1.0)
	_draw_text(&"ui.minigame.broom_backseat.title", Vector2(10, 17), 300, fg)
	if broom.state.phase == BroomBackseatState.Phase.TUTORIAL:
		_draw_text(&"ui.minigame.broom_backseat.tutorial", Vector2(20, 58), 280, fg); _draw_text(&"ui.minigame.broom_backseat.begin", Vector2(20, 165), 280, fg); return
	for x: int in [64, 160, 256]: draw_line(Vector2(x, 44), Vector2(x, 134), fg, 1.0)
	draw_line(Vector2(20, 90), Vector2(300, 90), fg, 1.0)
	var lane_x: int = [64, 160, 256][broom.state.cargo_lane + 1]
	var target_x: int = [64, 160, 256][broom.target_lane() + 1]
	draw_rect(Rect2(target_x - 14, 53, 28, 18), fg, false, 2.0); draw_rect(Rect2(lane_x - 10, 102, 20, 12), fg)
	_draw_text(&"ui.minigame.broom_backseat.status", Vector2(16, 151), 288, fg, [broom.state.checkpoint_index + 1, BroomBackseatSimulation.TARGET_LANES.size()])
	if broom.state.phase == BroomBackseatState.Phase.RESULT: _draw_text(&"ui.minigame.broom_backseat.result", Vector2(16, 166), 288, fg)

func _draw_text(key: StringName, position: Vector2, width: float, color: Color, values: Array = []) -> void:
	var text := _catalog.text(key, _locale)
	for index: int in range(values.size()): text = text.replace("{%d}" % index, str(values[index]))
	draw_string(_japanese_font if _locale == &"ja" else _latin_font, position, text, HORIZONTAL_ALIGNMENT_CENTER, width, 8, color)
