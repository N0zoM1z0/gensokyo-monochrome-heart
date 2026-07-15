class_name ProtagonistState
extends RefCounted
## Locale-independent player identity and deterministic profile seed.

var origin_id: StringName = &"origin.outside_world"
var comfort_profile_id: StringName = &"accessibility.original"
var profile_seed: int = 1


func duplicate_state() -> ProtagonistState:
	var copy := ProtagonistState.new()
	copy.origin_id = origin_id
	copy.comfort_profile_id = comfort_profile_id
	copy.profile_seed = profile_seed
	return copy
