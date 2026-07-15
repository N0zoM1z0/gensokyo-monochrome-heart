class_name OptionsScreen
extends UiScreenBase
## Live EN/JA, profile, motion, and flash preview with cancel-to-restore semantics.

const TOGGLE_SCENE := preload("res://ui/components/toggle.tscn")
const PROFILE_IDS: Array[StringName] = [&"A", &"B", &"C", &"D"]
const PROFILE_KEYS: Array[StringName] = [
	&"ui.profile.a",
	&"ui.profile.b",
	&"ui.profile.c",
	&"ui.profile.d",
]

var _opening_locale: StringName = &"en"
var _opening_profile: StringName = &"A"
var _opening_reduced_motion: bool = false
var _opening_safe_flash: bool = false
var _opening_accessibility_preset: int = 0
var _opening_accessibility_first_run: bool = true
var _opening_one_handed_preset: int = InputMapInstaller.OneHandedPreset.NONE
var _opening_ui_scale_percent: int = 100
var _current_profile: StringName = &"A"
var _current_reduced_motion: bool = false
var _current_safe_flash: bool = false
var _current_one_handed_preset: int = InputMapInstaller.OneHandedPreset.NONE
var _current_ui_scale_percent: int = 100
var _low_motion_toggle: PixelToggle
var _safe_flash_toggle: PixelToggle


func _build_screen() -> void:
	screen_id = &"options"
	var localization := get_node_or_null("/root/LocalizationService")
	var settings := get_node_or_null("/root/SettingsService")
	var accessibility := get_node_or_null("/root/AccessibilityState")
	_opening_locale = localization.locale if localization != null else &"en"
	_opening_profile = settings.preferred_presentation_profile if settings != null else &"A"
	_opening_reduced_motion = settings.is_reduced_motion if settings != null else false
	_opening_safe_flash = settings.is_safe_flash if settings != null else false
	_opening_accessibility_preset = int(accessibility.preset) if accessibility != null else 0
	_opening_accessibility_first_run = accessibility.is_first_run if accessibility != null else true
	_opening_one_handed_preset = accessibility.one_handed_preset if accessibility != null else InputMapInstaller.OneHandedPreset.NONE
	_opening_ui_scale_percent = accessibility.ui_scale_percent if accessibility != null else 100
	_current_profile = _opening_profile
	_current_reduced_motion = _opening_reduced_motion
	_current_safe_flash = _opening_safe_flash
	_current_one_handed_preset = _opening_one_handed_preset
	_current_ui_scale_percent = _opening_ui_scale_percent
	_add_frame(Rect2(8, 8, 304, 164))
	_add_row(&"ui.options.language", &"language", &"options.language", Rect2(16, 29, 288, 15))
	_add_row(&"ui.options.profile", &"profile", &"options.profile", Rect2(16, 45, 288, 15))
	_add_row(&"ui.options.ui_scale", &"ui_scale", &"options.ui_scale", Rect2(16, 61, 288, 15))
	_add_row(&"ui.options.low_motion", &"low_motion", &"options.low_motion", Rect2(16, 77, 288, 15))
	_add_row(&"ui.options.safe_flash", &"safe_flash", &"options.safe_flash", Rect2(16, 93, 288, 15))
	_add_row(&"ui.options.one_handed", &"one_handed", &"options.one_handed", Rect2(16, 109, 288, 15))
	_add_row(&"ui.options.back", &"options_apply", &"options.back", Rect2(16, 126, 288, 15))
	_low_motion_toggle = _add_toggle(Vector2(268, 79))
	_safe_flash_toggle = _add_toggle(Vector2(268, 95))
	_add_action_hint(GameInput.CONFIRM, &"ui.common.confirm", Rect2(16, 159, 92, 12))
	_add_action_hint(GameInput.CANCEL, &"ui.common.cancel", Rect2(210, 159, 94, 12))


func _on_fixture_configured() -> void:
	_opening_locale = _fixture_locale
	_opening_profile = _fixture_profile_id
	_opening_reduced_motion = _fixture_reduced_motion
	_opening_safe_flash = _fixture_safe_flash
	_current_profile = _fixture_profile_id
	_current_reduced_motion = _fixture_reduced_motion
	_current_safe_flash = _fixture_safe_flash
	_opening_one_handed_preset = InputMapInstaller.OneHandedPreset.NONE
	_current_one_handed_preset = InputMapInstaller.OneHandedPreset.NONE
	_opening_ui_scale_percent = _fixture_ui_scale_percent
	_current_ui_scale_percent = _fixture_ui_scale_percent


func set_ui_scale_fixture(percent: int) -> void:
	super.set_ui_scale_fixture(percent)
	_opening_ui_scale_percent = _fixture_ui_scale_percent
	_current_ui_scale_percent = _fixture_ui_scale_percent
	_refresh_screen()


func _adjust_current(direction: int) -> bool:
	if rows.is_empty():
		return false
	match rows[focused_index].command_id:
		&"language":
			_apply_locale(&"ja" if active_locale() == &"en" else &"en")
		&"profile":
			var profile_index := PROFILE_IDS.find(_current_profile)
			_apply_profile(PROFILE_IDS[wrapi(profile_index + direction, 0, PROFILE_IDS.size())])
		&"ui_scale":
			_apply_ui_scale(UI_SCALE_POLICY.next(_current_ui_scale_percent, direction))
		&"low_motion":
			_apply_reduced_motion(not _current_reduced_motion)
		&"safe_flash":
			_apply_safe_flash(not _current_safe_flash)
		&"one_handed":
			_apply_one_handed(wrapi(_current_one_handed_preset + direction, 0, 3))
		_:
			return false
	return true


func _activate_row(row: ListRow) -> void:
	if row.command_id == &"options_apply":
		command_requested.emit(&"options_apply", route_parameters)
	else:
		_adjust_current(1)


func _handle_cancel() -> void:
	_restore_opening_values()
	command_requested.emit(&"options_cancel", route_parameters)


func _refresh_screen() -> void:
	super._refresh_screen()
	if rows.size() < 7:
		return
	rows[0].set_value_key(&"ui.language.japanese" if active_locale() == &"ja" else &"ui.language.english")
	var profile_index := maxi(0, PROFILE_IDS.find(_current_profile))
	rows[1].set_value_key(PROFILE_KEYS[profile_index])
	rows[2].set_value_key(StringName("ui.options.ui_scale.%d" % _current_ui_scale_percent))
	rows[3].set_value_key(&"ui.common.on" if _current_reduced_motion else &"ui.common.off")
	rows[4].set_value_key(&"ui.common.on" if _current_safe_flash else &"ui.common.off")
	rows[5].set_value_key([
		&"ui.options.one_handed.off",
		&"ui.options.one_handed.left",
		&"ui.options.one_handed.right",
	][_current_one_handed_preset])
	_apply_scale_layout()
	if _low_motion_toggle != null:
		_low_motion_toggle.set_value(_current_reduced_motion, _active_profile_id())
	if _safe_flash_toggle != null:
		_safe_flash_toggle.set_value(_current_safe_flash, _active_profile_id())


func _draw_screen(profile: PresentationProfile) -> void:
	var foreground := profile.paper if profile.is_inverted else profile.ink
	_draw_localized(&"ui.options.title", Vector2(12, 24), 296, HORIZONTAL_ALIGNMENT_CENTER)
	if ui_scale_percent() == 100:
		draw_line(Vector2(16, 143), Vector2(304, 143), foreground, 1.0)
		_draw_localized_wrapped(&"ui.options.help", Rect2(16, 145, 288, 18), 2, 10)
	else:
		draw_line(Vector2(16, 151), Vector2(304, 151), foreground, 1.0)


func _add_toggle(position: Vector2) -> PixelToggle:
	var toggle := TOGGLE_SCENE.instantiate() as PixelToggle
	toggle.position = position
	toggle.size = Vector2(28, 12)
	add_child(toggle)
	return toggle


func _apply_locale(locale: StringName) -> void:
	if _fixture_mode:
		_fixture_locale = locale
		_refresh_screen()
		return
	var localization := get_node_or_null("/root/LocalizationService")
	if localization != null:
		localization.set_locale(locale)


func _apply_profile(profile_id: StringName) -> void:
	_current_profile = profile_id
	if _fixture_mode:
		_fixture_profile_id = profile_id
		_refresh_screen()
		return
	var settings := get_node_or_null("/root/SettingsService")
	if settings != null:
		settings.set_preferred_presentation_profile(profile_id)
	var registry := get_node_or_null("/root/UiThemeRegistry")
	if registry != null:
		registry.set_native_profile(profile_id)
	_refresh_screen()


func _apply_reduced_motion(enabled: bool) -> void:
	_current_reduced_motion = enabled
	if _fixture_mode:
		_fixture_reduced_motion = enabled
		_refresh_screen()
		return
	var accessibility := get_node_or_null("/root/AccessibilityState")
	if accessibility != null:
		accessibility.set_reduced_motion(enabled)
	else:
		var settings := get_node_or_null("/root/SettingsService")
		if settings != null:
			settings.set_reduced_motion(enabled)
	_refresh_screen()


func _apply_safe_flash(enabled: bool) -> void:
	_current_safe_flash = enabled
	if _fixture_mode:
		_fixture_safe_flash = enabled
		_refresh_screen()
		return
	var accessibility := get_node_or_null("/root/AccessibilityState")
	if accessibility != null:
		accessibility.set_safe_flash(enabled)
	else:
		var settings := get_node_or_null("/root/SettingsService")
		if settings != null:
			settings.set_safe_flash(enabled)
	_refresh_screen()


func _apply_one_handed(next_preset: int) -> void:
	_current_one_handed_preset = next_preset
	if not _fixture_mode:
		var accessibility := get_node_or_null("/root/AccessibilityState")
		if accessibility != null:
			accessibility.set_one_handed_preset(next_preset)
	_refresh_screen()


func _apply_ui_scale(next_percent: int) -> void:
	_current_ui_scale_percent = UI_SCALE_POLICY.normalize(next_percent)
	if _fixture_mode:
		_fixture_ui_scale_percent = _current_ui_scale_percent
		_refresh_screen()
		return
	var accessibility := get_node_or_null("/root/AccessibilityState")
	if accessibility != null:
		accessibility.set_ui_scale_percent(_current_ui_scale_percent)
	else:
		_refresh_screen()


func _focus_changed(_row: ListRow) -> void:
	_apply_scale_layout()


func _apply_scale_layout() -> void:
	if rows.size() < 7:
		return
	var percent := ui_scale_percent()
	if percent == 100:
		var positions := [29, 45, 61, 77, 93, 109, 126]
		for index: int in range(rows.size()):
			rows[index].visible = true
			rows[index].position = Vector2(16, positions[index])
			rows[index].size = Vector2(288, 15)
		_low_motion_toggle.visible = true
		_safe_flash_toggle.visible = true
		return
	var visible_count := 5 if percent == 125 else 4
	var row_height := 21 if percent == 125 else 26
	var row_step := 23 if percent == 125 else 28
	var first := clampi(focused_index - 1, 0, rows.size() - visible_count)
	for index: int in range(rows.size()):
		var slot := index - first
		rows[index].visible = slot >= 0 and slot < visible_count
		if rows[index].visible:
			rows[index].position = Vector2(16, 34 + slot * row_step)
			rows[index].size = Vector2(288, row_height)
	_low_motion_toggle.visible = false
	_safe_flash_toggle.visible = false
	if action_hints.size() >= 2:
		action_hints[0].position = Vector2(16, 157)
		action_hints[0].size = Vector2(142, 18)
		action_hints[1].position = Vector2(166, 157)
		action_hints[1].size = Vector2(138, 18)


func _restore_opening_values() -> void:
	if _fixture_mode:
		_fixture_locale = _opening_locale
		_fixture_profile_id = _opening_profile
		_fixture_reduced_motion = _opening_reduced_motion
		_fixture_safe_flash = _opening_safe_flash
		_current_profile = _opening_profile
		_current_reduced_motion = _opening_reduced_motion
		_current_safe_flash = _opening_safe_flash
		_current_one_handed_preset = _opening_one_handed_preset
		_fixture_ui_scale_percent = _opening_ui_scale_percent
		_current_ui_scale_percent = _opening_ui_scale_percent
		_refresh_screen()
		return
	var localization := get_node_or_null("/root/LocalizationService")
	if localization != null:
		localization.set_locale(_opening_locale)
	var settings := get_node_or_null("/root/SettingsService")
	if settings != null:
		settings.set_preferred_presentation_profile(_opening_profile)
	var registry := get_node_or_null("/root/UiThemeRegistry")
	if registry != null:
		registry.set_native_profile(_opening_profile)
	var accessibility := get_node_or_null("/root/AccessibilityState")
	if accessibility != null:
		accessibility.restore_presentation(
			_opening_reduced_motion,
			_opening_safe_flash,
			_opening_accessibility_preset,
			_opening_accessibility_first_run,
			true,
			_opening_ui_scale_percent
		)
		accessibility.set_one_handed_preset(_opening_one_handed_preset)
	_current_profile = _opening_profile
	_current_reduced_motion = _opening_reduced_motion
	_current_safe_flash = _opening_safe_flash
	_current_one_handed_preset = _opening_one_handed_preset
	_current_ui_scale_percent = _opening_ui_scale_percent
	_refresh_screen()
