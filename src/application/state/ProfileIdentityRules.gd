class_name ProfileIdentityRules
extends RefCounted
## Stable save-profile identities associated with the four first-run presentation cards.

const STORY_PROFILE_IDS: Array[StringName] = [&"p01", &"p02", &"p03", &"p04"]


static func story_profile_id(presentation_profile_id: StringName) -> StringName:
	match presentation_profile_id:
		&"A":
			return &"p01"
		&"B":
			return &"p02"
		&"C":
			return &"p03"
		&"D":
			return &"p04"
		_:
			return &""


static func is_valid_story_profile(profile_id: StringName) -> bool:
	return RegEx.create_from_string("^p[0-9]{2,}$").search(String(profile_id)) != null


static func presentation_profile_id(story_profile_id: StringName) -> StringName:
	var index := STORY_PROFILE_IDS.find(story_profile_id)
	return [&"A", &"B", &"C", &"D"][index] if index >= 0 else &"A"
