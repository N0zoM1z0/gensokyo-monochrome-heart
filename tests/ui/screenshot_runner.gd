extends SceneTree
## Renders one fixture scene to an exact 320×180 PNG without opening the editor.

const CANVAS_SIZE := Vector2i(320, 180)
const DEFAULT_SCENE := "res://tests/ui/fixtures/VisualFoundationFixture.tscn"
const DEFAULT_OUTPUT := "res://tests/screenshots/generated/visual_foundation_A_en.png"
const UI_SCALE_POLICY := preload("res://src/presentation/ui/UiScalePolicy.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	_configure_input_fixture(options)
	var packed_scene := ResourceLoader.load(options.scene_path) as PackedScene
	if packed_scene == null:
		_fail("fixture scene could not be loaded: %s" % options.scene_path)
		return
	var viewport := SubViewport.new()
	viewport.size = CANVAS_SIZE
	viewport.disable_3d = true
	viewport.transparent_bg = false
	viewport.snap_2d_transforms_to_pixel = true
	viewport.snap_2d_vertices_to_pixel = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var fixture := packed_scene.instantiate()
	viewport.add_child(fixture)
	if fixture.has_method("configure_fixture"):
		fixture.call(
			"configure_fixture",
			options.profile_id,
			options.locale,
			options.forced_profile,
			options.is_reduced_motion,
			options.is_safe_flash
		)
	_apply_ui_scale_fixture(fixture, options.ui_scale_percent)
	_apply_one_handed_fixture(fixture, options.one_handed)
	if options.focus_id != &"" and fixture.has_method("restore_focus"):
		fixture.call("restore_focus", options.focus_id)
	if options.semantic_action != &"" and fixture.has_method("handle_semantic_action"):
		fixture.call("handle_semantic_action", options.semantic_action)
	var resolved_profile := options.profile_id
	if fixture.has_method("resolved_profile_id"):
		resolved_profile = fixture.call("resolved_profile_id")
	# Give newly-created textures/MultiMeshes enough synchronized submissions to
	# finish their first upload before reading the viewport. Without the final
	# sync, software renderers can return a valid one-bit but incomplete frame.
	# Japanese glyph atlases plus a newly-instantiated story stage can require
	# several additional software-renderer submissions before readback.
	for _warmup_frame: int in range(8):
		await process_frame
		RenderingServer.force_draw(false)
	await process_frame
	RenderingServer.force_draw(false)
	var texture := viewport.get_texture()
	if texture == null:
		_fail("active rendering driver did not produce a viewport texture")
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		_fail("active rendering driver returned an empty screenshot")
		return
	_threshold_to_one_bit(image)
	if image.get_size() != CANVAS_SIZE:
		_fail("fixture rendered at %s instead of %s" % [image.get_size(), CANVAS_SIZE])
		return
	var output_path: String = options.output_path
	var absolute_output := ProjectSettings.globalize_path(output_path) if output_path.begins_with("res://") else output_path
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_output.get_base_dir())
	if directory_error != OK:
		_fail("could not create screenshot directory: %s" % absolute_output.get_base_dir())
		return
	var save_error := image.save_png(absolute_output)
	if save_error != OK:
		_fail("could not save screenshot %s (error %d)" % [output_path, save_error])
		return
	var palette_errors := OneBitImageValidator.new().validate_image(image, output_path)
	if not palette_errors.is_empty():
		for palette_error: String in palette_errors:
			printerr("ERROR: %s" % palette_error)
		quit(1)
		return
	print(
		"Screenshot fixture: scene=%s output=%s size=%s requested_profile=%s resolved_profile=%s locale=%s input=%s one_handed=%s ui_scale=%d"
		% [options.scene_path, output_path, image.get_size(), options.profile_id, resolved_profile, options.locale, options.input_device, options.one_handed, options.ui_scale_percent]
	)
	# Explicitly release the fixture tree before this short-lived process exits.
	viewport.free()
	quit(0)


func _threshold_to_one_bit(image: Image) -> void:
	# Threshold the final readback instead of sampling the viewport through a
	# screen-texture shader, so exported evidence does not depend on back-buffer
	# sampling behavior under different rendering drivers.
	image.convert(Image.FORMAT_RGBA8)
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var sampled := image.get_pixel(x, y)
			var luminance := sampled.r * 0.2126 + sampled.g * 0.7152 + sampled.b * 0.0722
			var bit := 1.0 if luminance >= 0.5 else 0.0
			image.set_pixel(x, y, Color(bit, bit, bit, 1.0))


func _configure_input_fixture(options: ScreenshotOptions) -> void:
	match options.one_handed:
		"left":
			InputMapInstaller.apply_one_handed_preset(InputMapInstaller.OneHandedPreset.LEFT_HAND)
		"right":
			InputMapInstaller.apply_one_handed_preset(InputMapInstaller.OneHandedPreset.RIGHT_HAND)
		_:
			InputMapInstaller.install_defaults(true)
	var glyph_service := get_root().get_node_or_null("InputGlyphService")
	if glyph_service == null:
		return
	if options.input_device == "controller":
		var controller_event := InputEventJoypadButton.new()
		controller_event.button_index = JOY_BUTTON_A
		glyph_service.observe_event(controller_event)
	else:
		var keyboard_event := InputEventKey.new()
		keyboard_event.physical_keycode = KEY_Z
		glyph_service.observe_event(keyboard_event)


func _apply_ui_scale_fixture(node: Node, percent: int) -> void:
	if node.has_method("set_ui_scale_fixture"):
		node.call("set_ui_scale_fixture", percent)
		return
	for child: Node in node.get_children():
		_apply_ui_scale_fixture(child, percent)


func _apply_one_handed_fixture(node: Node, preset_name: String) -> void:
	if node.has_method("set_one_handed_fixture"):
		var preset := InputMapInstaller.OneHandedPreset.NONE
		if preset_name == "left":
			preset = InputMapInstaller.OneHandedPreset.LEFT_HAND
		elif preset_name == "right":
			preset = InputMapInstaller.OneHandedPreset.RIGHT_HAND
		node.call("set_one_handed_fixture", preset)
		return
	for child: Node in node.get_children():
		_apply_one_handed_fixture(child, preset_name)


func _parse_options(arguments: PackedStringArray) -> ScreenshotOptions:
	var options := ScreenshotOptions.new()
	for argument: String in arguments:
		if argument.begins_with("--scene="):
			options.scene_path = argument.trim_prefix("--scene=")
		elif argument.begins_with("--output="):
			options.output_path = argument.trim_prefix("--output=")
		elif argument.begins_with("--profile="):
			options.profile_id = StringName(argument.trim_prefix("--profile="))
		elif argument.begins_with("--forced-profile="):
			options.forced_profile = StringName(argument.trim_prefix("--forced-profile="))
		elif argument.begins_with("--locale="):
			options.locale = StringName(argument.trim_prefix("--locale="))
		elif argument == "--reduced-motion":
			options.is_reduced_motion = true
		elif argument == "--safe-flash":
			options.is_safe_flash = true
		elif argument.begins_with("--input-device="):
			options.input_device = argument.trim_prefix("--input-device=")
		elif argument.begins_with("--one-handed="):
			options.one_handed = argument.trim_prefix("--one-handed=")
		elif argument.begins_with("--ui-scale="):
			options.ui_scale_percent = UI_SCALE_POLICY.normalize(int(argument.trim_prefix("--ui-scale=")))
		elif argument.begins_with("--focus-id="):
			options.focus_id = StringName(argument.trim_prefix("--focus-id="))
		elif argument.begins_with("--semantic-action="):
			options.semantic_action = StringName(argument.trim_prefix("--semantic-action="))
	return options


func _fail(message: String) -> void:
	printerr("ERROR: %s" % message)
	quit(1)


class ScreenshotOptions:
	extends RefCounted

	var scene_path: String = DEFAULT_SCENE
	var output_path: String = DEFAULT_OUTPUT
	var profile_id: StringName = &"A"
	var forced_profile: StringName = &""
	var locale: StringName = &"en"
	var is_reduced_motion: bool = false
	var is_safe_flash: bool = false
	var input_device: String = "keyboard"
	var one_handed: String = "off"
	var ui_scale_percent: int = 100
	var focus_id: StringName = &""
	var semantic_action: StringName = &""
