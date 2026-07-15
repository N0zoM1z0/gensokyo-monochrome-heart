class_name ContentManifestRecord
extends RefCounted
## Typed package revision and expected starter counts from content_index.json.

var package_schema_version: int
var content_revision: StringName
var expected_characters: int
var expected_locations: int
var expected_events: int
var expected_localization_rows: int
var files: Array[String]
var schemas: Array[String]


func _init(p_schema_version: int, p_revision: StringName) -> void:
	package_schema_version = p_schema_version
	content_revision = p_revision
	files = []
	schemas = []
