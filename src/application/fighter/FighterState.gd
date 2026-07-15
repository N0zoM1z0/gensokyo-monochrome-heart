class_name FighterState
extends RefCounted
## Canonical fixed-step state for one side of the compact duel.

const MAX_VITALITY := 1000
const MAX_TEMPERAMENT := 1000

var fighter_id: StringName
var side: int = 0
var x_fp: int = 0
var height_fp: int = 0
var velocity_x_fp: int = 0
var velocity_y_fp: int = 0
var facing: int = 1
var vitality: int = MAX_VITALITY
var vitality_notch: int = MAX_VITALITY
var temperament: int = 0
var breaks_won: int = 0
var current_move_id: StringName
var move_tick: int = 0
var active_hitbox: bool = false
var move_connected: bool = false
var guard_held: bool = false
var hitstun_ticks: int = 0
var blockstun_ticks: int = 0
var invulnerability_ticks: int = 0
var neutral_ticks: int = 0
var neutral_reset_armed: bool = false
var momentum_ticks: int = 0
var firepower_level: int = 0
var combo_hits_received: int = 0
var longest_lock_ticks: int = 0
var current_lock_ticks: int = 0
var last_hit_kind: StringName
var visual_pose: StringName = &"idle"


func is_grounded() -> bool:
	return height_fp <= 0


func origin(ground_y: int) -> Vector2i:
	return Vector2i(roundi(x_fp / 256.0), ground_y - roundi(height_fp / 256.0))


func duplicate_state() -> FighterState:
	var copy := FighterState.new()
	for property: Dictionary in get_property_list():
		var name := StringName(property.name)
		if name in [&"script", &"RefCounted"]:
			continue
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			copy.set(name, get(name))
	return copy


func canonical_snapshot() -> String:
	return "%s|%d|%d|%d|%d|%d|%d|%d|%d|%s|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%s|%s" % [
		fighter_id, side, x_fp, height_fp, velocity_x_fp, velocity_y_fp, facing,
		vitality, temperament, current_move_id, move_tick, int(active_hitbox),
		int(guard_held), hitstun_ticks, blockstun_ticks, invulnerability_ticks,
		neutral_ticks, int(neutral_reset_armed), momentum_ticks, firepower_level,
		breaks_won, last_hit_kind, visual_pose,
	]
