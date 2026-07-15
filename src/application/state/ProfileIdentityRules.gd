class_name ProfileIdentityRules
extends RefCounted
## Stable save-profile identities associated with the four first-run presentation cards.


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
