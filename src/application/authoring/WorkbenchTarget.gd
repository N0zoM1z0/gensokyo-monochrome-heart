class_name WorkbenchTarget
extends RefCounted
## One discoverable M11 debug target with stable identity and provenance.

var id: StringName
var kind: StringName
var category: StringName
var label: String
var resource_path: String
var definition_path: String
var fixture_state: StringName
var description: String


func _init(
	p_id: StringName,
	p_kind: StringName,
	p_category: StringName,
	p_label: String,
	p_resource_path: String,
	p_definition_path: String,
	p_fixture_state: StringName,
	p_description: String
) -> void:
	id = p_id
	kind = p_kind
	category = p_category
	label = p_label
	resource_path = p_resource_path
	definition_path = p_definition_path
	fixture_state = p_fixture_state
	description = p_description
