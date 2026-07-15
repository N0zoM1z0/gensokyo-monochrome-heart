class_name UiScreenBase
extends Control
## Fixture-safe localized screen base that consumes semantic input only.

signal command_requested(command_id: StringName, payload: Dictionary)

const LIST_ROW_SCENE := preload("res://ui/components/list_row.tscn")
const FRAME_SCENE := preload("res://ui/components/frame.tscn")
const ACTION_HINT_SCENE := preload("res://ui/components/action_hint.tscn")
const ACCEPT_RELEASE_FRAMES := 2

@export var screen_id: StringName

var route_parameters: Dictionary = {}
var rows: Array[ListRow] = []
var frames: Array[PanelFrame] = []
var action_hints: Array[ActionHint] = []
var focused_index: int = 0
var interaction_enabled: bool = true

var _catalog := UiTextCatalog.new()
var _latin_font: Font
var _japanese_font: Font
var _accept_release_frames: int = 0
var _accept_armed: bool = false
var _fixture_mode: bool = false
var _fixture_profile_id: StringName = &"A"
var _fixture_forced_profile_id: StringName = &""
var _fixture_locale: StringName = &"en"
var _fixture_reduced_motion: bool = false
var _fixture_safe_flash: bool = false
var _active_device_name: StringName = &"keyboard"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	custom_minimum_size = Vector2(320, 180)
	size = Vector2(320, 180)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_catalog.load_default()
	_latin_font = UiFontRegistry.latin()
	_japanese_font = UiFontRegistry.japanese()
	_read_active_device()
	_build_screen()
	_connect_live_services()
	if not rows.is_empty():
		focused_index = clampi(_initial_focus_index(), 0, rows.size() - 1)
		_apply_focus()
	_refresh_screen()
	queue_redraw()


func _process(_delta: float) -> void:
	if InputMap.has_action(GameInput.CONFIRM) and Input.is_action_pressed(GameInput.CONFIRM):
		_accept_release_frames = 0
		_accept_armed = false
	elif not _accept_armed:
		_accept_release_frames += 1
		_accept_armed = _accept_release_frames >= ACCEPT_RELEASE_FRAMES


func configure_route(request: ScreenRouteRequest) -> void:
	route_parameters = request.parameters.duplicate(true)
	_on_route_configured()
	_refresh_screen()


func configure_fixture(
	requested_profile: StringName,
	locale: StringName,
	forced_profile: StringName = &"",
	is_reduced_motion: bool = false,
	is_safe_flash: bool = false
) -> void:
	_fixture_mode = true
	_fixture_profile_id = requested_profile if requested_profile in [&"A", &"B", &"C", &"D"] else &"A"
	_fixture_forced_profile_id = forced_profile if forced_profile in [&"A", &"B", &"C", &"D"] else &""
	_fixture_locale = locale if locale in [&"en", &"ja"] else &"en"
	_fixture_reduced_motion = is_reduced_motion
	_fixture_safe_flash = is_safe_flash
	_on_fixture_configured()
	_refresh_screen()


func resolved_profile_id() -> StringName:
	return _active_profile_id()


func active_locale() -> StringName:
	if _fixture_mode:
		return _fixture_locale
	var localization := get_node_or_null("/root/LocalizationService")
	return localization.locale if localization != null else &"en"


func is_reduced_motion() -> bool:
	if _fixture_mode:
		return _fixture_reduced_motion
	var settings := get_node_or_null("/root/SettingsService")
	return settings.is_reduced_motion if settings != null else false


func is_safe_flash() -> bool:
	if _fixture_mode:
		return _fixture_safe_flash
	var settings := get_node_or_null("/root/SettingsService")
	return settings.is_safe_flash if settings != null else false


func current_focus_id() -> StringName:
	return rows[focused_index].focus_id if focused_index >= 0 and focused_index < rows.size() else &""


func restore_focus(focus_id: StringName) -> void:
	for index: int in range(rows.size()):
		if rows[index].focus_id == focus_id:
			focused_index = index
			_apply_focus()
			return


func handle_semantic_action(action: StringName) -> void:
	if not interaction_enabled or not visible:
		return
	match action:
		GameInput.MOVE_UP:
			_move_focus(-1)
		GameInput.MOVE_DOWN:
			_move_focus(1)
		GameInput.MOVE_LEFT:
			if not _adjust_current(-1):
				_move_horizontal(-1)
		GameInput.MOVE_RIGHT:
			if not _adjust_current(1):
				_move_horizontal(1)
		GameInput.CONFIRM:
			if _accept_armed:
				_accept_armed = false
				_accept_release_frames = 0
				_activate_current()
		GameInput.CANCEL:
			_handle_cancel()


func arm_input_for_test() -> void:
	_accept_release_frames = ACCEPT_RELEASE_FRAMES
	_accept_armed = true


func action_contract() -> PackedStringArray:
	var actions := PackedStringArray()
	for action: StringName in GameInput.ALL_ACTIONS:
		actions.append(String(action))
	return actions


func _build_screen() -> void:
	pass


func _on_route_configured() -> void:
	pass


func _on_fixture_configured() -> void:
	pass


func _initial_focus_index() -> int:
	return 0


func _focus_changed(_row: ListRow) -> void:
	pass


func _adjust_current(_direction: int) -> bool:
	return false


func _move_horizontal(_direction: int) -> void:
	pass


func _activate_row(row: ListRow) -> void:
	command_requested.emit(row.command_id, {})


func _handle_cancel() -> void:
	command_requested.emit(&"back", {})


func _refresh_screen() -> void:
	var locale := active_locale()
	var profile_id := _active_profile_id()
	for row: ListRow in rows:
		row.set_locale(locale)
		row.set_profile(profile_id)
	for frame: PanelFrame in frames:
		frame.set_profile(profile_id)
	var glyph_service := get_node_or_null("/root/InputGlyphService")
	for hint: ActionHint in action_hints:
		var glyph_key: StringName = glyph_service.glyph_key(hint.action) if glyph_service != null else StringName("input.glyph.keyboard.%s" % ("menu" if hint.action == GameInput.PAUSE else "confirm"))
		hint.configure(hint.action, hint.verb_key, locale, profile_id, glyph_key)
	_apply_focus()
	queue_redraw()


func _draw() -> void:
	var profile := PresentationProfileRegistry.resolve(_active_profile_id())
	var background := profile.ink if profile.is_inverted else profile.paper
	draw_rect(Rect2(Vector2.ZERO, Vector2(320, 180)), background)
	_draw_screen(profile)


func _draw_screen(_profile: PresentationProfile) -> void:
	pass


func _draw_localized(
	key: StringName,
	position: Vector2,
	width: float = -1.0,
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
	font_size: int = 0
) -> void:
	var profile := PresentationProfileRegistry.resolve(_active_profile_id())
	var foreground := profile.paper if profile.is_inverted else profile.ink
	var font := _japanese_font if active_locale() == &"ja" else _latin_font
	var resolved_size := _resolved_font_size(font_size)
	draw_string(font, position, _text(key), alignment, width, resolved_size, foreground)


func _draw_localized_wrapped(
	key: StringName,
	rect: Rect2,
	maximum_lines: int = 2,
	font_size: int = 0
) -> void:
	var profile := PresentationProfileRegistry.resolve(_active_profile_id())
	var foreground := profile.paper if profile.is_inverted else profile.ink
	var font := _japanese_font if active_locale() == &"ja" else _latin_font
	var resolved_size := _resolved_font_size(font_size)
	var lines := PixelTextWrapper.wrap(
		_text(key), font, rect.size.x, resolved_size, active_locale(), maximum_lines
	)
	var line_height := resolved_size + 2
	var baseline_y := rect.position.y + resolved_size
	for index: int in range(mini(lines.size(), maximum_lines)):
		draw_string(
			font,
			Vector2(rect.position.x, baseline_y + index * line_height),
			lines[index],
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x,
			resolved_size,
			foreground
		)


func _resolved_font_size(requested_size: int = 0) -> int:
	if active_locale() == &"ja":
		return maxi(10, requested_size if requested_size > 0 else 12)
	return requested_size if requested_size > 0 else 8


func _text(key: StringName) -> String:
	if _fixture_mode:
		return _catalog.text(key, _fixture_locale)
	var localization := get_node_or_null("/root/LocalizationService")
	return localization.text(key) if localization != null else _catalog.text(key, &"en")


func _add_frame(
	rect: Rect2,
	state: StringName = &"idle",
	fill_background: bool = false
) -> PanelFrame:
	var frame := FRAME_SCENE.instantiate() as PanelFrame
	frame.position = rect.position
	frame.size = rect.size
	frame.state = state
	frame.fill_background = fill_background
	frame.profile_id = _active_profile_id()
	add_child(frame)
	frames.append(frame)
	return frame


func _add_row(
	label_key: StringName,
	command_id: StringName,
	focus_id: StringName,
	rect: Rect2,
	value_key: StringName = &""
) -> ListRow:
	var row := LIST_ROW_SCENE.instantiate() as ListRow
	row.label_key = label_key
	row.command_id = command_id
	row.focus_id = focus_id
	row.value_key = value_key
	row.position = rect.position
	row.size = rect.size
	row.locale = active_locale()
	row.profile_id = _active_profile_id()
	add_child(row)
	rows.append(row)
	return row


func _add_action_hint(
	action: StringName,
	verb_key: StringName,
	rect: Rect2
) -> ActionHint:
	var hint := ACTION_HINT_SCENE.instantiate() as ActionHint
	hint.position = rect.position
	hint.size = rect.size
	add_child(hint)
	var glyph_service := get_node_or_null("/root/InputGlyphService")
	var glyph_key: StringName = glyph_service.glyph_key(action) if glyph_service != null else &"input.glyph.keyboard.confirm"
	hint.configure(action, verb_key, active_locale(), _active_profile_id(), glyph_key)
	action_hints.append(hint)
	return hint


func _active_profile_id() -> StringName:
	if _fixture_mode:
		return _fixture_forced_profile_id if _fixture_forced_profile_id != &"" else _fixture_profile_id
	var registry := get_node_or_null("/root/UiThemeRegistry")
	return registry.effective_profile_id() if registry != null else &"A"


func _move_focus(delta: int) -> void:
	if rows.is_empty():
		return
	focused_index = wrapi(focused_index + delta, 0, rows.size())
	_apply_focus()


func _apply_focus() -> void:
	if rows.is_empty():
		return
	for index: int in range(rows.size()):
		rows[index].configure_focus(index == focused_index, _active_device_name)
	_focus_changed(rows[focused_index])


func _activate_current() -> void:
	if focused_index >= 0 and focused_index < rows.size():
		_activate_row(rows[focused_index])


func _connect_live_services() -> void:
	var localization := get_node_or_null("/root/LocalizationService")
	if localization != null and not localization.locale_changed.is_connected(_on_locale_changed):
		localization.locale_changed.connect(_on_locale_changed)
	var theme_registry := get_node_or_null("/root/UiThemeRegistry")
	if theme_registry != null and not theme_registry.profile_changed.is_connected(_on_profile_changed):
		theme_registry.profile_changed.connect(_on_profile_changed)
	var glyph_service := get_node_or_null("/root/InputGlyphService")
	if glyph_service != null and not glyph_service.active_device_changed.is_connected(_on_device_changed):
		glyph_service.active_device_changed.connect(_on_device_changed)


func _read_active_device() -> void:
	var glyph_service := get_node_or_null("/root/InputGlyphService")
	var device := int(glyph_service.active_device) if glyph_service != null else 0
	_active_device_name = [&"keyboard", &"controller", &"pointer"][clampi(device, 0, 2)]


func _on_locale_changed(_locale: StringName) -> void:
	if not _fixture_mode:
		_refresh_screen()


func _on_profile_changed(_profile_id: StringName) -> void:
	if not _fixture_mode:
		_refresh_screen()


func _on_device_changed(_device: int) -> void:
	_read_active_device()
	_apply_focus()
