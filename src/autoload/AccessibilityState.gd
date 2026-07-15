extends Node
## Stores presentation/gameplay assist presets without affecting story outcomes.

signal accessibility_changed

enum Preset {
	ORIGINAL,
	STORY,
	LOW_MOTION,
	CUSTOM,
}

const CONFIG_PATH := "user://settings.cfg"

var preset: Preset = Preset.ORIGINAL
var is_first_run: bool = true
var is_reduced_motion: bool = false
var is_safe_flash: bool = false
var has_simple_fighter_input: bool = false
var has_unlimited_story_retries: bool = false
var game_speed_percent: int = 100
var bullet_density_percent: int = 100


func _ready() -> void:
	_load_preference()


func apply_preset(next_preset: Preset, should_persist: bool = true) -> void:
	preset = next_preset
	match next_preset:
		Preset.STORY:
			is_reduced_motion = false
			is_safe_flash = true
			has_simple_fighter_input = true
			has_unlimited_story_retries = true
			game_speed_percent = 90
			bullet_density_percent = 70
		Preset.LOW_MOTION:
			is_reduced_motion = true
			is_safe_flash = true
			has_simple_fighter_input = false
			has_unlimited_story_retries = false
			game_speed_percent = 100
			bullet_density_percent = 100
		Preset.CUSTOM:
			pass
		_:
			is_reduced_motion = false
			is_safe_flash = false
			has_simple_fighter_input = false
			has_unlimited_story_retries = false
			game_speed_percent = 100
			bullet_density_percent = 100
	is_first_run = false
	_sync_presentation_settings()
	if should_persist:
		_save_preference()
	accessibility_changed.emit()


func apply_named_preset(preset_id: StringName, should_persist: bool = true) -> void:
	match preset_id:
		&"story":
			apply_preset(Preset.STORY, should_persist)
		&"low_motion":
			apply_preset(Preset.LOW_MOTION, should_persist)
		_:
			apply_preset(Preset.ORIGINAL, should_persist)


func set_reduced_motion(enabled: bool, should_persist: bool = true) -> void:
	preset = Preset.CUSTOM
	is_first_run = false
	is_reduced_motion = enabled
	_sync_presentation_settings()
	if should_persist:
		_save_preference()
	accessibility_changed.emit()


func set_safe_flash(enabled: bool, should_persist: bool = true) -> void:
	preset = Preset.CUSTOM
	is_first_run = false
	is_safe_flash = enabled
	_sync_presentation_settings()
	if should_persist:
		_save_preference()
	accessibility_changed.emit()


func restore_presentation(
	reduced_motion: bool,
	safe_flash: bool,
	prior_preset: int,
	prior_first_run: bool,
	should_persist: bool = true
) -> void:
	preset = clampi(prior_preset, Preset.ORIGINAL, Preset.CUSTOM) as Preset
	is_first_run = prior_first_run
	is_reduced_motion = reduced_motion
	is_safe_flash = safe_flash
	_sync_presentation_settings()
	if should_persist:
		if is_first_run:
			_clear_preference()
		else:
			_save_preference()
	accessibility_changed.emit()


func _sync_presentation_settings() -> void:
	if not is_inside_tree():
		return
	var settings := get_node_or_null("/root/SettingsService")
	if settings != null:
		settings.set_reduced_motion(is_reduced_motion)
		settings.set_safe_flash(is_safe_flash)


func _load_preference() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK or not config.has_section_key("accessibility", "preset"):
		return
	var stored_preset := clampi(int(config.get_value("accessibility", "preset", 0)), 0, Preset.CUSTOM)
	apply_preset(stored_preset as Preset, false)
	if preset == Preset.CUSTOM:
		is_reduced_motion = bool(config.get_value("accessibility", "reduced_motion", false))
		is_safe_flash = bool(config.get_value("accessibility", "safe_flash", false))
		_sync_presentation_settings()


func _save_preference() -> void:
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	config.set_value("accessibility", "preset", preset)
	config.set_value("accessibility", "reduced_motion", is_reduced_motion)
	config.set_value("accessibility", "safe_flash", is_safe_flash)
	var error := config.save(CONFIG_PATH)
	if error != OK:
		push_error("Could not persist accessibility preference (error %d)" % error)


func _clear_preference() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK or not config.has_section("accessibility"):
		return
	config.erase_section("accessibility")
	var error := config.save(CONFIG_PATH)
	if error != OK:
		push_error("Could not clear accessibility preference (error %d)" % error)
