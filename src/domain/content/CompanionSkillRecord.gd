class_name CompanionSkillRecord
extends RefCounted
## Typed roster-facing companion ability authored in each character skills document.

var id: StringName
var display_name: String
var description: String
var scope: StringName


func _init(
	p_id: StringName,
	p_display_name: String,
	p_description: String,
	p_scope: StringName
) -> void:
	id = p_id
	display_name = p_display_name
	description = p_description
	scope = p_scope
