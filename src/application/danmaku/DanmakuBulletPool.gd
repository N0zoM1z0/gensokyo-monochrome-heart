class_name DanmakuBulletPool
extends RefCounted
## Fixed-capacity packed bullet storage. No active bullet is represented by a Node.

enum Lifecycle {
	TELEGRAPH,
	COMMITTED,
	DISSOLVE,
}

const DISSOLVE_TICKS := 8
const PAD_FP := 12 * 256

var capacity: int
var used := PackedByteArray()
var lifecycle := PackedByteArray()
var x_fp := PackedInt32Array()
var y_fp := PackedInt32Array()
var velocity_x_fp := PackedInt32Array()
var velocity_y_fp := PackedInt32Array()
var radius_fp := PackedInt32Array()
var telegraph_ticks := PackedInt32Array()
var was_telegraphed := PackedByteArray()
var age_ticks := PackedInt32Array()
var lifetime_ticks := PackedInt32Array()
var family := PackedByteArray()
var polarity := PackedByteArray()
var emitter_index := PackedInt32Array()
var phase_index := PackedInt32Array()
var grazed := PackedByteArray()
var dissolve_ticks := PackedByteArray()

var active_count: int = 0
var committed_count: int = 0
var dropped_spawn_count: int = 0
var total_spawned: int = 0
var total_committed: int = 0
var untelegraphed_commit_count: int = 0
var _free_indices: Array[int] = []


func _init(p_capacity: int = 512) -> void:
	capacity = maxi(1, p_capacity)
	used.resize(capacity)
	lifecycle.resize(capacity)
	x_fp.resize(capacity)
	y_fp.resize(capacity)
	velocity_x_fp.resize(capacity)
	velocity_y_fp.resize(capacity)
	radius_fp.resize(capacity)
	telegraph_ticks.resize(capacity)
	was_telegraphed.resize(capacity)
	age_ticks.resize(capacity)
	lifetime_ticks.resize(capacity)
	family.resize(capacity)
	polarity.resize(capacity)
	emitter_index.resize(capacity)
	phase_index.resize(capacity)
	grazed.resize(capacity)
	dissolve_ticks.resize(capacity)
	_rebuild_free_list()


func spawn(spec: DanmakuBulletSpec) -> int:
	if spec == null or _free_indices.is_empty():
		dropped_spawn_count += 1
		return -1
	var index: int = _free_indices.pop_back()
	used[index] = 1
	lifecycle[index] = Lifecycle.TELEGRAPH
	x_fp[index] = spec.x_fp
	y_fp[index] = spec.y_fp
	velocity_x_fp[index] = spec.velocity_x_fp
	velocity_y_fp[index] = spec.velocity_y_fp
	radius_fp[index] = maxi(1, spec.radius_fp)
	telegraph_ticks[index] = maxi(0, spec.telegraph_ticks)
	was_telegraphed[index] = int(spec.telegraph_ticks > 0)
	age_ticks[index] = 0
	lifetime_ticks[index] = maxi(1, spec.lifetime_ticks)
	family[index] = spec.family
	polarity[index] = spec.polarity
	emitter_index[index] = spec.emitter_index
	phase_index[index] = spec.phase_index
	grazed[index] = 0
	dissolve_ticks[index] = 0
	active_count += 1
	total_spawned += 1
	return index


func step(arena_width_fp: int, arena_height_fp: int) -> void:
	if active_count <= 0:
		return
	var maximum_x := arena_width_fp + PAD_FP
	var maximum_y := arena_height_fp + PAD_FP
	for index: int in range(capacity):
		if used[index] == 0:
			continue
		var current_lifecycle: int = lifecycle[index]
		match current_lifecycle:
			Lifecycle.TELEGRAPH:
				var warning_ticks: int = telegraph_ticks[index]
				if warning_ticks > 0:
					warning_ticks -= 1
					telegraph_ticks[index] = warning_ticks
				if warning_ticks <= 0:
					lifecycle[index] = Lifecycle.COMMITTED
					committed_count += 1
					total_committed += 1
					if was_telegraphed[index] == 0:
						# A zero authored telegraph commits on its first pool step.
						untelegraphed_commit_count += 1
			Lifecycle.COMMITTED:
				var next_x: int = x_fp[index] + velocity_x_fp[index]
				var next_y: int = y_fp[index] + velocity_y_fp[index]
				var next_age: int = age_ticks[index] + 1
				x_fp[index] = next_x
				y_fp[index] = next_y
				age_ticks[index] = next_age
				if (
					next_x < -PAD_FP
					or next_x > maximum_x
					or next_y < -PAD_FP
					or next_y > maximum_y
					or next_age >= lifetime_ticks[index]
				):
					begin_dissolve(index)
			Lifecycle.DISSOLVE:
				var remaining: int = dissolve_ticks[index]
				if remaining > 0:
					remaining -= 1
					dissolve_ticks[index] = remaining
				if remaining <= 0:
					retire(index)


func begin_dissolve(index: int) -> void:
	if index < 0 or index >= capacity or used[index] == 0 or lifecycle[index] == Lifecycle.DISSOLVE:
		return
	if lifecycle[index] == Lifecycle.COMMITTED:
		committed_count = maxi(0, committed_count - 1)
	lifecycle[index] = Lifecycle.DISSOLVE
	dissolve_ticks[index] = DISSOLVE_TICKS


func dissolve_all_committed() -> void:
	for index: int in range(capacity):
		if used[index] != 0 and lifecycle[index] == Lifecycle.COMMITTED:
			begin_dissolve(index)


func retire(index: int) -> void:
	if index < 0 or index >= capacity or used[index] == 0:
		return
	if lifecycle[index] == Lifecycle.COMMITTED:
		committed_count = maxi(0, committed_count - 1)
	used[index] = 0
	active_count = maxi(0, active_count - 1)
	_free_indices.append(index)


func clear(reset_statistics: bool = false) -> void:
	used.fill(0)
	lifecycle.fill(0)
	active_count = 0
	committed_count = 0
	_rebuild_free_list()
	if reset_statistics:
		dropped_spawn_count = 0
		total_spawned = 0
		total_committed = 0
		untelegraphed_commit_count = 0


func canonical_snapshot() -> String:
	var rows := PackedStringArray()
	for index: int in range(capacity):
		if used[index] == 0:
			continue
		rows.append("%d,%d,%d,%d,%d,%d,%d,%d,%d" % [
			index,
			lifecycle[index],
			x_fp[index],
			y_fp[index],
			velocity_x_fp[index],
			velocity_y_fp[index],
			family[index],
			polarity[index],
			int(grazed[index]),
		])
	return ";".join(rows)


func _rebuild_free_list() -> void:
	_free_indices.clear()
	for index: int in range(capacity - 1, -1, -1):
		_free_indices.append(index)
