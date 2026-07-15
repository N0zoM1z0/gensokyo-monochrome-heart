class_name FighterProjectilePool
extends RefCounted
## Fixed SoA projectile storage capped at exactly 64 entries per fighter.

const SIDES := 2

var per_fighter_capacity: int
var capacity: int
var used := PackedByteArray()
var owner_side := PackedByteArray()
var x_fp := PackedInt32Array()
var y_fp := PackedInt32Array()
var velocity_x_fp := PackedInt32Array()
var damage := PackedInt32Array()
var guard_damage := PackedInt32Array()
var hitstun_ticks := PackedInt32Array()
var blockstun_ticks := PackedInt32Array()
var lifetime_ticks := PackedInt32Array()
var family := PackedStringArray()
var active_count: int = 0
var dropped_spawn_count: int = 0


func _init(p_per_fighter_capacity: int = 64) -> void:
	per_fighter_capacity = maxi(1, p_per_fighter_capacity)
	capacity = per_fighter_capacity * SIDES
	used.resize(capacity)
	owner_side.resize(capacity)
	x_fp.resize(capacity)
	y_fp.resize(capacity)
	velocity_x_fp.resize(capacity)
	damage.resize(capacity)
	guard_damage.resize(capacity)
	hitstun_ticks.resize(capacity)
	blockstun_ticks.resize(capacity)
	lifetime_ticks.resize(capacity)
	family.resize(capacity)
	clear(true)


func spawn(spec: FighterProjectileSpec) -> int:
	if spec == null or active_for_side(spec.owner_side) >= per_fighter_capacity:
		dropped_spawn_count += 1
		return -1
	for index: int in range(capacity):
		if used[index] != 0:
			continue
		used[index] = 1
		owner_side[index] = clampi(spec.owner_side, 0, 1)
		x_fp[index] = spec.x_fp
		y_fp[index] = spec.y_fp
		velocity_x_fp[index] = spec.velocity_x_fp
		damage[index] = spec.damage
		guard_damage[index] = spec.guard_damage
		hitstun_ticks[index] = spec.hitstun_ticks
		blockstun_ticks[index] = spec.blockstun_ticks
		lifetime_ticks[index] = spec.lifetime_ticks
		family[index] = String(spec.family)
		active_count += 1
		return index
	dropped_spawn_count += 1
	return -1


func step(left_bound_fp: int, right_bound_fp: int) -> void:
	for index: int in range(capacity):
		if used[index] == 0:
			continue
		x_fp[index] += velocity_x_fp[index]
		lifetime_ticks[index] -= 1
		if lifetime_ticks[index] <= 0 or x_fp[index] < left_bound_fp or x_fp[index] > right_bound_fp:
			retire(index)


func retire(index: int) -> void:
	if index < 0 or index >= capacity or used[index] == 0:
		return
	used[index] = 0
	family[index] = ""
	active_count -= 1


func clear(reset_drops: bool = false) -> void:
	used.fill(0)
	family.fill("")
	active_count = 0
	if reset_drops:
		dropped_spawn_count = 0


func active_for_side(side: int) -> int:
	var count := 0
	for index: int in range(capacity):
		if used[index] != 0 and owner_side[index] == side:
			count += 1
	return count


func canonical_snapshot() -> String:
	var entries := PackedStringArray()
	for index: int in range(capacity):
		if used[index] == 0:
			continue
		entries.append("%d:%d:%d:%d:%d:%d:%s" % [
			index, owner_side[index], x_fp[index], y_fp[index], velocity_x_fp[index],
			lifetime_ticks[index], family[index],
		])
	return "%d|%d|%s" % [active_count, dropped_spawn_count, ";".join(entries)]
