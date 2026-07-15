class_name NamedTextArgument
extends RefCounted
## Serializable-friendly named localization substitution.

var name: StringName
var value: String


func _init(p_name: StringName = &"", p_value: String = "") -> void:
	name = p_name
	value = p_value
