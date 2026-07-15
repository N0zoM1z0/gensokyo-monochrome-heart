class_name DialogueBeatRecord
extends RefCounted
## One typed dialogue beat referring to speaker and localization IDs.

var id: StringName
var speaker_id: StringName
var text_key: StringName
var portrait: StringName
var nonverbal_key: StringName
var advance_policy: StringName
var memory_tag: StringName
var source_path: String


func _init(
	p_id: StringName,
	p_speaker_id: StringName,
	p_text_key: StringName,
	p_portrait: StringName,
	p_nonverbal_key: StringName,
	p_advance_policy: StringName,
	p_memory_tag: StringName,
	p_source_path: String = ""
) -> void:
	id = p_id
	speaker_id = p_speaker_id
	text_key = p_text_key
	portrait = p_portrait
	nonverbal_key = p_nonverbal_key
	advance_policy = p_advance_policy
	memory_tag = p_memory_tag
	source_path = p_source_path
