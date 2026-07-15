class_name DanmakuState
extends RefCounted
## Integer-only encounter state; presentation reads it but never owns combat truth.

var phase_index: int = 0
var phase_tick: int = 0
var encounter_tick: int = 0
var player_x_fp: int = 112 * 256
var player_y_fp: int = 136 * 256
var focus_held: bool = false
var lives: int = 3
var bombs: int = 2
var margin: int = 0
var automatic_saves_remaining: int = 0
var boss_integrity: int = 0
var boss_integrity_max: int = 0
var invulnerability_ticks: int = 0
var graze_count: int = 0
var hit_count: int = 0
var bombs_used: int = 0
var automatic_bombs_used: int = 0
var margin_spent: int = 0
var score: int = 0
var inactive_margin_ticks: int = 0
var completed_phases: int = 0
var result_tag: StringName


func canonical_snapshot() -> String:
	return "%d|%d|%d|%d,%d|%d|%d|%d|%d|%d,%d|%d|%d|%d|%d|%d|%d|%d|%d|%s" % [
		phase_index,
		phase_tick,
		encounter_tick,
		player_x_fp,
		player_y_fp,
		int(focus_held),
		lives,
		bombs,
		margin,
		automatic_saves_remaining,
		boss_integrity,
		boss_integrity_max,
		invulnerability_ticks,
		graze_count,
		hit_count,
		bombs_used,
		automatic_bombs_used,
		margin_spent,
		score,
		result_tag,
	]


func duplicate_state() -> DanmakuState:
	var copy := DanmakuState.new()
	copy.phase_index = phase_index
	copy.phase_tick = phase_tick
	copy.encounter_tick = encounter_tick
	copy.player_x_fp = player_x_fp
	copy.player_y_fp = player_y_fp
	copy.focus_held = focus_held
	copy.lives = lives
	copy.bombs = bombs
	copy.margin = margin
	copy.automatic_saves_remaining = automatic_saves_remaining
	copy.boss_integrity = boss_integrity
	copy.boss_integrity_max = boss_integrity_max
	copy.invulnerability_ticks = invulnerability_ticks
	copy.graze_count = graze_count
	copy.hit_count = hit_count
	copy.bombs_used = bombs_used
	copy.automatic_bombs_used = automatic_bombs_used
	copy.margin_spent = margin_spent
	copy.score = score
	copy.inactive_margin_ticks = inactive_margin_ticks
	copy.completed_phases = completed_phases
	copy.result_tag = result_tag
	return copy
