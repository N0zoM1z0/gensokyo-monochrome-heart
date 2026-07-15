class_name FighterDuelDefinition
extends RefCounted
## Typed data root for one story duel and its fixed technical limits.

var schema_version: int = 0
var id: StringName
var title_key: StringName
var arena_width: int = 320
var ground_y: int = 142
var left_bound: int = 12
var right_bound: int = 308
var breaks_to_win: int = 2
var max_projectiles_per_fighter: int = 64
var fighters: Array[FighterDefinition] = []
var source_path: String
var data_hash: String


func fighter(fighter_id: StringName) -> FighterDefinition:
	for candidate: FighterDefinition in fighters:
		if candidate.id == fighter_id:
			return candidate
	return null


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if schema_version != 1 or not String(id).begins_with("duel.") or title_key == &"":
		errors.append("fighter duel requires schema v1, stable ID, and title key")
	if arena_width != 320 or ground_y <= 0 or left_bound >= right_bound:
		errors.append("fighter duel arena geometry is invalid")
	if breaks_to_win != 2:
		errors.append("compact fighter story duel must require exactly two spell breaks")
	if max_projectiles_per_fighter != 64:
		errors.append("fighter projectile contract must remain exactly 64 per fighter")
	if fighters.size() != 2:
		errors.append("foundation duel requires exactly two fighter definitions")
	var ids: Array[StringName] = []
	for definition: FighterDefinition in fighters:
		errors.append_array(definition.validation_errors())
		if definition.id in ids:
			errors.append("duplicate fighter definition: %s" % definition.id)
		ids.append(definition.id)
	return errors
