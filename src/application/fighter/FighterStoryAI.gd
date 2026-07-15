class_name FighterStoryAI
extends RefCounted
## Authored deterministic behavior bands with enforced recovery/escape windows.

const BANDS := [&"gentle", &"story", &"assertive"]

var band: StringName = &"story"
var side: int = 1
var decision_tick: int = 0
var offense_streak: int = 0
var deterministic_seed: int = 1


func configure(p_band: StringName, p_side: int, seed: int) -> bool:
	if p_band not in BANDS or p_side not in [0, 1]:
		return false
	band = p_band
	side = p_side
	deterministic_seed = maxi(1, seed)
	decision_tick = 0
	offense_streak = 0
	return true


func next_input(simulation: FighterDuelSimulation) -> FighterInputFrame:
	var frame := FighterInputFrame.new()
	if simulation == null or simulation.final_result != null:
		return frame
	decision_tick += 1
	var self_state := simulation.states[side]
	var target := simulation.states[1 - side]
	if self_state.hitstun_ticks > 0 or self_state.blockstun_ticks > 0:
		return frame
	var delta_fp := target.x_fp - self_state.x_fp
	var toward := 1 if delta_fp > 0 else -1
	var distance := absi(delta_fp) / FighterDuelSimulation.FP
	var attack_interval := 74 if band == &"gentle" else (56 if band == &"story" else 42)
	var recovery_window := 28 if band == &"gentle" else 20
	if offense_streak >= 2:
		frame.horizontal_axis = -toward
		frame.guard_held = decision_tick % 3 != 0
		if decision_tick % recovery_window == 0:
			offense_streak = 0
		return frame
	if distance > 54:
		frame.horizontal_axis = toward
		if decision_tick % (attack_interval + 17) == 0:
			frame.skill_pressed = true
			offense_streak += 1
		return frame
	if decision_tick % attack_interval == 0:
		var selector := posmod(deterministic_seed + decision_tick / attack_interval, 3)
		frame.light_pressed = selector == 0
		frame.heavy_pressed = selector == 1
		frame.skill_pressed = selector == 2
		offense_streak += 1
	elif decision_tick % 19 < 5:
		frame.guard_held = true
	else:
		frame.horizontal_axis = -toward if distance < 28 else toward
	return frame
