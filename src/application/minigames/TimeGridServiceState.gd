class_name TimeGridServiceState
extends RefCounted
## Integer-only queue, clock, and scoring state for replay/save evidence.

enum Phase { TUTORIAL, ACTIVE, RESULT }

var phase: Phase = Phase.TUTORIAL
var cursor := Vector2i(1, 1)
var service_tick: int = 0
var elapsed_ticks: int = 0
var remaining_ticks: int = 2700
var stop_stock: int = 300
var time_stopped: bool = false
var stop_ticks_used: int = 0
var task_index: int = 0
var queued_station: int = -1
var completed_tasks: int = 0
var missed_tasks: int = 0
var total_timing_error: int = 0
var result_tag: StringName


func canonical_snapshot() -> String:
	return "|".join(PackedStringArray([
		str(phase), "%d,%d" % [cursor.x, cursor.y], str(service_tick), str(elapsed_ticks),
		str(remaining_ticks), str(stop_stock), str(int(time_stopped)), str(stop_ticks_used),
		str(task_index), str(queued_station), str(completed_tasks), str(missed_tasks),
		str(total_timing_error), String(result_tag),
	]))
