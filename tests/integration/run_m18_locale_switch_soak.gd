extends SceneTree
## M18: repeatedly reflow live EN/JA presentation without changing campaign state.

const SLICE_SCENE := preload("res://src/presentation/slice/VerticalSliceMode.tscn")
const TOGGLES_PER_PHASE := 80
const STATIC_MEMORY_DRIFT_LIMIT_BYTES := 64 * 1024

var _failures: Array[String] = []
var _kernel: Node
var _slice: VerticalSliceMode
var _localization: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_kernel = root.get_node_or_null("GameKernel")
	_localization = root.get_node_or_null("LocalizationService")
	var accessibility := root.get_node_or_null("AccessibilityState")
	_expect(_kernel != null and _localization != null and accessibility != null, "required autoload is unavailable")
	if not _failures.is_empty():
		_finish()
		return
	_kernel.clear_state()
	accessibility.apply_preset(AccessibilityState.Preset.STORY, false)
	_localization.set_locale(&"en", false)
	var created: CommandResult = _kernel.create_new_profile(&"p180", &"accessibility.story")
	_expect(created.is_success(), "could not create locale-soak profile")
	await _spawn_slice()

	await _soak(&"invitation")
	_press(GameInput.CONFIRM)
	_press(GameInput.CONFIRM)
	_expect(_slice.phase_id() == &"exploration", "did not reach exploration")
	await _soak(&"exploration")

	_expect(_slice.complete_exploration_for_test(), "could not complete exploration")
	_press_until(&"mini.shrine.tea_temperature", "Tea Temperature")
	_expect(_slice.submit_mode_result_for_test(&"loss"), "could not leave Tea Temperature")
	_press_until(&"danmaku.hkr.boundary_stain", "Boundary Stain")
	await _soak(&"danmaku")
	_expect(_mode_locale() == &"en", "danmaku renderer did not receive the final locale")

	_expect(_slice.submit_mode_result_for_test(&"assist_clear"), "could not leave Boundary Stain")
	_press_until(&"duel.hkr.spell_card_terms", "compact duel")
	await _soak(&"fighter")
	_expect(_mode_locale() == &"en", "fighter renderer did not receive the final locale")

	_expect(_slice.submit_mode_result_for_test(&"loss"), "could not leave compact duel")
	_press_until(&"journal", "Journal")
	await _soak(&"journal")
	_expect(_slice.phase_id() == &"journal", "locale soak changed the Journal route")

	await _free_slice()
	_finish()


func _spawn_slice() -> void:
	_slice = SLICE_SCENE.instantiate() as VerticalSliceMode
	root.add_child(_slice)
	await process_frame
	_slice.set_instant_text_for_test(true)


func _free_slice() -> void:
	if _slice != null and is_instance_valid(_slice):
		_slice.free()
	_slice = null
	await process_frame
	await process_frame


func _soak(phase_label: String) -> void:
	if _slice == null:
		_failures.append("%s: slice is unavailable" % phase_label)
		return
	# Let both cached layouts materialize before measuring retained resources.
	for _toggle: int in range(4):
		_toggle_locale()
	await process_frame
	await process_frame
	var phase_before := _slice.phase_id()
	var canonical_before := GameStateCodec.new().canonical_state(_kernel.state_snapshot())
	var object_count_before := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var static_memory_before := OS.get_static_memory_usage()
	for _toggle: int in range(TOGGLES_PER_PHASE):
		_toggle_locale()
	await process_frame
	await process_frame
	_expect(_localization.locale == &"en", "%s: even toggle count did not return to English" % phase_label)
	_expect(_slice.phase_id() == phase_before, "%s: locale changes changed the active route" % phase_label)
	_expect(
		GameStateCodec.new().canonical_state(_kernel.state_snapshot()) == canonical_before,
		"%s: locale changes mutated campaign state" % phase_label
	)
	var object_drift := int(Performance.get_monitor(Performance.OBJECT_COUNT)) - object_count_before
	var static_memory_drift := OS.get_static_memory_usage() - static_memory_before
	_expect(object_drift <= 0, "%s: locale changes retained %d live objects" % [phase_label, object_drift])
	_expect(
		static_memory_drift <= STATIC_MEMORY_DRIFT_LIMIT_BYTES,
		"%s: locale changes retained %d bytes of static memory" % [phase_label, static_memory_drift]
	)


func _toggle_locale() -> void:
	_localization.set_locale(&"ja" if _localization.locale == &"en" else &"en", false)


func _mode_locale() -> StringName:
	var mode := _slice.active_child_mode()
	if mode == null:
		return &""
	var debug: Dictionary = mode.capture_debug_state()
	return StringName(String(debug.get("locale", "")))


func _press_until(target_phase: StringName, label: String) -> void:
	for _attempt: int in range(8):
		if _slice.phase_id() == target_phase:
			return
		_slice.arm_input_for_test()
		_press(GameInput.CONFIRM)
	_expect(_slice.phase_id() == target_phase, "did not reach %s" % label)


func _press(action: StringName) -> void:
	_slice.handle_semantic_action(action)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	print(
		"M18 locale switching soak: phases=5 toggles_per_phase=%d failures=%d"
		% [TOGGLES_PER_PHASE, _failures.size()]
	)
	for failure: String in _failures:
		printerr("FAIL: %s" % failure)
	quit(0 if _failures.is_empty() else 1)
