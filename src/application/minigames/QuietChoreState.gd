class_name QuietChoreState
extends RefCounted
## Integer-only evidence for the no-slot shrine routine.

enum Phase { TUTORIAL, SWEEP, MEND, SIT, RESULT }

var phase: Phase = Phase.TUTORIAL
var sweep_strokes: int = 0
var last_sweep_direction: int = 0
var mended_seams: int = 0
var silence_ticks: int = 0
var interruptions: int = 0
var elapsed_ticks: int = 0
var result_tag: StringName


func canonical_snapshot() -> String:
	return "|".join(PackedStringArray([
		str(phase), str(sweep_strokes), str(last_sweep_direction), str(mended_seams),
		str(silence_ticks), str(interruptions), str(elapsed_ticks), String(result_tag),
	]))
