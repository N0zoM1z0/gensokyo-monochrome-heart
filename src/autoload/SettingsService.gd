extends Node
## Owns presentation/accessibility preferences only; it never mutates story state.

signal presentation_settings_changed

const DEFAULT_PROFILE: StringName = &"A"
const VALID_PROFILES: Array[StringName] = [&"A", &"B", &"C", &"D"]
const CONFIG_PATH := "user://settings.cfg"

var forced_presentation_profile: StringName = &""
var preferred_presentation_profile: StringName = DEFAULT_PROFILE
var is_reduced_motion: bool = false
var is_safe_flash: bool = false


func _ready() -> void:
	_load_preferences()


func set_forced_presentation_profile(profile_id: StringName) -> void:
	var normalized: StringName = profile_id if profile_id in VALID_PROFILES else &""
	if forced_presentation_profile == normalized:
		return
	forced_presentation_profile = normalized
	presentation_settings_changed.emit()


func set_preferred_presentation_profile(profile_id: StringName) -> void:
	var normalized: StringName = profile_id if profile_id in VALID_PROFILES else DEFAULT_PROFILE
	if preferred_presentation_profile == normalized:
		return
	preferred_presentation_profile = normalized
	_save_preferences()
	presentation_settings_changed.emit()


func set_reduced_motion(enabled: bool) -> void:
	if is_reduced_motion == enabled:
		return
	is_reduced_motion = enabled
	_save_preferences()
	presentation_settings_changed.emit()


func set_safe_flash(enabled: bool) -> void:
	if is_safe_flash == enabled:
		return
	is_safe_flash = enabled
	_save_preferences()
	presentation_settings_changed.emit()


func resolve_profile(requested_profile: StringName) -> StringName:
	if forced_presentation_profile != &"":
		return forced_presentation_profile
	if requested_profile in VALID_PROFILES:
		return requested_profile
	return preferred_presentation_profile


func _load_preferences() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	var stored_profile := StringName(config.get_value("presentation", "profile", DEFAULT_PROFILE))
	preferred_presentation_profile = stored_profile if stored_profile in VALID_PROFILES else DEFAULT_PROFILE
	is_reduced_motion = bool(config.get_value("presentation", "reduced_motion", false))
	is_safe_flash = bool(config.get_value("presentation", "safe_flash", false))


func _save_preferences() -> void:
	if not is_inside_tree():
		return
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	config.set_value("presentation", "profile", String(preferred_presentation_profile))
	config.set_value("presentation", "reduced_motion", is_reduced_motion)
	config.set_value("presentation", "safe_flash", is_safe_flash)
	var error := config.save(CONFIG_PATH)
	if error != OK:
		push_error("Could not persist presentation preference (error %d)" % error)
