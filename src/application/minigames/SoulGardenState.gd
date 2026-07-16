class_name SoulGardenState
extends RefCounted
## Integer-only orchard state suitable for deterministic replay evidence.

enum Phase { TUTORIAL, ACTIVE, RESULT }

var phase: Phase = Phase.TUTORIAL
var cursor_column: int = 2
var spirit_columns: Array[int] = [4, 0, 2]
var released: Array[bool] = [false, false, false]
var carried_spirit: int = -1
var released_count: int = 0
var mismatch_count: int = 0
var elapsed_ticks: int = 0
var result_tag: StringName


func canonical_snapshot() -> String:
	var released_bits := PackedStringArray()
	var column_values := PackedStringArray()
	for value: bool in released:
		released_bits.append(str(int(value)))
	for value: int in spirit_columns:
		column_values.append(str(value))
	return "|".join(PackedStringArray([
		str(phase), str(cursor_column), ",".join(column_values),
		",".join(released_bits), str(carried_spirit), str(released_count), str(mismatch_count),
		str(elapsed_ticks), String(result_tag),
	]))
