class_name TestPresentationFoundation
extends RefCounted

const SETTINGS_SERVICE_SCRIPT := preload("res://src/autoload/SettingsService.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_validate_project_settings(failures)
	_validate_scale_layout(failures)
	_validate_profiles(failures)
	_validate_settings_invariance(failures)
	return failures


func _validate_project_settings(failures: Array[String]) -> void:
	var expected := {
		"display/window/size/viewport_width": 320,
		"display/window/size/viewport_height": 180,
		"display/window/stretch/scale_mode": "integer",
		"rendering/textures/canvas_textures/default_texture_filter": 0,
		"rendering/textures/default_filters/use_nearest_mipmap_filter": false,
		"physics/common/physics_interpolation": false,
	}
	for setting: String in expected:
		var actual: Variant = ProjectSettings.get_setting(setting)
		if actual != expected[setting]:
			failures.append("%s expected %s, got %s" % [setting, expected[setting], actual])


func _validate_scale_layout(failures: Array[String]) -> void:
	var controller := PixelScaleController.new()
	var cases := [
		[Vector2i(960, 540), 3, Vector2i.ZERO],
		[Vector2i(1000, 600), 3, Vector2i(20, 30)],
		[Vector2i(500, 400), 1, Vector2i(90, 110)],
		[Vector2i(2560, 1440), 6, Vector2i(320, 180)],
	]
	for fixture: Array in cases:
		var layout := controller.calculate_layout(fixture[0])
		if layout.scale != fixture[1] or layout.letterbox_offset != fixture[2]:
			failures.append(
				"layout %s expected scale=%d offset=%s, got scale=%d offset=%s"
				% [fixture[0], fixture[1], fixture[2], layout.scale, layout.letterbox_offset]
			)
	controller.free()


func _validate_profiles(failures: Array[String]) -> void:
	var expected_names := {
		&"A": "Pocket Shrine",
		&"B": "PC-98 Dither",
		&"C": "Woodblock Adventure",
		&"D": "Midnight LCD",
	}
	for profile_id: StringName in expected_names:
		var profile := PresentationProfileRegistry.resolve(profile_id)
		if profile.profile_id != profile_id or profile.display_name != expected_names[profile_id]:
			failures.append("profile %s does not match the token contract" % profile_id)
		for error: String in profile.validation_errors():
			failures.append("profile %s: %s" % [profile_id, error])
	if PresentationProfileRegistry.resolve(&"unknown").profile_id != &"A":
		failures.append("unknown presentation profile did not fall back to A")


func _validate_settings_invariance(failures: Array[String]) -> void:
	var actions_before := InputMap.get_actions()
	var settings := SETTINGS_SERVICE_SCRIPT.new()
	for profile_id: StringName in [&"A", &"B", &"C", &"D", &"unknown"]:
		settings.set_forced_presentation_profile(profile_id)
		settings.resolve_profile(profile_id)
	settings.set_reduced_motion(true)
	settings.set_safe_flash(true)
	if InputMap.get_actions() != actions_before:
		failures.append("presentation settings changed the input action contract")
	if not settings.is_reduced_motion or not settings.is_safe_flash:
		failures.append("accessibility presentation settings did not persist")
	settings.free()
