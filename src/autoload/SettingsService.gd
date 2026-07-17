extends Node
## Owns presentation and audio accessibility preferences; it never mutates story state.

signal presentation_settings_changed
signal audio_settings_changed

const DEFAULT_PROFILE: StringName = &"A"
const VALID_PROFILES: Array[StringName] = [&"A", &"B", &"C", &"D"]
const CONFIG_PATH := "user://settings.cfg"
const MONO_EFFECT_INDEX := 0
const LOW_DYNAMIC_EFFECT_INDEX := 1

var forced_presentation_profile: StringName = &""
var preferred_presentation_profile: StringName = DEFAULT_PROFILE
var is_reduced_motion: bool = false
var is_safe_flash: bool = false
var is_mono_audio: bool = false
var is_low_dynamic_range: bool = false


func _ready() -> void:
	_load_preferences()
	_apply_audio_bus_settings()


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


func set_mono_audio(enabled: bool) -> void:
	configure_audio_accessibility(enabled, is_low_dynamic_range)


func set_low_dynamic_range(enabled: bool) -> void:
	configure_audio_accessibility(is_mono_audio, enabled)


func configure_audio_accessibility(
	mono_enabled: bool,
	low_dynamic_enabled: bool,
	should_persist: bool = true
) -> void:
	if is_mono_audio == mono_enabled and is_low_dynamic_range == low_dynamic_enabled:
		_apply_audio_bus_settings()
		return
	is_mono_audio = mono_enabled
	is_low_dynamic_range = low_dynamic_enabled
	_apply_audio_bus_settings()
	if should_persist:
		_save_preferences()
	audio_settings_changed.emit()


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
	is_mono_audio = bool(config.get_value("audio", "mono", false))
	is_low_dynamic_range = bool(config.get_value("audio", "low_dynamic_range", false))


func _save_preferences() -> void:
	if not is_inside_tree():
		return
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	config.set_value("presentation", "profile", String(preferred_presentation_profile))
	config.set_value("presentation", "reduced_motion", is_reduced_motion)
	config.set_value("presentation", "safe_flash", is_safe_flash)
	config.set_value("audio", "mono", is_mono_audio)
	config.set_value("audio", "low_dynamic_range", is_low_dynamic_range)
	var error := config.save(CONFIG_PATH)
	if error != OK:
		push_error("Could not persist presentation preference (error %d)" % error)


func _apply_audio_bus_settings() -> void:
	var master_bus := AudioServer.get_bus_index(&"Master")
	if master_bus < 0:
		return
	if AudioServer.get_bus_effect_count(master_bus) > MONO_EFFECT_INDEX:
		AudioServer.set_bus_effect_enabled(master_bus, MONO_EFFECT_INDEX, is_mono_audio)
	if AudioServer.get_bus_effect_count(master_bus) > LOW_DYNAMIC_EFFECT_INDEX:
		AudioServer.set_bus_effect_enabled(master_bus, LOW_DYNAMIC_EFFECT_INDEX, is_low_dynamic_range)
