class_name ArchiveAdaptiveSimulation
extends BoundaryStainSimulation
## Finale rule: a clearly previewed familiar lane is filled only after transform.


func safe_lane_preview() -> int:
	var phase := current_phase()
	if phase != null and state.phase_index == 2 and state.phase_tick >= phase.transform_tick:
		return -1
	return super.safe_lane_preview()


func familiar_lane_removed() -> bool:
	var phase := current_phase()
	return phase != null and state.phase_index == 2 and state.phase_tick >= phase.transform_tick


func _emit_volley(emitter: DanmakuEmitterDefinition, volley: int) -> void:
	if (
		state.phase_index != 2
		or state.phase_tick < current_phase().transform_tick
		or emitter.pattern_type not in [&"safe_lane_grid", &"knife_lattice"]
	):
		super._emit_volley(emitter, volley)
		return
	# The guide vanishes at transform_tick. Later volleys fill the old gap, but
	# their authored telegraph still precedes commitment by at least 24 ticks.
	var familiar_lane := emitter.safe_lane
	emitter.safe_lane = -1
	super._emit_volley(emitter, volley)
	emitter.safe_lane = familiar_lane


func _finish(result_tag: StringName) -> ModeResult:
	var is_new := final_result == null
	var result := super._finish(result_tag)
	if result != null and is_new:
		result.outcome_tags.append(&"archive.familiar_lane_removed")
	return result
