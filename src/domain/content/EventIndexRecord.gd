class_name EventIndexRecord
extends RefCounted
## Planning/runtime index record; graph execution data lives in EventGraphRecord.

var id: StringName
var legacy_id: StringName
var title_en: String
var location_id: StringName
var lead_character_ids: Array[StringName]
var primary_mode: StringName
var core_change: String
var status: StringName
var estimated_minutes: int
var comfort_tags: Array[StringName]
var source_path: String


func _init(
	p_id: StringName,
	p_legacy_id: StringName,
	p_title_en: String,
	p_location_id: StringName,
	p_lead_character_ids: Array[StringName],
	p_primary_mode: StringName,
	p_core_change: String,
	p_status: StringName,
	p_estimated_minutes: int,
	p_comfort_tags: Array[StringName],
	p_source_path: String = ""
) -> void:
	id = p_id
	legacy_id = p_legacy_id
	title_en = p_title_en
	location_id = p_location_id
	lead_character_ids = p_lead_character_ids.duplicate()
	primary_mode = p_primary_mode
	core_change = p_core_change
	status = p_status
	estimated_minutes = p_estimated_minutes
	comfort_tags = p_comfort_tags.duplicate()
	source_path = p_source_path
