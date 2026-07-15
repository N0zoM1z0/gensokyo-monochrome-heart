class_name FighterDefinition
extends RefCounted
## One original compact-fighter loadout and its character-shaped passive.

const PASSIVES := [&"neutral_reset", &"momentum"]

var id: StringName
var character_id: StringName
var name_key: StringName
var passive: StringName
var walk_speed_fp: int = 384
var jump_speed_fp: int = 1152
var hurtbox := FighterBox.new(-6, -30, 12, 30)
var moves: Array[FighterMoveDefinition] = []


func move_for_action(action: StringName) -> FighterMoveDefinition:
	for move: FighterMoveDefinition in moves:
		if move.action == action:
			return move
	return null


func move_by_id(move_id: StringName) -> FighterMoveDefinition:
	for move: FighterMoveDefinition in moves:
		if move.id == move_id:
			return move
	return null


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if not String(id).begins_with("fighter.") or not String(character_id).begins_with("char."):
		errors.append("fighter definition requires stable fighter/character IDs: %s" % id)
	if name_key == &"" or passive not in PASSIVES:
		errors.append("fighter %s requires a localized name and reviewed passive" % id)
	errors.append_array(hurtbox.validation_errors(String(id)))
	var actions: Array[StringName] = []
	for move: FighterMoveDefinition in moves:
		errors.append_array(move.validation_errors())
		if move.action in actions:
			errors.append("fighter %s duplicates action %s" % [id, move.action])
		actions.append(move.action)
	for required: StringName in FighterMoveDefinition.ACTIONS:
		if required not in actions:
			errors.append("fighter %s lacks move action %s" % [id, required])
	return errors
