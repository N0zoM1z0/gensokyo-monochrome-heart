class_name EventPresentationCue
extends RefCounted
## Stable nonnumeric cue emitted while the interpreter advances automatic nodes.

var kind: StringName
var cue_id: StringName
var owner_id: StringName
var semantic_key: StringName


func _init(
	p_kind: StringName = &"",
	p_cue_id: StringName = &"",
	p_owner_id: StringName = &"",
	p_semantic_key: StringName = &""
) -> void:
	kind = p_kind
	cue_id = p_cue_id
	owner_id = p_owner_id
	semantic_key = p_semantic_key
