class_name DanmakuEmitterDefinition
extends RefCounted
## Audited data-only emitter; pattern behavior is selected from a closed vocabulary.

const PATTERN_TYPES := [&"lane_fan", &"offering_ring", &"safe_lane_grid"]

var id: StringName
var pattern_type: StringName
var start_tick: int = 0
var interval_ticks: int = 60
var volleys: int = 1
var slot_count: int = 1
var origin_x: int = 112
var origin_y: int = 16
var speed_fp: int = 256
var angle_millidegrees: int = 90000
var telegraph_ticks: int = 18
var lifetime_ticks: int = 600
var family: DanmakuBulletSpec.Family = DanmakuBulletSpec.Family.AMULET
var polarity: DanmakuBulletSpec.Polarity = DanmakuBulletSpec.Polarity.INK
var safe_lane: int = -1


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if not String(id).begins_with("emit."):
		errors.append("emitter ID must begin with emit.: %s" % id)
	if pattern_type not in PATTERN_TYPES:
		errors.append("unsupported danmaku pattern component: %s" % pattern_type)
	if start_tick < 0 or interval_ticks <= 0 or volleys <= 0 or slot_count <= 0:
		errors.append("emitter timing and slot counts must be positive: %s" % id)
	if speed_fp <= 0 or telegraph_ticks <= 0 or lifetime_ticks <= 0:
		errors.append("emitter speed, telegraph, and lifetime must be positive: %s" % id)
	if pattern_type == &"safe_lane_grid" and (safe_lane < 0 or safe_lane >= slot_count):
		errors.append("safe-lane emitter requires a lane inside its slot range: %s" % id)
	return errors


func selected_slots(density_percent: int) -> PackedInt32Array:
	var accepted_density := density_percent if density_percent in DanmakuAssistSettings.DENSITY_TIERS else 100
	var target_count := maxi(1, roundi(slot_count * accepted_density / 100.0))
	var result := PackedInt32Array()
	if target_count == 1:
		result.append(floori(slot_count / 2.0))
		return result
	var seen := {}
	for output_index: int in range(target_count):
		var slot := roundi(output_index * (slot_count - 1) / float(target_count - 1))
		if not seen.has(slot):
			seen[slot] = true
			result.append(slot)
	return result
