class_name ContentDependencyEdge
extends RefCounted
## One typed stable-ID dependency with its semantic relationship kind.

var source_id: StringName
var target_id: StringName
var kind: StringName


func _init(p_source_id: StringName, p_target_id: StringName, p_kind: StringName) -> void:
	source_id = p_source_id
	target_id = p_target_id
	kind = p_kind


func sort_key() -> String:
	return "%s|%s|%s" % [source_id, target_id, kind]
