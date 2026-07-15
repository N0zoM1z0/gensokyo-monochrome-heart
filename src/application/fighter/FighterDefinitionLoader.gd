class_name FighterDefinitionLoader
extends RefCounted
## Parses the closed fighter JSON vocabulary into data-only runtime records.

var errors: Array[String] = []


func load_path(path: String) -> FighterDuelDefinition:
	errors.clear()
	if not FileAccess.file_exists(path):
		errors.append("fighter duel file is missing: %s" % path)
		return null
	var text := FileAccess.get_file_as_string(path)
	var raw: Variant = JSON.parse_string(text)
	if not raw is Dictionary:
		errors.append("fighter duel root must be an object: %s" % path)
		return null
	var duel := FighterDuelDefinition.new()
	duel.schema_version = int(raw.get("schema_version", 0))
	duel.id = StringName(raw.get("id", ""))
	duel.title_key = StringName(raw.get("title_key", ""))
	var arena: Variant = raw.get("arena", {})
	if arena is Dictionary:
		duel.arena_width = int(arena.get("width", 0))
		duel.ground_y = int(arena.get("ground_y", 0))
		duel.left_bound = int(arena.get("left_bound", 0))
		duel.right_bound = int(arena.get("right_bound", 0))
	else:
		errors.append("fighter arena must be an object")
	duel.breaks_to_win = int(raw.get("breaks_to_win", 0))
	duel.max_projectiles_per_fighter = int(raw.get("max_projectiles_per_fighter", 0))
	for fighter_raw: Variant in raw.get("fighters", []):
		if not fighter_raw is Dictionary:
			errors.append("fighter entry must be an object")
			continue
		duel.fighters.append(_parse_fighter(fighter_raw))
	duel.source_path = path
	duel.data_hash = text.sha256_text()
	errors.append_array(duel.validation_errors())
	return duel


func _parse_fighter(raw: Dictionary) -> FighterDefinition:
	var fighter := FighterDefinition.new()
	fighter.id = StringName(raw.get("id", ""))
	fighter.character_id = StringName(raw.get("character_id", ""))
	fighter.name_key = StringName(raw.get("name_key", ""))
	fighter.passive = StringName(raw.get("passive", ""))
	fighter.walk_speed_fp = roundi(float(raw.get("walk_speed", 0.0)) * 256.0)
	fighter.jump_speed_fp = roundi(float(raw.get("jump_speed", 0.0)) * 256.0)
	fighter.hurtbox = _parse_box(raw.get("hurtbox", {}), "fighter %s hurtbox" % fighter.id)
	for move_raw: Variant in raw.get("moves", []):
		if not move_raw is Dictionary:
			errors.append("fighter %s move must be an object" % fighter.id)
			continue
		fighter.moves.append(_parse_move(move_raw))
	return fighter


func _parse_move(raw: Dictionary) -> FighterMoveDefinition:
	var move := FighterMoveDefinition.new()
	move.id = StringName(raw.get("id", ""))
	move.action = StringName(raw.get("action", ""))
	move.startup_ticks = int(raw.get("startup_ticks", 0))
	move.active_ticks = int(raw.get("active_ticks", 0))
	move.recovery_ticks = int(raw.get("recovery_ticks", 0))
	move.damage = int(raw.get("damage", 0))
	move.guard_damage = int(raw.get("guard_damage", 0))
	move.hitstun_ticks = int(raw.get("hitstun_ticks", 0))
	move.blockstun_ticks = int(raw.get("blockstun_ticks", 0))
	move.temperament_cost = int(raw.get("temperament_cost", 0))
	move.temperament_gain = int(raw.get("temperament_gain", 0))
	move.hitbox = _parse_box(raw.get("hitbox", {}), "move %s hitbox" % move.id)
	var projectile: Variant = raw.get("projectile", {})
	if projectile is Dictionary:
		move.projectile_enabled = bool(projectile.get("enabled", false))
		move.projectile_speed_fp = roundi(float(projectile.get("speed", 0.0)) * 256.0)
		move.projectile_lifetime_ticks = int(projectile.get("lifetime_ticks", 0))
		move.projectile_family = StringName(projectile.get("family", ""))
	for event_raw: Variant in raw.get("events", []):
		if not event_raw is Dictionary:
			errors.append("move %s frame event must be an object" % move.id)
			continue
		var event := FighterFrameEvent.new()
		event.tick = int(event_raw.get("tick", -1))
		event.type = StringName(event_raw.get("type", ""))
		event.value = int(event_raw.get("value", 0))
		move.frame_events.append(event)
	return move


func _parse_box(raw: Variant, label: String) -> FighterBox:
	if not raw is Dictionary:
		errors.append("%s must be an object" % label)
		return FighterBox.new(0, 0, 0, 0)
	return FighterBox.new(
		int(raw.get("x", 0)),
		int(raw.get("y", 0)),
		int(raw.get("width", 0)),
		int(raw.get("height", 0))
	)
