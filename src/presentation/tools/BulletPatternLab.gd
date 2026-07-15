class_name BulletPatternLab
extends Control
## Interactive M11 data-only preview over the production fixed-step simulation.

const FIELD_ORIGIN := Vector2(3, 22)
const FIELD_SIZE := Vector2(224, 145)
const DENSITIES := [55, 70, 85, 100]
const SPEEDS := [70, 80, 90, 100]

@export_file("*.json") var pattern_path: String = "res://content/danmaku/boundary_stain.json"
@export_range(0, 2, 1) var fixture_phase: int = 0
@export_range(0, 1080, 1) var fixture_ticks: int = 0
@export_enum("55", "70", "85", "100") var fixture_density: String = "100"
@export var fixture_help: bool = false

var definition: DanmakuPatternDefinition
var runtime: BoundaryStainSimulation
var errors: Array[String] = []
var selected_phase: int = 0
var selected_emitter: int = 0
var density_percent: int = 100
var speed_percent: int = 100
var is_paused: bool = false
var show_help: bool = false
var peak_active: int = 0
var reload_count: int = 0

var _locale: StringName = &"en"
var _accumulator: float = 0.0
var _batch_renderer := DanmakuBulletBatchRenderer.new()
var _catalog := UiTextCatalog.new()
var _latin_font: Font
var _japanese_font: Font


func configure_pattern(path: String) -> void:
	pattern_path = path
	if is_inside_tree():
		_reload_pattern()


func configure_fixture(
	_profile_id: StringName,
	locale: StringName,
	_forced_profile: StringName = &"",
	_reduced_motion: bool = false,
	_safe_flash: bool = false
) -> void:
	_locale = locale if locale in [&"en", &"ja"] else &"en"
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	_latin_font = UiFontRegistry.latin()
	_japanese_font = UiFontRegistry.japanese()
	_catalog.load_default()
	density_percent = int(fixture_density)
	selected_phase = fixture_phase
	show_help = fixture_help
	_reload_pattern()
	if runtime != null and fixture_ticks > 0:
		for _tick: int in range(fixture_ticks):
			_step_once()
		is_paused = true
	grab_focus()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if runtime == null or is_paused:
		return
	_accumulator += maxf(0.0, delta)
	var tick_seconds := 1.0 / BoundaryStainSimulation.TICKS_PER_SECOND
	var steps := 0
	while _accumulator >= tick_seconds and steps < 4:
		_accumulator -= tick_seconds
		_step_once()
		steps += 1
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_H:
			show_help = not show_help
		KEY_R:
			_reload_pattern()
		KEY_SPACE:
			is_paused = not is_paused
		KEY_PERIOD:
			is_paused = true
			_step_once()
		KEY_F:
			is_paused = true
			for _tick: int in range(60):
				_step_once()
		KEY_P:
			selected_phase = posmod(selected_phase + 1, 3)
			selected_emitter = 0
			_rebuild_runtime(true)
		KEY_D:
			density_percent = DENSITIES[(DENSITIES.find(density_percent) + 1) % DENSITIES.size()]
			_rebuild_runtime(true)
		KEY_S:
			speed_percent = SPEEDS[(SPEEDS.find(speed_percent) + 1) % SPEEDS.size()]
			_rebuild_runtime(true)
		KEY_E:
			var emitters := definition.phase(selected_phase).emitters if definition != null else []
			if not emitters.is_empty():
				selected_emitter = posmod(selected_emitter + 1, emitters.size())
		_:
			return
	accept_event()
	queue_redraw()


func _reload_pattern() -> void:
	errors.clear()
	var loader := DanmakuPatternLoader.new()
	definition = loader.load_path(pattern_path)
	errors.append_array(loader.errors)
	if definition == null or not errors.is_empty():
		runtime = null
		queue_redraw()
		return
	selected_phase = clampi(selected_phase, 0, definition.phases.size() - 1)
	selected_emitter = 0
	reload_count += 1
	_rebuild_runtime(true)


func _rebuild_runtime(seek_phase: bool) -> void:
	if definition == null:
		return
	var settings := DanmakuAssistSettings.new()
	settings.story_mode = false
	settings.density_percent = density_percent
	settings.bullet_speed_percent = speed_percent
	settings.safe_lane_preview = true
	var context := ModeContext.new()
	context.mode_type = &"start_danmaku"
	context.mode_id = definition.id
	context.event_id = &"evt.authoring.bullet_lab"
	context.node_id = &"lab_preview"
	context.deterministic_seed = 1111
	runtime = BoundaryStainSimulation.new()
	if not runtime.configure(definition, context, settings, 2500):
		errors.append("production simulation rejected the pattern")
		runtime = null
		return
	peak_active = 0
	_accumulator = 0.0
	if seek_phase and selected_phase > 0:
		var ticks_to_seek := 0
		for phase_index: int in range(selected_phase):
			ticks_to_seek += definition.phases[phase_index].duration_ticks
		for _tick: int in range(ticks_to_seek):
			_step_once()
	queue_redraw()


func _step_once() -> void:
	if runtime == null:
		return
	if runtime.final_result != null:
		_rebuild_runtime(true)
		return
	runtime.state.invulnerability_ticks = 4096
	runtime.step(DanmakuInputFrame.new())
	peak_active = maxi(peak_active, runtime.pool.active_count)
	if runtime.state.phase_index != selected_phase:
		selected_phase = runtime.state.phase_index
		selected_emitter = 0


func _draw() -> void:
	var background := Color.WHITE
	var foreground := Color.BLACK
	draw_rect(Rect2(0, 0, 320, 180), background)
	# The lab is a technical stable-ID surface; its compact ASCII telemetry uses
	# the reviewed Latin pixel font consistently in every preview locale.
	var font := _latin_font
	draw_string(font, Vector2(4, 13), "BULLET PATTERN LAB", HORIZONTAL_ALIGNMENT_LEFT, 148, _font_size(), foreground)
	draw_string(font, Vector2(154, 13), pattern_path.get_file(), HORIZONTAL_ALIGNMENT_RIGHT, 162, _small_size(), foreground)
	draw_rect(Rect2(FIELD_ORIGIN, FIELD_SIZE), foreground, false, 1.0)
	draw_rect(Rect2(230, 22, 87, 145), foreground, false, 1.0)
	if runtime == null:
		_draw_errors(font, foreground)
		return
	_batch_renderer.draw_safe_lane(self, runtime, FIELD_ORIGIN, FIELD_SIZE, foreground)
	_batch_renderer.draw_field(self, runtime, FIELD_ORIGIN, FIELD_SIZE, foreground, background)
	_draw_emitters(font, foreground)
	_draw_player(foreground, background)
	_draw_telemetry(font, foreground)
	if show_help:
		_draw_help(font, foreground, background)
	draw_string(font, Vector2(3, 177), "H=HELP R=LOAD SPC=RUN .=1 F=60 P=PH D=DEN S=SPD E=EM", HORIZONTAL_ALIGNMENT_CENTER, 314, _small_size(), foreground)


func _draw_emitters(font: Font, foreground: Color) -> void:
	var phase := runtime.current_phase()
	for index: int in range(phase.emitters.size()):
		var emitter := phase.emitters[index]
		var point := Vector2(FIELD_ORIGIN.x + emitter.origin_x, FIELD_ORIGIN.y + emitter.origin_y * FIELD_SIZE.y / definition.arena_height)
		draw_line(point + Vector2(-3, 0), point + Vector2(3, 0), foreground, 1.0)
		draw_line(point + Vector2(0, -3), point + Vector2(0, 3), foreground, 1.0)
		if index == selected_emitter:
			draw_rect(Rect2(point - Vector2(5, 5), Vector2(11, 11)), foreground, false, 1.0)
			var label_x := point.x + 6 if point.x < FIELD_ORIGIN.x + FIELD_SIZE.x - 20 else point.x - 18
			draw_string(font, Vector2(label_x, point.y + 3), "E%d" % (index + 1), HORIZONTAL_ALIGNMENT_LEFT, 14, _small_size(), foreground)


func _draw_player(foreground: Color, background: Color) -> void:
	var player := Vector2(
		FIELD_ORIGIN.x + roundi(runtime.state.player_x_fp / 256.0),
		FIELD_ORIGIN.y + roundi(runtime.state.player_y_fp / 256.0 * FIELD_SIZE.y / definition.arena_height)
	)
	var outline := PackedVector2Array([
		player + Vector2(0, -4),
		player + Vector2(4, 0),
		player + Vector2(0, 4),
		player + Vector2(-4, 0),
		player + Vector2(0, -4),
	])
	draw_polyline(outline, foreground, 1.0)
	draw_rect(Rect2(player, Vector2(1, 1)), foreground)
	draw_rect(Rect2(player + Vector2(1, 1), Vector2(1, 1)), background)


func _draw_telemetry(font: Font, foreground: Color) -> void:
	var phase := runtime.current_phase()
	var emitter := phase.emitters[selected_emitter] if selected_emitter < phase.emitters.size() else null
	var lines := PackedStringArray([
		"PHASE %d/3" % (runtime.state.phase_index + 1),
	])
	_append_telemetry_value(lines, String(phase.id).get_slice(".", String(phase.id).get_slice_count(".") - 1).to_upper(), font)
	lines.append_array(PackedStringArray([
		"TICK %03d/%03d" % [runtime.state.phase_tick, phase.duration_ticks],
		"LIVE %04d" % runtime.pool.active_count,
		"SOLID %04d" % runtime.pool.committed_count,
		"PEAK %04d" % peak_active,
		"DENSITY %d%%" % density_percent,
		"SPEED %d%%" % speed_percent,
		"STATUS %s" % ("PAUSED" if is_paused else "RUNNING"),
		"ASCII EN/JA",
		"SAFE LANE %d" % phase.safe_lane if phase.safe_lane >= 0 else "LOAD OK R%d" % reload_count,
	]))
	if emitter != null:
		lines.append("EMIT %d/%d" % [selected_emitter + 1, phase.emitters.size()])
		_append_telemetry_value(lines, String(emitter.pattern_type).to_upper(), font)
		lines.append("INT %d  VOL %d" % [emitter.interval_ticks, emitter.volleys])
		lines.append("SLOT%d TEL%d" % [emitter.slot_count, emitter.telegraph_ticks])
	var line_step := 8 if lines.size() > 15 else 9
	for index: int in range(lines.size()):
		draw_string(font, Vector2(234, 32 + index * line_step), lines[index], HORIZONTAL_ALIGNMENT_LEFT, 79, _small_size(), foreground)


func _append_telemetry_value(lines: PackedStringArray, value: String, font: Font) -> void:
	var tokens := value.split("_", true)
	var current := ""
	for token: String in tokens:
		var candidate := token if current.is_empty() else "%s_%s" % [current, token]
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, _small_size()).x <= 79:
			current = candidate
			continue
		if not current.is_empty():
			lines.append(current + "_")
		current = token
	if current.is_empty():
		return
	for wrapped_line: String in PixelTextWrapper.wrap(current, font, 79, _small_size(), &"en"):
		lines.append(wrapped_line)


func _draw_help(font: Font, foreground: Color, background: Color) -> void:
	draw_rect(Rect2(3, 22, 314, 145), background)
	draw_rect(Rect2(3, 22, 314, 145), foreground, false, 1.0)
	draw_string(font, Vector2(10, 35), "READ-ONLY PREVIEW", HORIZONTAL_ALIGNMENT_LEFT, 300, _font_size(), foreground)
	var emitter := runtime.current_phase().emitters[selected_emitter] if selected_emitter < runtime.current_phase().emitters.size() else null
	var emitter_id := String(emitter.id) if emitter != null else "NONE"
	var emitter_type := String(emitter.pattern_type).to_upper() if emitter != null else "NONE"
	var safe_text := (
		"SAFE LANE %d; DOTTED LINES ARE THE GUIDE" % emitter.safe_lane
		if emitter != null and emitter.safe_lane >= 0
		else "SAFE SLOT NONE FOR THIS EMITTER"
	)
	var lines := PackedStringArray([
		"EDIT JSON -> SAVE -> R RELOAD",
		"D/S PREVIEW ONLY; THEY NEVER WRITE JSON",
		"COUNTS ARE LIVE / SOLID / PEAK BULLETS",
		"SELECTED EMITTER %d/%d" % [selected_emitter + 1, runtime.current_phase().emitters.size()],
		"ID %s" % emitter_id,
		"TYPE %s" % emitter_type,
		safe_text,
		"KEYS",
		"SPACE PLAY/PAUSE   . ONE TICK   F +60 TICKS",
		"P PHASE   D DENSITY   S SPEED   E EMITTER",
		"R RELOAD JSON   H CLOSE HELP",
		"DIAMOND = OBSERVER   E# = SELECTED ORIGIN",
	])
	for index: int in range(lines.size()):
		draw_string(font, Vector2(10, 48 + index * 10), lines[index], HORIZONTAL_ALIGNMENT_LEFT, 300, _small_size(), foreground)


func _draw_errors(font: Font, foreground: Color) -> void:
	draw_string(font, Vector2(10, 42), "PATTERN INVALID", HORIZONTAL_ALIGNMENT_LEFT, 206, _font_size(), foreground)
	var y := 58
	for error: String in errors:
		for line: String in PixelTextWrapper.wrap(error, font, 200, _small_size(), &"en", 3):
			draw_string(font, Vector2(10, y), line, HORIZONTAL_ALIGNMENT_LEFT, 206, _small_size(), foreground)
			y += 10


func _font_size() -> int:
	return 8


func _small_size() -> int:
	return 6
