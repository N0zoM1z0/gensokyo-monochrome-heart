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
var _current_profile: StringName = &"A"
var _current_reduced_motion: bool = false
var _current_safe_flash: bool = false
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
	_current_profile = _opening_profile
	_current_reduced_motion = _opening_reduced_motion
	_current_safe_flash = _opening_safe_flash
	_add_frame(Rect2(8, 8, 304, 164))
	_add_row(&"ui.options.language", &"language", &"options.language", Rect2(16, 32, 288, 16))
	_add_row(&"ui.options.profile", &"profile", &"options.profile", Rect2(16, 52, 288, 16))
	_add_row(&"ui.options.low_motion", &"low_motion", &"options.low_motion", Rect2(16, 72, 288, 16))
	_add_row(&"ui.options.safe_flash", &"safe_flash", &"options.safe_flash", Rect2(16, 92, 288, 16))
	_add_row(&"ui.options.back", &"options_apply", &"options.back", Rect2(16, 116, 288, 16))
	_low_motion_toggle = _add_toggle(Vector2(268, 74))
	_safe_flash_toggle = _add_toggle(Vector2(268, 94))
	_add_action_hint(GameInput.CONFIRM, &"ui.common.confirm", Rect2(16, 162, 92, 12))
	_add_action_hint(GameInput.CANCEL, &"ui.common.cancel", Rect2(210, 162, 94, 12))


func _on_fixture_configured() -> void:
	_opening_locale = _fixture_locale
	_opening_profile = _fixture_profile_id
	_opening_reduced_motion = _fixture_reduced_motion
	_opening_safe_flash = _fixture_safe_flash
	_current_profile = _fixture_profile_id
	_current_reduced_motion = _fixture_reduced_motion
	_current_safe_flash = _fixture_safe_flash


func _adjust_current(direction: int) -> bool:
	if rows.is_empty():
		return false
	match rows[focused_index].command_id:
		&"language":
			_apply_locale(&"ja" if active_locale() == &"en" else &"en")
		&"profile":
			var profile_index := PROFILE_IDS.find(_current_profile)
			_apply_profile(PROFILE_IDS[wrapi(profile_index + direction, 0, PROFILE_IDS.size())])
		&"low_motion":
			_apply_reduced_motion(not _current_reduced_motion)
		&"safe_flash":
			_apply_safe_flash(not _current_safe_flash)
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
	if rows.size() < 5:
		return
	rows[0].set_value_key(&"ui.language.japanese" if active_locale() == &"ja" else &"ui.language.english")
	var profile_index := maxi(0, PROFILE_IDS.find(_current_profile))
	rows[1].set_value_key(PROFILE_KEYS[profile_index])
	rows[2].set_value_key(&"ui.common.on" if _current_reduced_motion else &"ui.common.off")
	rows[3].set_value_key(&"ui.common.on" if _current_safe_flash else &"ui.common.off")
	if _low_motion_toggle != null:
		_low_motion_toggle.set_value(_current_reduced_motion, _active_profile_id())
	if _safe_flash_toggle != null:
		_safe_flash_toggle.set_value(_current_safe_flash, _active_profile_id())


func _draw_screen(profile: PresentationProfile) -> void:
	var foreground := profile.paper if profile.is_inverted else profile.ink
	_draw_localized(&"ui.options.title", Vector2(12, 24), 296, HORIZONTAL_ALIGNMENT_CENTER)
	draw_line(Vector2(16, 138), Vector2(304, 138), foreground, 1.0)
	_draw_localized_wrapped(&"ui.options.help", Rect2(16, 141, 288, 20), 2)


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


func _restore_opening_values() -> void:
	if _fixture_mode:
		_fixture_locale = _opening_locale
		_fixture_profile_id = _opening_profile
		_fixture_reduced_motion = _opening_reduced_motion
		_fixture_safe_flash = _opening_safe_flash
		_current_profile = _opening_profile
		_current_reduced_motion = _opening_reduced_motion
		_current_safe_flash = _opening_safe_flash
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
			_opening_accessibility_first_run
		)
	_current_profile = _opening_profile
	_current_reduced_motion = _opening_reduced_motion
	_current_safe_flash = _opening_safe_flash
	_refresh_screen()
