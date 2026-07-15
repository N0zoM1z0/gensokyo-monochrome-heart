class_name FighterMoveDefinition
extends RefCounted
## Data-only attack definition with explicit timing, boxes, and frame events.

const ACTIONS := [&"light", &"heavy", &"skill", &"skill_forward", &"spell"]

var id: StringName
var action: StringName
var startup_ticks: int = 1
var active_ticks: int = 1
var recovery_ticks: int = 1
var damage: int = 0
var guard_damage: int = 0
var hitstun_ticks: int = 0
var blockstun_ticks: int = 0
var temperament_cost: int = 0
var temperament_gain: int = 0
var hitbox := FighterBox.new()
var projectile_enabled: bool = false
var projectile_speed_fp: int = 0
var projectile_lifetime_ticks: int = 0
var projectile_family: StringName
var frame_events: Array[FighterFrameEvent] = []


func duration_ticks() -> int:
	return startup_ticks + active_ticks + recovery_ticks


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if not String(id).begins_with("move."):
		errors.append("fighter move ID must begin with move.: %s" % id)
	if action not in ACTIONS:
		errors.append("fighter move %s has unsupported action %s" % [id, action])
	if startup_ticks <= 0 or active_ticks <= 0 or recovery_ticks <= 0:
		errors.append("fighter move %s timing must be positive" % id)
	if damage <= 0 or hitstun_ticks <= 0 or blockstun_ticks <= 0:
		errors.append("fighter move %s damage and stun must be positive" % id)
	errors.append_array(hitbox.validation_errors(String(id)))
	var creates_damage := false
	for event: FighterFrameEvent in frame_events:
		errors.append_array(event.validation_errors(id, duration_ticks()))
		creates_damage = creates_damage or event.type in [&"hitbox_on", &"projectile"]
	if not creates_damage:
		errors.append("fighter move %s has no data-authored damaging frame event" % id)
	if projectile_enabled and (projectile_speed_fp == 0 or projectile_lifetime_ticks <= 0):
		errors.append("fighter projectile move %s has invalid speed or lifetime" % id)
	return errors


func events_at(tick: int) -> Array[FighterFrameEvent]:
	var result: Array[FighterFrameEvent] = []
	for event: FighterFrameEvent in frame_events:
		if event.tick == tick:
			result.append(event)
	return result
