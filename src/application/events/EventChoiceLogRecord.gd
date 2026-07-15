class_name EventChoiceLogRecord
extends RefCounted
## Locale-independent runtime choice evidence.

var choice_id: StringName
var tone: StringName
var node_id: StringName


func _init(p_choice_id: StringName, p_tone: StringName, p_node_id: StringName) -> void:
	choice_id = p_choice_id
	tone = p_tone
	node_id = p_node_id
