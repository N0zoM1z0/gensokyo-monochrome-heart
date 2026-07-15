class_name TestNavigationFoundation
extends RefCounted

const ROUTE_IDS: Array[StringName] = [
	&"title",
	&"profile_select",
	&"accessibility",
	&"options",
	&"credits",
	&"foundation_mode",
	&"vertical_slice",
]


func run() -> Array[String]:
	var failures: Array[String] = []
	_validate_route_registry(failures)
	_validate_persistent_shell(failures)
	_validate_transition_variants(failures)
	_validate_credits_contract(failures)
	_validate_screen_text_boundary(failures)
	return failures


func _validate_route_registry(failures: Array[String]) -> void:
	for route_id: StringName in ROUTE_IDS:
		if not UiScreenRegistry.has_route(route_id):
			failures.append("navigation registry lacks route: %s" % route_id)
			continue
		var path := UiScreenRegistry.scene_path(route_id)
		if not ResourceLoader.exists(path, "PackedScene"):
			failures.append("route %s does not resolve to a PackedScene: %s" % [route_id, path])
		if UiScreenRegistry.host_id(route_id) not in [UiScreenRegistry.SCREEN_HOST, UiScreenRegistry.MODE_HOST]:
			failures.append("route %s has an unsupported persistent host" % route_id)
	if UiScreenRegistry.has_route(&"unknown"):
		failures.append("unknown route was accepted by the registry")


func _validate_persistent_shell(failures: Array[String]) -> void:
	var packed_scene := load("res://src/presentation/shell/Main.tscn") as PackedScene
	if packed_scene == null:
		failures.append("persistent Main shell could not be loaded")
		return
	var shell := packed_scene.instantiate()
	var required_paths := [
		"FixedResolutionRoot/GameViewport/ModeHost",
		"FixedResolutionRoot/GameViewport/WorldCanvas/RootScreenHost",
		"FixedResolutionRoot/GameViewport/HUDCanvas/HUDHost",
		"FixedResolutionRoot/GameViewport/ModalCanvas/ModalHost",
		"FixedResolutionRoot/GameViewport/TransitionCanvas/TransitionController",
		"FixedResolutionRoot/GameViewport/OneBitCanvas/OneBitThreshold",
		"InputRouter",
		"AudioRoot",
	]
	for path: String in required_paths:
		if shell.get_node_or_null(path) == null:
			failures.append("persistent Main shell lacks node: %s" % path)
	var viewport := shell.get_node("FixedResolutionRoot/GameViewport") as SubViewport
	if viewport.size != Vector2i(320, 180):
		failures.append("GameViewport is not fixed at 320x180")
	shell.free()


func _validate_transition_variants(failures: Array[String]) -> void:
	var controller := TransitionController.new()
	if controller.style_for_reduced_motion(false) != TransitionOverlay.STYLE_PAPER_FOLD:
		failures.append("standard transition did not select paper fold")
	if controller.style_for_reduced_motion(true) != TransitionOverlay.STYLE_BORDER_TICK:
		failures.append("Low Motion did not replace paper fold with border tick")
	if (
		TransitionController.STANDARD_HALF_FRAMES * 2 != 6
		or TransitionController.REDUCED_COVER_FRAMES + TransitionController.REDUCED_REVEAL_FRAMES != 3
	):
		failures.append("transition frame budgets do not match the reviewed 6/3 frame contract")
	controller.free()


func _validate_credits_contract(failures: Array[String]) -> void:
	if CreditsScreen.DEFAULT_SCROLL_SPEED > 24.0 or CreditsScreen.DEFAULT_SCROLL_SPEED <= 0.0:
		failures.append("Credits default scroll speed exceeds the reviewed readability budget")
	if CreditsScreen.CREDIT_KEYS.size() < 7:
		failures.append("Credits omitted legal, engine, font, audio, or asset provenance")
	if CreditsScreen.CREDIT_MAX_LINES_PER_ENTRY < 2:
		failures.append("Credits do not reserve wrapping space for long EN/JA provenance lines")


func _validate_screen_text_boundary(failures: Array[String]) -> void:
	var paths := [
		"res://ui/screens/TitleScreen.gd",
		"res://ui/screens/ProfileSelectScreen.gd",
		"res://ui/screens/AccessibilityScreen.gd",
		"res://ui/screens/OptionsScreen.gd",
		"res://ui/screens/PauseScreen.gd",
		"res://ui/screens/CreditsScreen.gd",
		"res://src/presentation/modes/FoundationMode.gd",
		"res://src/presentation/slice/VerticalSliceMode.gd",
	]
	var visible_literal := RegEx.create_from_string("draw_(?:string|multiline_string)\\([^\\n]*\\\"[A-Za-z]")
	for path: String in paths:
		var source := FileAccess.get_file_as_string(path)
		if source.is_empty():
			failures.append("could not inspect M01 display-text boundary: %s" % path)
		elif visible_literal.search(source) != null:
			failures.append("M01 screen contains visible display text outside localization keys: %s" % path)
