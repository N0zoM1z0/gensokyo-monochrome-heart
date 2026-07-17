extends SceneTree
## Deterministic semantic-input proof of the complete M01 navigation loop.

const MAX_WAIT_FRAMES := 240
const TEST_ROOT := "user://tests/m01_flow"

var failures: Array[String] = []
var shell: GameShell


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_prepare_services()
	var packed_shell := load("res://src/presentation/shell/Main.tscn") as PackedScene
	if packed_shell == null:
		_fail("Main shell could not be loaded")
		await _finish()
		return
	shell = packed_shell.instantiate() as GameShell
	root.add_child(shell)
	if not await _wait_for_route(&"title"):
		await _finish()
		return
	await _verify_live_locale_route()
	await _verify_new_profile_to_mode()
	await _verify_pause_modal_focus_and_resume()
	await _verify_pause_return_to_title()
	await _verify_continue_from_latest_save()
	await _verify_completed_slice_returns_to_title()
	await _finish()


func _prepare_services() -> void:
	_remove_tree(TEST_ROOT)
	var localization := root.get_node_or_null("LocalizationService")
	if localization != null:
		localization.set_locale(&"en", false)
	var settings := root.get_node_or_null("SettingsService")
	if settings != null:
		settings.set_forced_presentation_profile(&"")
		settings.set_preferred_presentation_profile(&"A")
		settings.set_reduced_motion(false)
		settings.set_safe_flash(false)
		settings.configure_audio_accessibility(false, false)
	var theme := root.get_node_or_null("UiThemeRegistry")
	if theme != null:
		theme.set_native_profile(&"A")
	var accessibility := root.get_node_or_null("AccessibilityState")
	if accessibility != null:
		accessibility.preset = AccessibilityState.Preset.ORIGINAL
		accessibility.is_first_run = true
		accessibility.is_reduced_motion = false
		accessibility.is_safe_flash = false
	var kernel := root.get_node_or_null("GameKernel")
	if kernel != null:
		kernel.clear_state()
	var save_service := root.get_node_or_null("SaveService")
	if save_service != null:
		save_service.configure_for_test(kernel, TEST_ROOT)
	var focus_router := root.get_node_or_null("FocusRouter")
	if focus_router != null:
		focus_router.clear()


func _verify_live_locale_route() -> void:
	_press(GameInput.MOVE_DOWN)
	_press(GameInput.MOVE_DOWN)
	_press(GameInput.CONFIRM)
	if not await _wait_for_route(&"credits"):
		return
	var credits := shell.active_primary_screen() as CreditsScreen
	if credits == null or credits.screen_id != &"credits":
		_fail("title Credits entry did not open the legal presentation")
		return
	_press(GameInput.CONFIRM)
	if not credits.is_paused:
		_fail("Credits Confirm did not pause its readable scroll")
	_press(GameInput.CANCEL)
	if not await _wait_for_route(&"title"):
		return
	if shell.active_primary_screen().current_focus_id() != &"title.credits":
		_fail("returning from Credits did not restore title focus")
	_press(GameInput.MOVE_UP)
	_press(GameInput.CONFIRM)
	if not await _wait_for_route(&"options"):
		return
	var options := shell.active_primary_screen()
	var instance_id := options.get_instance_id()
	options.call("arm_input_for_test")
	_press(GameInput.CONFIRM)
	await _wait_frames(1)
	var localization := root.get_node_or_null("LocalizationService")
	if localization == null or localization.locale != &"ja":
		_fail("Options did not switch the active locale to Japanese")
	if shell.active_primary_screen().get_instance_id() != instance_id:
		_fail("locale switching restarted the active Options scene")
	for _step: int in range(8):
		_press(GameInput.MOVE_DOWN)
	if options.call("current_focus_id") != &"options.mono_audio":
		_fail("Options did not expose Mono Audio at its stable focus ID")
	options.call("arm_input_for_test")
	_press(GameInput.CONFIRM)
	_press(GameInput.MOVE_DOWN)
	if options.call("current_focus_id") != &"options.low_dynamic_range":
		_fail("Options did not expose Low Dynamic Range at its stable focus ID")
	options.call("arm_input_for_test")
	_press(GameInput.CONFIRM)
	var settings := root.get_node_or_null("SettingsService")
	if settings == null or not settings.is_mono_audio or not settings.is_low_dynamic_range:
		_fail("Options did not apply live mono and low-dynamic audio settings")
	else:
		var config := ConfigFile.new()
		if config.load(SettingsService.CONFIG_PATH) != OK:
			_fail("Options did not persist its live audio settings")
		elif not bool(config.get_value("audio", "mono", false)) or not bool(config.get_value("audio", "low_dynamic_range", false)):
			_fail("persisted audio accessibility values did not match the live Options state")
	_press(GameInput.CANCEL)
	if not await _wait_for_route(&"title"):
		return
	if localization != null and localization.locale != &"en":
		_fail("Options cancel did not restore its opening locale")
	if settings != null and (settings.is_mono_audio or settings.is_low_dynamic_range):
		_fail("Options cancel did not restore its opening audio mix")


func _verify_new_profile_to_mode() -> void:
	var glyph_service := root.get_node_or_null("InputGlyphService")
	if glyph_service != null:
		var controller_event := InputEventJoypadButton.new()
		controller_event.button_index = JOY_BUTTON_A
		glyph_service.observe_event(controller_event)
		controller_event = null
	_press(GameInput.MOVE_UP)
	_press(GameInput.CONFIRM)
	if not await _wait_for_route(&"profile_select"):
		return
	_press(GameInput.MOVE_RIGHT)
	_press(GameInput.CONFIRM)
	if not await _wait_for_route(&"accessibility"):
		return
	var settings := root.get_node_or_null("SettingsService")
	if settings == null or settings.preferred_presentation_profile != &"B":
		_fail("profile selection did not store visual Profile B")
	_press(GameInput.MOVE_DOWN)
	_press(GameInput.MOVE_DOWN)
	_press(GameInput.CONFIRM)
	if not await _wait_for_route(&"vertical_slice"):
		return
	var accessibility := root.get_node_or_null("AccessibilityState")
	if accessibility == null or not accessibility.is_reduced_motion:
		_fail("first-run Low Motion preset was not applied")
	var kernel := root.get_node_or_null("GameKernel")
	var state: Variant = kernel.state_snapshot() if kernel != null else null
	if not state is GameState or state.profile_id != &"p02" or state.protagonist.comfort_profile_id != &"accessibility.low_motion":
		_fail("Profile B and Low Motion did not initialize the shared typed GameState")
	var save_service := root.get_node_or_null("SaveService")
	var has_day_card := false
	if save_service != null:
		for card: SaveCardMetadata in save_service.list_cards(&"p02"):
			if card.slot_id == &"auto_day":
				has_day_card = true
	if not has_day_card:
		_fail("entering the first day did not produce the rolling day-start autosave")
	var transition := shell.get_node("FixedResolutionRoot/GameViewport/TransitionCanvas/TransitionController") as TransitionController
	if transition.last_style != TransitionOverlay.STYLE_BORDER_TICK:
		_fail("Low Motion route still used the paper-fold transition")
	if glyph_service != null and glyph_service.active_device != 1:
		_fail("controller input did not preserve the active controller glyph family")
	if shell.active_primary_screen().process_mode != Node.PROCESS_MODE_PAUSABLE:
		_fail("ModeHost content would continue processing while the tree is paused")
	var slice := shell.active_primary_screen() as VerticalSliceMode
	if settings != null and slice != null:
		settings.configure_audio_accessibility(true, true)
		if not slice.music_player.is_mono_audio or not slice.music_player.is_low_dynamic_range:
			_fail("live audio settings did not propagate to the active production music director")
		settings.configure_audio_accessibility(false, false)


func _verify_pause_modal_focus_and_resume() -> void:
	Input.action_press(GameInput.CONFIRM)
	Input.action_press(GameInput.PAUSE)
	_press(GameInput.PAUSE)
	if not shell.has_open_pause() or not paused:
		_fail("Pause did not open synchronously while freezing the tree")
		return
	if Input.is_action_pressed(GameInput.CONFIRM) or Input.is_action_pressed(GameInput.PAUSE):
		_fail("opening Pause did not release active semantic input")
	await _wait_frames(3)
	shell.pause_screen.arm_input_for_test()
	_press(GameInput.MOVE_DOWN)
	_press(GameInput.CONFIRM)
	if not await _wait_until_modal_options(true):
		return
	_press(GameInput.CANCEL)
	if not await _wait_until_modal_options(false):
		return
	if not shell.pause_screen.visible or shell.pause_screen.current_focus_id() != &"pause.options":
		_fail("closing nested Options did not restore Pause focus")
	_press(GameInput.CANCEL)
	await _wait_frames(2)
	if not shell.has_open_pause():
		_fail("Pause closed before the three-frame resume cue completed")
	await _wait_frames(3)
	if shell.has_open_pause() or paused:
		_fail("Pause did not resume after its three-frame cue")
	if shell.active_route_id() != &"vertical_slice":
		_fail("resume replaced the active mode instead of preserving it")


func _verify_pause_return_to_title() -> void:
	_press(GameInput.PAUSE)
	if not shell.has_open_pause():
		_fail("Pause could not reopen after resume")
		return
	await _wait_frames(3)
	shell.pause_screen.arm_input_for_test()
	_press(GameInput.MOVE_DOWN)
	_press(GameInput.MOVE_DOWN)
	_press(GameInput.CONFIRM)
	if not await _wait_for_route(&"title"):
		return
	if paused or shell.has_open_pause():
		_fail("return-to-title left the game paused or retained the modal")
	var kernel := root.get_node_or_null("GameKernel")
	if kernel != null and kernel.has_active_state():
		_fail("return-to-title retained an active story state")


func _verify_continue_from_latest_save() -> void:
	var title := shell.active_primary_screen() as TitleScreen
	if title == null or title.current_focus_id() != &"title.continue":
		_fail("title did not expose Continue after a valid day-start save existed")
		return
	_press(GameInput.CONFIRM)
	if not await _wait_for_route(&"vertical_slice"):
		return
	var kernel := root.get_node_or_null("GameKernel")
	var state: Variant = kernel.state_snapshot() if kernel != null else null
	if not state is GameState or state.profile_id != &"p02":
		_fail("Continue did not restore the saved Profile B story state")
	var settings := root.get_node_or_null("SettingsService")
	if settings == null or settings.preferred_presentation_profile != &"B":
		_fail("Continue did not restore the saved presentation-profile identity")
	var accessibility := root.get_node_or_null("AccessibilityState")
	if accessibility == null or accessibility.preset != AccessibilityState.Preset.LOW_MOTION:
		_fail("Continue did not restore the saved Low Motion comfort preset")
	var slice := shell.active_primary_screen() as VerticalSliceMode
	if slice == null or slice.phase_id() != &"invitation":
		_fail("Continue did not rebuild the vertical slice at its saved day cursor")


func _verify_completed_slice_returns_to_title() -> void:
	var slice := shell.active_primary_screen() as VerticalSliceMode
	if slice == null:
		_fail("completed-slice shell test had no active vertical slice")
		return
	slice.mode_completed.emit(ModeResult.new(&"complete"))
	if not await _wait_for_route(&"title"):
		return
	var title := shell.active_primary_screen() as TitleScreen
	if title == null or title.current_focus_id() != &"title.continue":
		_fail("completed vertical slice did not return to a title with Continue available")


func _press(action: StringName) -> void:
	shell.receive_semantic_action(action)


func _wait_for_route(route_id: StringName) -> bool:
	for _frame: int in range(MAX_WAIT_FRAMES):
		if shell.active_route_id() == route_id and not shell.scene_router.is_routing:
			await _wait_frames(3)
			var screen := shell.active_primary_screen()
			if screen != null and screen.has_method("arm_input_for_test"):
				screen.call("arm_input_for_test")
			return true
		await process_frame
	_fail("timed out waiting for route: %s" % route_id)
	return false


func _wait_until_modal_options(expected_open: bool) -> bool:
	for _frame: int in range(30):
		if shell.has_open_modal_options() == expected_open:
			await _wait_frames(2)
			if expected_open and shell.modal_options_screen != null:
				shell.modal_options_screen.arm_input_for_test()
			return true
		await process_frame
	_fail("timed out waiting for nested Options open=%s" % expected_open)
	return false


func _wait_frames(frame_count: int) -> void:
	for _frame: int in range(frame_count):
		await process_frame


func _remove_tree(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var child := "%s/%s" % [path, entry]
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(child))
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(absolute)


func _fail(message: String) -> void:
	failures.append(message)


func _finish() -> void:
	paused = false
	print("M01 integration flow: failures=%d" % failures.size())
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	if shell != null and is_instance_valid(shell):
		shell.queue_free()
		shell = null
	await process_frame
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
