class_name EventGraphRecord
extends RefCounted
## Fully typed event graph; no authored JSON object survives this boundary.

var schema_version: int
var id: StringName
var title_key: StringName
var location_id: StringName
var spot_id: StringName
var cast: Array[StringName]
var availability: Array[AvailabilityPredicateRecord]
var entry_node_id: StringName
var nodes: Array[EventNodeRecord]
var origin_canon: int
var origin_fanon: int
var origin_original: int
var comfort_tags: Array[StringName]
var source_path: String


func _init(
	p_schema_version: int,
	p_id: StringName,
	p_title_key: StringName,
	p_location_id: StringName,
	p_spot_id: StringName,
	p_cast: Array[StringName],
	p_entry_node_id: StringName,
	p_comfort_tags: Array[StringName],
	p_source_path: String = ""
) -> void:
	schema_version = p_schema_version
	id = p_id
	title_key = p_title_key
	location_id = p_location_id
	spot_id = p_spot_id
	cast = p_cast.duplicate()
	entry_node_id = p_entry_node_id
	comfort_tags = p_comfort_tags.duplicate()
	source_path = p_source_path
	availability = []
	nodes = []


func node(node_id: StringName) -> EventNodeRecord:
	for candidate: EventNodeRecord in nodes:
		if candidate.id == node_id:
			return candidate
	return null
