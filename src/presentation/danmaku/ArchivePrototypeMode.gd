class_name ArchivePrototypeMode
extends BoundaryStainMode
## Standalone finale prototype that consumes the active profile's strategy ledger.

const REMOVAL_NOTICE_TICKS := 60

@export var fixture_strategy_tags: Array[StringName] = []
@export var archive_fixture_after_removal: bool = false

var _indexed_strategy_tags: Array[StringName] = []


func _ready() -> void:
	_indexed_strategy_tags = fixture_strategy_tags.duplicate()
	if _indexed_strategy_tags.is_empty():
		var kernel := get_node_or_null("/root/GameKernel")
		var snapshot: Variant = kernel.call("state_snapshot") if kernel != null else null
		if snapshot is GameState:
			_indexed_strategy_tags = ArchivePatternComposer.strategies_for_state(snapshot)
	if _indexed_strategy_tags.is_empty():
		_indexed_strategy_tags.append(ArchivePatternComposer.FALLBACK_STRATEGY)
	teaching_keys = [
		ArchivePatternComposer.teaching_key(_indexed_strategy_tags[0]),
		&"ui.archive.teach.composite_shift",
		&"ui.archive.teach.margin_error",
	]
	super._ready()
	_apply_archive_fixture_post_state()


func configure_fixture(
	requested_profile: StringName,
	locale: StringName,
	forced_profile: StringName = &"",
	is_reduced_motion: bool = false,
	is_safe_flash: bool = false
) -> void:
	super.configure_fixture(requested_profile, locale, forced_profile, is_reduced_motion, is_safe_flash)
	_apply_archive_fixture_post_state()


func indexed_strategy_tags() -> Array[StringName]:
	return _indexed_strategy_tags.duplicate()


func _apply_archive_fixture_post_state() -> void:
	if runtime == null or runtime.state.phase_index != 2:
		return
	if archive_fixture_after_removal:
		var phase := runtime.current_phase()
		step_fixture(
			maxi(0, phase.transform_tick - runtime.state.phase_tick + 36),
			_fixture_input(0, 0, false, false)
		)
		_visual_cue_seconds = 0.0
	_center_fixture_player_in_familiar_lane()


func _center_fixture_player_in_familiar_lane() -> void:
	if fixture_state != "phase3":
		return
	var phase := runtime.current_phase()
	for emitter: DanmakuEmitterDefinition in phase.emitters:
		if emitter.pattern_type in [&"safe_lane_grid", &"knife_lattice"] and emitter.slot_count > 1:
			var lane_x := 8 + roundi(
				emitter.safe_lane * (definition.arena_width - 16) / float(emitter.slot_count - 1)
			)
			runtime.state.player_x_fp = lane_x * BoundaryStainSimulation.FP
			return


func _adapt_definition(source: DanmakuPatternDefinition) -> DanmakuPatternDefinition:
	return ArchivePatternComposer.compose(source, _indexed_strategy_tags)


func _draw_mode_overlay(foreground: Color, background: Color) -> void:
	if not _removal_notice_active():
		return
	var lane_x := _familiar_lane_display_x()
	# Broken rails preserve the player's learned reference while clearly cancelling it.
	for rail_x: float in [lane_x - 5.0, lane_x + 5.0]:
		for y: int in range(18, 139, 12):
			draw_line(Vector2(rail_x, y), Vector2(rail_x, y + 4), foreground, 1.0)
	draw_line(Vector2(lane_x - 12, 65), Vector2(lane_x + 13, 91), foreground, 2.0)
	draw_line(Vector2(lane_x + 12, 65), Vector2(lane_x - 13, 91), foreground, 2.0)
	var notice := Rect2(47, 37, 138, 18)
	draw_rect(notice, background)
	draw_rect(notice, foreground, false, 2.0)
	draw_string(
		_font(), Vector2(52, 51), _catalog.text(&"ui.archive.pattern_removed", _locale),
		HORIZONTAL_ALIGNMENT_CENTER, 128, _hud_font_size(), foreground
	)


func _removal_notice_active() -> bool:
	if not runtime is ArchiveAdaptiveSimulation:
		return false
	var phase := runtime.current_phase()
	return (
		(runtime as ArchiveAdaptiveSimulation).familiar_lane_removed()
		and runtime.state.phase_tick < phase.transform_tick + REMOVAL_NOTICE_TICKS
	)


func _familiar_lane_display_x() -> float:
	var phase := runtime.current_phase()
	for emitter: DanmakuEmitterDefinition in phase.emitters:
		if emitter.pattern_type in [&"safe_lane_grid", &"knife_lattice"] and emitter.slot_count > 1:
			return FIELD_ORIGIN.x + 8.0 + roundi(
				emitter.safe_lane * (definition.arena_width - 16) / float(emitter.slot_count - 1)
			)
	return FIELD_ORIGIN.x + definition.arena_width / 2.0


func capture_debug_state() -> Dictionary:
	var debug := super.capture_debug_state()
	var tags: Array[String] = []
	for tag: StringName in _indexed_strategy_tags:
		tags.append(String(tag))
	debug["indexed_strategy_tags"] = tags
	debug["familiar_lane_removed"] = (
		runtime is ArchiveAdaptiveSimulation
		and (runtime as ArchiveAdaptiveSimulation).familiar_lane_removed()
	)
	return debug
