class_name ModeResultBranchRecord
extends RefCounted
## Stable mechanical result tag mapped to the next event node.

var result_tag: StringName
var next_node_id: StringName


func _init(p_result_tag: StringName, p_next_node_id: StringName) -> void:
	result_tag = p_result_tag
	next_node_id = p_next_node_id
