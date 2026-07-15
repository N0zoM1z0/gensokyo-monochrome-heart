class_name AudioMixPolicy
extends RefCounted
## Relative placeholder-mix contract; final mastering may move all values together.

enum Role {
	AUTO,
	DIALOGUE_WARNING,
	PLAYER_CRITICAL,
	COMBAT_HIGH,
	GAMEPLAY,
	UI,
	AMBIENCE,
}

const MUSIC_DB := -10.0
const DIALOGUE_DUCK_DB := -3.0
const ROLE_DB := {
	Role.DIALOGUE_WARNING: -1.0,
	Role.PLAYER_CRITICAL: -3.0,
	Role.COMBAT_HIGH: -5.0,
	Role.GAMEPLAY: -8.0,
	Role.UI: -10.0,
	Role.AMBIENCE: -14.0,
}


static func gain_db(role: Role, cue_id: StringName = &"") -> float:
	var resolved := infer_role(cue_id) if role == Role.AUTO else role
	return float(ROLE_DB.get(resolved, ROLE_DB[Role.GAMEPLAY]))


static func music_gain_db(dialogue_ducked: bool) -> float:
	return MUSIC_DB + (DIALOGUE_DUCK_DB if dialogue_ducked else 0.0)


static func infer_role(cue_id: StringName) -> Role:
	var cue := String(cue_id)
	if cue.contains("warning") or cue.contains("threat"):
		return Role.DIALOGUE_WARNING
	if cue.contains("bomb") or cue.contains("damage") or cue.contains("spell_break"):
		return Role.PLAYER_CRITICAL
	if cue.contains("impact") or cue.contains("result"):
		return Role.COMBAT_HIGH
	if cue.begins_with("sfx.ui"):
		return Role.UI
	if cue.contains("step") or cue.contains("door") or cue.contains("prop"):
		return Role.AMBIENCE
	return Role.GAMEPLAY
