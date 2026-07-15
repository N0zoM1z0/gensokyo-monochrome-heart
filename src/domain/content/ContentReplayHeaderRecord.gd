class_name ContentReplayHeaderRecord
extends RefCounted
## Typed content identity embedded by future deterministic replay formats.

const SCHEMA: StringName = &"gmh-replay-content-v1"

var content_revision: StringName
var content_hash: String


func _init(p_content_revision: StringName, p_content_hash: String) -> void:
	content_revision = p_content_revision
	content_hash = p_content_hash


func matches(other: ContentReplayHeaderRecord) -> bool:
	return (
		other != null
		and content_revision == other.content_revision
		and content_hash == other.content_hash
	)


func diagnostic_header() -> String:
	return "content_revision=%s content_hash=%s" % [content_revision, content_hash]
