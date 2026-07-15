extends Node
## Owns presentation/accessibility preferences only; it never mutates story state.

signal presentation_settings_changed

const DEFAULT_PROFILE: StringName = &"A"
const VALID_PROFILES: Array[StringName] = [&"A", &"B", &"C", &"D"]

var forced_presentation_profile: StringName = &""
var is_reduced_motion: bool = false
var is_safe_flash: bool = false


func set_forced_presentation_profile(profile_id: StringName) -> void:
	var normalized: StringName = profile_id if profile_id in VALID_PROFILES else &""
	if forced_presentation_profile == normalized:
		return
	forced_presentation_profile = normalized
	presentation_settings_changed.emit()


func set_reduced_motion(enabled: bool) -> void:
	if is_reduced_motion == enabled:
		return
	is_reduced_motion = enabled
	presentation_settings_changed.emit()


func set_safe_flash(enabled: bool) -> void:
	if is_safe_flash == enabled:
		return
	is_safe_flash = enabled
	presentation_settings_changed.emit()


func resolve_profile(requested_profile: StringName) -> StringName:
	if forced_presentation_profile != &"":
		return forced_presentation_profile
	if requested_profile in VALID_PROFILES:
		return requested_profile
	return DEFAULT_PROFILE
