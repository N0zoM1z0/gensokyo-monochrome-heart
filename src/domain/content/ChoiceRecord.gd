class_name ChoiceRecord
extends RefCounted
## A stable event choice with typed tone options.

var id: StringName
var options: Array[ChoiceOptionRecord]


func _init(p_id: StringName, p_options: Array[ChoiceOptionRecord]) -> void:
	id = p_id
	options = p_options.duplicate()
