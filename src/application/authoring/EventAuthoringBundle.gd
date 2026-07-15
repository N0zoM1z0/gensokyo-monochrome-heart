class_name EventAuthoringBundle
extends RefCounted
## Typed, isolated authoring snapshot used by M11 validation and preview tools.

var bundle_path: String
var source_event_id: StringName
var graph: EventGraphRecord
var dialogue_beats: Array[DialogueBeatRecord] = []
var localized_strings: Array[ContentStringRecord] = []
var errors: Array[String] = []
var warnings: Array[String] = []


func is_valid() -> bool:
	return errors.is_empty()


func dialogue_beat(beat_id: StringName) -> DialogueBeatRecord:
	for beat: DialogueBeatRecord in dialogue_beats:
		if beat.id == beat_id:
			return beat
	return null


func localized_string(key: StringName) -> ContentStringRecord:
	for record: ContentStringRecord in localized_strings:
		if record.key == key:
			return record
	return null


func human_readable() -> String:
	var event_id := graph.id if graph != null else &""
	var lines: PackedStringArray = [
		"AUTHORING BUNDLE event=%s beats=%d strings=%d errors=%d warnings=%d"
		% [event_id, dialogue_beats.size(), localized_strings.size(), errors.size(), warnings.size()]
	]
	for error: String in errors:
		lines.append("ERROR %s" % error)
	for warning: String in warnings:
		lines.append("WARNING %s" % warning)
	return "\n".join(lines)
