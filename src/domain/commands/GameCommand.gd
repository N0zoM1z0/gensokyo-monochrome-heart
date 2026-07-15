class_name GameCommand
extends RefCounted
## Serializable command identity; concrete commands carry typed mutation intent.

var command_id: StringName


func _init(p_command_id: StringName = &"command.unknown") -> void:
	command_id = p_command_id
