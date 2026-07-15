extends Node
## Resolves visual-only profiles and broadcasts skin changes to shared components.

signal profile_changed(profile_id: StringName)

var native_profile_id: StringName = &"A"


func _ready() -> void:
	var settings := get_node_or_null("/root/SettingsService")
	if settings != null:
		native_profile_id = settings.preferred_presentation_profile
		settings.presentation_settings_changed.connect(_on_settings_changed)


func set_native_profile(profile_id: StringName) -> void:
	var normalized := profile_id if profile_id in PresentationProfileRegistry.PROFILE_PATHS else &"A"
	if native_profile_id == normalized:
		return
	native_profile_id = normalized
	profile_changed.emit(effective_profile_id())


func effective_profile_id() -> StringName:
	var settings := get_node_or_null("/root/SettingsService")
	return settings.resolve_profile(native_profile_id) if settings != null else native_profile_id


func profile() -> PresentationProfile:
	return PresentationProfileRegistry.resolve(effective_profile_id())


func _on_settings_changed() -> void:
	profile_changed.emit(effective_profile_id())
