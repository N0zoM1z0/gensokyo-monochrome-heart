extends SceneTree
## Renders one fixture scene to an exact 320×180 PNG without opening the editor.

const CANVAS_SIZE := Vector2i(320, 180)
const DEFAULT_SCENE := "res://tests/ui/fixtures/VisualFoundationFixture.tscn"
const DEFAULT_OUTPUT := "res://tests/screenshots/generated/visual_foundation_A_en.png"
const ONE_BIT_SHADER := preload("res://ui/theme/one_bit_post_process.gdshader")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
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
	_add_one_bit_threshold(viewport)
	var resolved_profile := options.profile_id
	if fixture.has_method("resolved_profile_id"):
		resolved_profile = fixture.call("resolved_profile_id")
	await process_frame
	RenderingServer.force_draw(false)
	await process_frame
	var texture := viewport.get_texture()
	if texture == null:
		_fail("active rendering driver did not produce a viewport texture")
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		_fail("active rendering driver returned an empty screenshot")
		return
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
		"Screenshot fixture: scene=%s output=%s size=%s requested_profile=%s resolved_profile=%s locale=%s"
		% [options.scene_path, output_path, image.get_size(), options.profile_id, resolved_profile, options.locale]
	)
	# Explicitly release the fixture tree before this short-lived process exits.
	viewport.free()
	quit(0)


func _add_one_bit_threshold(viewport: SubViewport) -> void:
	var material := ShaderMaterial.new()
	material.shader = ONE_BIT_SHADER
	var threshold := ColorRect.new()
	threshold.position = Vector2.ZERO
	threshold.size = CANVAS_SIZE
	threshold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	threshold.z_index = 1000
	threshold.material = material
	viewport.add_child(threshold)


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
