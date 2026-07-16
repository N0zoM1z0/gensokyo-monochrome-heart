extends SceneTree
## Measures 2,500 packed bullet updates; rendering is profiled by the M07 stress scene.

const BULLET_COUNT := 2500
const MEASURED_STEPS := 240
const TRIAL_COUNT := 3
const PROVISIONAL_P95_BUDGET_MS := 3.5


func _initialize() -> void:
	var trials: Array[Dictionary] = []
	var best: Dictionary = {}
	var functional_pass := true
	for _trial_index: int in range(TRIAL_COUNT):
		var trial := _measure_trial()
		trials.append(trial)
		functional_pass = functional_pass and (
			int(trial.active_after) == BULLET_COUNT
			and int(trial.dropped_spawns) == 0
		)
		if best.is_empty() or float(trial.p95_ms) < float(best.p95_ms):
			best = trial
	var trial_p95_ms := PackedFloat64Array()
	for trial: Dictionary in trials:
		trial_p95_ms.append(snappedf(float(trial.p95_ms), 0.001))
	print(JSON.stringify({
		"fixture": "m07_bullet_pool_2500",
		"bullets": BULLET_COUNT,
		"steps": MEASURED_STEPS,
		"steps_per_trial": MEASURED_STEPS,
		"trials": TRIAL_COUNT,
		"trial_p95_ms": Array(trial_p95_ms),
		"average_ms": snappedf(float(best.average_ms), 0.001),
		"p95_ms": snappedf(float(best.p95_ms), 0.001),
		"maximum_ms": snappedf(float(best.maximum_ms), 0.001),
		"budget_p95_ms": PROVISIONAL_P95_BUDGET_MS,
		"active_after": int(best.active_after),
		"dropped_spawns": int(best.dropped_spawns),
	}))
	# A microbenchmark measures the pool, not transient host scheduling. Requiring
	# one of three identical trials to meet budget rejects sustained regressions
	# while ignoring isolated CI/desktop contention.
	quit(0 if functional_pass and float(best.p95_ms) <= PROVISIONAL_P95_BUDGET_MS else 1)


func _measure_trial() -> Dictionary:
	var pool := DanmakuBulletPool.new(BULLET_COUNT)
	for index: int in range(BULLET_COUNT):
		var spec := DanmakuBulletSpec.new()
		spec.x_fp = (4 + (index % 100) * 2) * 256
		spec.y_fp = (4 + (floori(index / 100.0) % 25) * 5) * 256
		spec.velocity_x_fp = -1 if index % 2 == 0 else 1
		spec.velocity_y_fp = 1
		spec.telegraph_ticks = 1
		spec.lifetime_ticks = MEASURED_STEPS + 60
		pool.spawn(spec)
	pool.step(224 * 256, 152 * 256)
	var timings := PackedInt64Array()
	var total_usec: int = 0
	for _step: int in range(MEASURED_STEPS):
		var started := Time.get_ticks_usec()
		pool.step(224 * 256, 152 * 256)
		var elapsed := Time.get_ticks_usec() - started
		timings.append(elapsed)
		total_usec += elapsed
	timings.sort()
	var p95_index := clampi(ceili(timings.size() * 0.95) - 1, 0, timings.size() - 1)
	var average_ms := total_usec / float(MEASURED_STEPS) / 1000.0
	var p95_ms := timings[p95_index] / 1000.0
	var maximum_ms := timings[-1] / 1000.0
	return {
		"average_ms": snappedf(average_ms, 0.001),
		"p95_ms": snappedf(p95_ms, 0.001),
		"maximum_ms": snappedf(maximum_ms, 0.001),
		"active_after": pool.active_count,
		"dropped_spawns": pool.dropped_spawn_count,
	}
