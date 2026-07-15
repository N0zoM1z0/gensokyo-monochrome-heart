class_name SetComfortProfileCommand
extends GameCommand
## Persists a presentation/accessibility choice without changing story outcomes.

var comfort_profile_id: StringName


func _init(p_comfort_profile_id: StringName = &"") -> void:
	super(&"protagonist.set_comfort_profile")
	comfort_profile_id = p_comfort_profile_id
