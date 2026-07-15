class_name GameShell
extends Node
## Persistent M01 shell: primary async routes, synchronous pause, and modal focus restore.

const PAUSE_SCENE := preload("res://ui/screens/pause_screen.tscn")
const OPTIONS_SCENE := preload("res://ui/screens/options_screen.tscn")

@onready var input_router: InputRouter = $InputRouter
@onready var scene_router: SceneRouter = $FixedResolutionRoot/GameViewport/SceneRouter
@onready var modal_host: Control = $FixedResolutionRoot/GameViewport/ModalCanvas/ModalHost

var pause_screen: PauseScreen
var modal_options_screen: OptionsScreen
var _is_resuming: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	input_router.process_mode = Node.PROCESS_MODE_ALWAYS
	input_router.set_action_candidate_resolver(_resolve_input_candidates)
	input_router.semantic_action_pressed.connect(_on_semantic_action_pressed)
	scene_router.route_completed.connect(_on_route_completed)
	_boot.call_deferred()


func _boot() -> void:
	var content_db := get_node_or_null("/root/ContentDB")
	if content_db == null or not content_db.is_loaded():
		var diagnostic := "ContentDB singleton is unavailable."
		if content_db != null and content_db.last_report() != null:
			diagnostic = content_db.last_report().human_readable()
		push_error("Title route blocked because authored content is invalid:\n%s" % diagnostic)
		return
	await _route_primary(&"title")


func receive_semantic_action(action: StringName) -> void:
	_on_semantic_action_pressed(action)


func active_primary_screen() -> Node:
	return scene_router.current_screen


func active_route_id() -> StringName:
	return scene_router.current_screen_id


func has_open_pause() -> bool:
	return pause_screen != null and is_instance_valid(pause_screen)


func has_open_modal_options() -> bool:
	return modal_options_screen != null and is_instance_valid(modal_options_screen)


func _on_semantic_action_pressed(action: StringName) -> void:
	if modal_options_screen != null and is_instance_valid(modal_options_screen):
		modal_options_screen.handle_semantic_action(action)
		return
	if pause_screen != null and is_instance_valid(pause_screen):
		pause_screen.handle_semantic_action(action)
		return
	if action == GameInput.PAUSE and scene_router.current_screen_id in [&"foundation_mode", &"vertical_slice"]:
		_open_pause()
		return
	var active_screen := scene_router.current_screen
	if active_screen != null and active_screen.has_method("handle_semantic_action"):
		active_screen.call("handle_semantic_action", action)


func _on_route_completed(result: ScreenRouteResult) -> void:
	var content_db := get_node_or_null("/root/ContentDB")
	if content_db != null:
		content_db.set_active_mode(result.screen_id)
	if result.screen != null and result.screen.has_signal("command_requested"):
		result.screen.connect("command_requested", _on_screen_command)
	if result.screen_id == &"vertical_slice" and result.screen != null and result.screen.has_signal("mode_completed"):
		result.screen.connect("mode_completed", _on_primary_mode_completed)


func _on_primary_mode_completed(result: ModeResult) -> void:
	if scene_router.current_screen_id != &"vertical_slice" or result == null or result.result_tag != &"complete":
		return
	_return_to_title_after_mode.call_deferred()


func _return_to_title_after_mode() -> void:
	_release_active_inputs()
	var focus_router := get_node_or_null("/root/FocusRouter")
	if focus_router != null:
		focus_router.clear()
	await _route_primary(&"title")


func _on_screen_command(command_id: StringName, payload: Dictionary) -> void:
	match command_id:
		&"continue_game":
			_continue_game.call_deferred(payload)
		&"new_profile":
			var kernel := get_node_or_null("/root/GameKernel")
			if kernel != null:
				kernel.clear_state()
			_push_primary_focus()
			_route_primary.call_deferred(&"profile_select")
		&"open_options":
			_push_primary_focus()
			_route_primary.call_deferred(
				&"options",
				{"origin": &"title"}
			)
		&"open_credits":
			_push_primary_focus()
			_route_primary.call_deferred(&"credits")
		&"quit":
			get_tree().quit()
		&"back":
			_route_back_from_primary.call_deferred()
		&"profile_selected":
			_route_after_profile.call_deferred(payload)
		&"accessibility_selected":
			_apply_accessibility_and_enter_mode.call_deferred(payload)
		&"options_apply", &"options_cancel":
			_close_options.call_deferred(payload)
		&"resume":
			_resume_from_pause.call_deferred()
		&"pause_options":
			_open_modal_options.call_deferred()
		&"return_title":
			_return_to_title_from_pause.call_deferred()


func _route_primary(
	screen_id: StringName,
	parameters: Dictionary = {},
	restore_focus_id: StringName = &""
) -> ScreenRouteResult:
	var result := await scene_router.route_to(
		ScreenRouteRequest.new(screen_id, parameters, restore_focus_id)
	)
	if not result.is_success():
		push_error(result.diagnostic)
	return result


func _route_back_from_primary() -> void:
	var destination: StringName = &"title"
	if scene_router.current_screen_id == &"accessibility":
		destination = &"profile_select"
	var restore_focus := _pop_focus()
	await _route_primary(destination, {}, restore_focus)


func _route_after_profile(payload: Dictionary) -> void:
	var accessibility := get_node_or_null("/root/AccessibilityState")
	var comfort_profile_id: StringName = accessibility.save_profile_id() if accessibility != null else &"accessibility.original"
	var presentation_profile_id := StringName(payload.get("profile_id", &""))
	var story_profile_id := ProfileIdentityRules.story_profile_id(presentation_profile_id)
	var kernel := get_node_or_null("/root/GameKernel")
	if kernel == null:
		push_error("New profile route blocked because GameKernel is unavailable.")
		return
	var created: Variant = kernel.create_new_profile(story_profile_id, comfort_profile_id)
	if not created is CommandResult or not created.is_success():
		push_error("New profile route blocked: %s" % [created.message if created is CommandResult else "unknown GameKernel result"])
		return
	if accessibility != null and accessibility.is_first_run:
		await _route_primary(&"accessibility")
	else:
		await _enter_vertical_slice()


func _apply_accessibility_and_enter_mode(payload: Dictionary) -> void:
	var accessibility := get_node_or_null("/root/AccessibilityState")
	if accessibility != null:
		accessibility.apply_named_preset(StringName(payload.get("preset_id", &"original")))
		var kernel := get_node_or_null("/root/GameKernel")
		if kernel != null:
			var result: Variant = kernel.dispatch(SetComfortProfileCommand.new(accessibility.save_profile_id()))
			if not result is CommandResult or (not result.is_success() and result.code != CommandResult.Code.ALREADY_EXISTS):
				push_error("Could not persist accessibility profile into GameState.")
				return
	await _enter_vertical_slice()


func _enter_vertical_slice() -> void:
	var focus_router := get_node_or_null("/root/FocusRouter")
	if focus_router != null:
		focus_router.clear()
	var save_service := get_node_or_null("/root/SaveService")
	if save_service != null:
		var result: Variant = save_service.autosave(&"day_start")
		if result is SaveOperationResult and not result.is_success():
			push_warning("Day-start autosave failed: %s" % result.message)
	await _route_primary(&"vertical_slice")


func _continue_game(payload: Dictionary) -> void:
	var profile_id := StringName(payload.get("profile_id", &""))
	var slot_id := StringName(payload.get("slot_id", &""))
	var save_service := get_node_or_null("/root/SaveService")
	if save_service == null:
		push_error("Continue route blocked because SaveService is unavailable.")
		return
	var loaded: Variant = save_service.load_slot(profile_id, slot_id)
	if not loaded is SaveOperationResult or not loaded.is_success():
		push_error("Continue route could not load %s/%s." % [profile_id, slot_id])
		return
	var state := loaded.state as GameState
	var presentation_profile_id := ProfileIdentityRules.presentation_profile_id(profile_id)
	var settings := get_node_or_null("/root/SettingsService")
	if settings != null:
		settings.set_preferred_presentation_profile(presentation_profile_id)
	var theme := get_node_or_null("/root/UiThemeRegistry")
	if theme != null:
		theme.set_native_profile(presentation_profile_id)
	var accessibility := get_node_or_null("/root/AccessibilityState")
	if accessibility != null and state != null:
		accessibility.apply_named_preset(
			StringName(String(state.protagonist.comfort_profile_id).trim_prefix("accessibility.")),
			false
		)
	var focus_router := get_node_or_null("/root/FocusRouter")
	if focus_router != null:
		focus_router.clear()
	await _route_primary(&"vertical_slice")


func _open_pause() -> void:
	if has_open_pause() or _is_resuming:
		return
	_release_active_inputs()
	_push_primary_focus()
	pause_screen = PAUSE_SCENE.instantiate() as PauseScreen
	pause_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	modal_host.add_child(pause_screen)
	pause_screen.command_requested.connect(_on_screen_command)
	get_tree().paused = true


func _open_modal_options() -> void:
	if not has_open_pause() or has_open_modal_options():
		return
	var focus_router := get_node_or_null("/root/FocusRouter")
	if focus_router != null:
		focus_router.push_prior_focus(pause_screen.current_focus_id())
	pause_screen.visible = false
	modal_options_screen = OPTIONS_SCENE.instantiate() as OptionsScreen
	modal_options_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	modal_host.add_child(modal_options_screen)
	modal_options_screen.configure_route(
		ScreenRouteRequest.new(&"options", {"origin": &"pause"})
	)
	modal_options_screen.command_requested.connect(_on_screen_command)


func _close_options(payload: Dictionary) -> void:
	if StringName(payload.get("origin", &"title")) == &"pause" and has_open_modal_options():
		modal_options_screen.queue_free()
		modal_options_screen = null
		pause_screen.visible = true
		pause_screen.restore_focus(_pop_focus())
		pause_screen.arm_input_for_test()
		return
	await _route_primary(&"title", {}, _pop_focus())


func _resume_from_pause() -> void:
	if not has_open_pause() or _is_resuming:
		return
	_is_resuming = true
	_release_active_inputs()
	await pause_screen.play_resume_cue()
	pause_screen.queue_free()
	pause_screen = null
	get_tree().paused = false
	var active_screen := scene_router.current_screen
	var restore_focus := _pop_focus()
	if active_screen != null and active_screen.has_method("restore_focus"):
		active_screen.call("restore_focus", restore_focus)
	_is_resuming = false


func _return_to_title_from_pause() -> void:
	if has_open_modal_options():
		modal_options_screen.queue_free()
		modal_options_screen = null
	if has_open_pause():
		pause_screen.queue_free()
		pause_screen = null
	_release_active_inputs()
	get_tree().paused = false
	_is_resuming = false
	var focus_router := get_node_or_null("/root/FocusRouter")
	if focus_router != null:
		focus_router.clear()
	var kernel := get_node_or_null("/root/GameKernel")
	if kernel != null:
		kernel.clear_state()
	await _route_primary(&"title")


func _push_primary_focus() -> void:
	var focus_router := get_node_or_null("/root/FocusRouter")
	if focus_router != null:
		focus_router.push_prior_focus(scene_router.current_focus_id())


func _pop_focus() -> StringName:
	var focus_router := get_node_or_null("/root/FocusRouter")
	return focus_router.pop_prior_focus() if focus_router != null else &""


func _release_active_inputs() -> void:
	for action: StringName in GameInput.ALL_ACTIONS:
		Input.action_release(action)


func _resolve_input_candidates(candidates: Array[StringName]) -> StringName:
	if modal_options_screen != null and is_instance_valid(modal_options_screen):
		return _resolve_ui_candidates(candidates)
	if pause_screen != null and is_instance_valid(pause_screen):
		return _resolve_ui_candidates(candidates)
	var active_screen := scene_router.current_screen
	if active_screen != null and active_screen.has_method("resolve_input_candidates"):
		return StringName(active_screen.call("resolve_input_candidates", candidates))
	if scene_router.current_screen_id in [&"foundation_mode", &"vertical_slice"] and GameInput.PAUSE in candidates:
		return GameInput.PAUSE
	return _resolve_ui_candidates(candidates)


func _resolve_ui_candidates(candidates: Array[StringName]) -> StringName:
	return GameInput.first_matching(candidates, [
		GameInput.MOVE_UP,
		GameInput.MOVE_DOWN,
		GameInput.MOVE_LEFT,
		GameInput.MOVE_RIGHT,
		GameInput.CONFIRM,
		GameInput.CANCEL,
		GameInput.PAGE_LEFT,
		GameInput.PAGE_RIGHT,
		GameInput.PAUSE,
		GameInput.MENU,
	])
