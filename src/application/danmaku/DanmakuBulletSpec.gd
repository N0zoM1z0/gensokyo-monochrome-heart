class_name DanmakuBulletSpec
extends RefCounted
## Allocation-free spawn payload copied into the packed bullet pool.

enum Family {
	AMULET,
	OFFERING,
	MEMORY,
}

enum Polarity {
	INK,
	PAPER,
}

var x_fp: int = 0
var y_fp: int = 0
var velocity_x_fp: int = 0
var velocity_y_fp: int = 0
var radius_fp: int = 256
var telegraph_ticks: int = 1
var lifetime_ticks: int = 600
var family: Family = Family.AMULET
var polarity: Polarity = Polarity.INK
var emitter_index: int = -1
var phase_index: int = 0
