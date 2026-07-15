class_name TeaTemperatureState
extends RefCounted
## Integer-only Tea Temperature state suitable for deterministic replay fixtures.

enum Phase {
	TUTORIAL,
	ACTIVE,
	RESULT,
}

var phase: Phase = Phase.TUTORIAL
var kettle_heat: int = 400
var steep_ticks: int = 0
var cup_temperatures := PackedInt32Array([-1, -1])
var poured_cups: int = 0
var elapsed_ticks: int = 0
var remaining_ticks: int = 2700
var ticks_since_pour: int = 999
var steam_phase: int = 0
var result_tag: StringName


func canonical_snapshot() -> String:
	return "%d|%d|%d|%d,%d|%d|%d|%d|%d|%s" % [
		phase,
		kettle_heat,
		steep_ticks,
		cup_temperatures[0],
		cup_temperatures[1],
		poured_cups,
		elapsed_ticks,
		remaining_ticks,
		ticks_since_pour,
		result_tag,
	]
