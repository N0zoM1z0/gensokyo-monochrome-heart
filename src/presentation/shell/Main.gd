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
	if action == GameInput.PAUSE and scene_router.current_screen_id == &"foundation_mode":
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


func _on_screen_command(command_id: StringName, payload: Dictionary) -> void:
	match command_id:
		&"new_profile":
			_push_primary_focus()
			_route_primary.call_deferred(&"profile_select")
		&"open_options":
			_push_primary_focus()
			_route_primary.call_deferred(
				&"options",
				{"origin": &"title"}
			)
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


func _route_after_profile(_payload: Dictionary) -> void:
	var accessibility := get_node_or_null("/root/AccessibilityState")
	if accessibility != null and accessibility.is_first_run:
		await _route_primary(&"accessibility")
	else:
		var focus_router := get_node_or_null("/root/FocusRouter")
		if focus_router != null:
			focus_router.clear()
		await _route_primary(&"foundation_mode")


func _apply_accessibility_and_enter_mode(payload: Dictionary) -> void:
	var accessibility := get_node_or_null("/root/AccessibilityState")
	if accessibility != null:
		accessibility.apply_named_preset(StringName(payload.get("preset_id", &"original")))
	var focus_router := get_node_or_null("/root/FocusRouter")
	if focus_router != null:
		focus_router.clear()
	await _route_primary(&"foundation_mode")


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
