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
	settings.configure_audio_accessibility(true, true, false)
	if InputMap.get_actions() != actions_before:
		failures.append("presentation or audio settings changed the input action contract")
	if not settings.is_reduced_motion or not settings.is_safe_flash:
		failures.append("accessibility presentation settings did not persist")
	if not settings.is_mono_audio or not settings.is_low_dynamic_range:
		failures.append("audio accessibility settings did not retain the selected modes")
	var master_bus := AudioServer.get_bus_index(&"Master")
	if master_bus < 0 or AudioServer.get_bus_effect_count(master_bus) < 2:
		failures.append("Master bus omitted the mono and low-dynamic processors")
	else:
		var mono_effect := AudioServer.get_bus_effect(master_bus, 0) as AudioEffectStereoEnhance
		var compact_effect := AudioServer.get_bus_effect(master_bus, 1) as AudioEffectCompressor
		if mono_effect == null:
			failures.append("mono mode is not backed by a stereo-collapse processor")
		elif not is_zero_approx(mono_effect.pan_pullout):
			failures.append("mono processor did not collapse stereo panning to center")
		if compact_effect == null:
			failures.append("low-dynamic mode is not backed by a peak compressor")
		elif not is_equal_approx(compact_effect.threshold, -14.0) or not is_equal_approx(compact_effect.ratio, 3.0):
			failures.append("low-dynamic compressor drifted from its reviewed threshold or ratio")
		if not AudioServer.is_bus_effect_enabled(master_bus, 0):
			failures.append("mono mode did not enable the Master downmix effect")
		if not AudioServer.is_bus_effect_enabled(master_bus, 1):
			failures.append("low-dynamic mode did not enable the Master compressor")
	var normal_span := AudioMixPolicy.gain_db(AudioMixPolicy.Role.DIALOGUE_WARNING) - AudioMixPolicy.gain_db(AudioMixPolicy.Role.AMBIENCE)
	var compact_span := AudioMixPolicy.gain_db(AudioMixPolicy.Role.DIALOGUE_WARNING, &"", true) - AudioMixPolicy.gain_db(AudioMixPolicy.Role.AMBIENCE, &"", true)
	if compact_span >= normal_span:
		failures.append("low-dynamic mix did not reduce the warning-to-ambience gain span")
	settings.configure_audio_accessibility(false, false, false)
	settings.free()
