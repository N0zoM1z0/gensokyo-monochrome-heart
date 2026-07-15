class_name SceneRouter
extends Node
## Loads a primary screen or mode off-screen, then swaps it on a transition boundary.

signal route_started(request: ScreenRouteRequest)
signal route_completed(result: ScreenRouteResult)
signal route_failed(result: ScreenRouteResult)

@export var screen_host_path: NodePath
@export var mode_host_path: NodePath
@export var transition_controller_path: NodePath

var current_screen: Node
var current_screen_id: StringName = &""
var is_routing: bool = false
var _loader_thread: Thread

@onready var screen_host: Node = get_node(screen_host_path)
@onready var mode_host: Node = get_node(mode_host_path)
@onready var transition_controller: TransitionController = get_node(transition_controller_path)


func route_to(request: ScreenRouteRequest) -> ScreenRouteResult:
	if is_routing:
		return _fail(
			ScreenRouteResult.Code.BUSY,
			request.screen_id,
			"A primary route is already in progress."
		)
	if not UiScreenRegistry.has_route(request.screen_id):
		return _fail(
			ScreenRouteResult.Code.UNKNOWN_ROUTE,
			request.screen_id,
			"Unknown route ID: %s" % request.screen_id
		)
	var host_id := UiScreenRegistry.host_id(request.screen_id)
	var host := _host_for(host_id)
	if host == null:
		return _fail(
			ScreenRouteResult.Code.HOST_MISSING,
			request.screen_id,
			"Persistent host is unavailable for route: %s" % request.screen_id
		)
	is_routing = true
	route_started.emit(request)
	var path := UiScreenRegistry.scene_path(request.screen_id)
	_loader_thread = Thread.new()
	var request_error := _loader_thread.start(_load_scene_on_thread.bind(path))
	if request_error != OK:
		_loader_thread = null
		is_routing = false
		return _fail(
			ScreenRouteResult.Code.LOAD_REQUEST_FAILED,
			request.screen_id,
			"Could not request route resource %s (error %d)." % [path, request_error]
		)
	while _loader_thread.is_alive():
		await get_tree().process_frame
	var packed_scene := _loader_thread.wait_to_finish() as PackedScene
	_loader_thread = null
	if packed_scene == null:
		is_routing = false
		return _fail(
			ScreenRouteResult.Code.LOAD_FAILED,
			request.screen_id,
			"Could not load route resource: %s" % path
		)
	var next_screen := packed_scene.instantiate()
	if next_screen == null:
		is_routing = false
		return _fail(
			ScreenRouteResult.Code.INSTANTIATION_FAILED,
			request.screen_id,
			"Could not instantiate route resource: %s" % path
		)
	next_screen.process_mode = (
		Node.PROCESS_MODE_ALWAYS
		if host_id == UiScreenRegistry.SCREEN_HOST
		else Node.PROCESS_MODE_PAUSABLE
	)
	next_screen.visible = false
	host.add_child(next_screen)
	if next_screen.has_method("configure_route"):
		next_screen.call("configure_route", request)
	var settings := get_node_or_null("/root/SettingsService")
	var reduced_motion: bool = settings.is_reduced_motion if settings != null else false
	var theme_registry := get_node_or_null("/root/UiThemeRegistry")
	var profile_id: StringName = theme_registry.effective_profile_id() if theme_registry != null else &"A"
	await transition_controller.cover(reduced_motion, profile_id)
	var prior_screen := current_screen
	current_screen = next_screen
	current_screen_id = request.screen_id
	next_screen.visible = true
	if prior_screen != null and is_instance_valid(prior_screen):
		prior_screen.queue_free()
	if request.restore_focus_id != &"" and next_screen.has_method("restore_focus"):
		next_screen.call("restore_focus", request.restore_focus_id)
	await transition_controller.reveal(reduced_motion, profile_id)
	is_routing = false
	var result := ScreenRouteResult.success(request.screen_id, next_screen)
	route_completed.emit(result)
	return result


func current_focus_id() -> StringName:
	if current_screen != null and current_screen.has_method("current_focus_id"):
		return current_screen.call("current_focus_id")
	return &""


func _exit_tree() -> void:
	if _loader_thread != null and _loader_thread.is_started():
		_loader_thread.wait_to_finish()
	_loader_thread = null


func _load_scene_on_thread(path: String) -> PackedScene:
	return ResourceLoader.load(path, "PackedScene") as PackedScene


func _host_for(host_id: StringName) -> Node:
	return mode_host if host_id == UiScreenRegistry.MODE_HOST else screen_host


func _fail(
	code: ScreenRouteResult.Code,
	screen_id: StringName,
	diagnostic: String
) -> ScreenRouteResult:
	var result := ScreenRouteResult.failure(code, screen_id, diagnostic)
	route_failed.emit(result)
	return result
