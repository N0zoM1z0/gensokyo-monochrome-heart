class_name BroomBackseatState
extends RefCounted
## Integer-only cargo position and landing evidence for Broom Backseat.

enum Phase { TUTORIAL, ACTIVE, RESULT }

var phase: Phase = Phase.TUTORIAL
var cargo_lane: int = 0
var checkpoint_index: int = 0
var safe_landings: int = 0
var rough_landings: int = 0
var last_landing: StringName
var elapsed_ticks: int = 0
var result_tag: StringName


func canonical_snapshot() -> String:
	return "|".join(PackedStringArray([
		str(phase), str(cargo_lane), str(checkpoint_index), str(safe_landings),
		str(rough_landings), String(last_landing), str(elapsed_ticks), String(result_tag),
	]))
