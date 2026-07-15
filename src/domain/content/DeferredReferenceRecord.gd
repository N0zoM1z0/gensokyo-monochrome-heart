class_name DeferredReferenceRecord
extends RefCounted
## Reviewed allowlist entry for a stable ID authored in a later milestone.

var id: StringName
var kind: StringName
var target_milestone: StringName
var reason: String
var source_path: String


func _init(
	p_id: StringName,
	p_kind: StringName,
	p_target_milestone: StringName,
	p_reason: String,
	p_source_path: String = ""
) -> void:
	id = p_id
	kind = p_kind
	target_milestone = p_target_milestone
	reason = p_reason
	source_path = p_source_path
