class_name ImpossibleErrandOption
extends RefCounted
## One explicit philosophy for answering an impossible request.

var approach_id: StringName
var label_key: StringName
var action_key: StringName
var consequence_key: StringName


func _init(
	p_approach_id: StringName = &"",
	p_label_key: StringName = &"",
	p_action_key: StringName = &"",
	p_consequence_key: StringName = &""
) -> void:
	approach_id = p_approach_id
	label_key = p_label_key
	action_key = p_action_key
	consequence_key = p_consequence_key
