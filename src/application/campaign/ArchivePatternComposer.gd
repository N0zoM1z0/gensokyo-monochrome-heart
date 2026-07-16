class_name ArchivePatternComposer
extends RefCounted
## Adapts one reviewed finale pattern from persisted, locale-free strategy evidence.

const FALLBACK_STRATEGY: StringName = &"strategy.unrecorded_gap"
const TEACHING_KEYS := {
	&"strategy.photo_frame": &"ui.archive.teach.photo_frame",
	&"strategy.margin_corridor": &"ui.archive.teach.margin_corridor",
	&"strategy.focus_lane": &"ui.archive.teach.focus_lane",
	&"strategy.neutral_guard": &"ui.archive.teach.neutral_guard",
}


static func strategies_for_state(state: GameState) -> Array[StringName]:
	var ranked := RecordedStrategyLedger.ranked_tags(state)
	if ranked.is_empty():
		ranked.append(FALLBACK_STRATEGY)
	return ranked


static func teaching_key(strategy_tag: StringName) -> StringName:
	return TEACHING_KEYS.get(strategy_tag, &"ui.archive.teach.unrecorded_gap")


static func compose(
	definition: DanmakuPatternDefinition,
	strategy_tags: Array[StringName]
) -> DanmakuPatternDefinition:
	if definition == null or definition.phases.size() != 3:
		return definition
	var primary := strategy_tags[0] if not strategy_tags.is_empty() else FALLBACK_STRATEGY
	var secondary := strategy_tags[1] if strategy_tags.size() > 1 else primary
	var familiar_lane := _lane_for(primary)
	var shifted_lane := _shifted_lane(familiar_lane, _lane_for(secondary))
	_set_phase_lane(definition.phases[0], familiar_lane)
	_set_phase_lane(definition.phases[1], shifted_lane)
	_set_phase_lane(definition.phases[2], shifted_lane)
	return definition


static func _set_phase_lane(phase: DanmakuPhaseDefinition, safe_lane: int) -> void:
	phase.safe_lane = safe_lane
	for emitter: DanmakuEmitterDefinition in phase.emitters:
		if emitter.pattern_type in [&"safe_lane_grid", &"knife_lattice"]:
			emitter.safe_lane = clampi(safe_lane, 0, emitter.slot_count - 1)


static func _lane_for(strategy_tag: StringName) -> int:
	match strategy_tag:
		&"strategy.photo_frame":
			return 4
		&"strategy.margin_corridor":
			return 6
		&"strategy.focus_lane":
			return 2
		&"strategy.neutral_guard":
			return 7
		_:
			return 5


static func _shifted_lane(primary_lane: int, secondary_lane: int) -> int:
	if secondary_lane != primary_lane:
		return secondary_lane
	return primary_lane + (1 if primary_lane < 8 else -1)
