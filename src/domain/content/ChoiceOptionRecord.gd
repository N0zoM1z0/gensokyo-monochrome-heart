class_name ChoiceOptionRecord
extends RefCounted
## One localized tone option and its stable event-node destination.

var tone: StringName
var text_key: StringName
var next_node_id: StringName


func _init(p_tone: StringName, p_text_key: StringName, p_next_node_id: StringName) -> void:
	tone = p_tone
	text_key = p_text_key
	next_node_id = p_next_node_id
