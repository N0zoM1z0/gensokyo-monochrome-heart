class_name CampaignChapterDefinition
extends RefCounted
## Typed, locale-free transition from one headline chapter into the next.

var chapter_id: StringName
var next_chapter_id: StringName
var required_event_ids: Array[StringName] = []
var reveal_id: StringName
var reveal_flag_id: StringName
var journal_entry_id: StringName
var journal_title_key: StringName
var journal_observation_key: StringName
var next_region_conditions: Dictionary[StringName, StringName] = {}


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if not _matches(chapter_id, "^chapter\\.[1-9][0-9]*$"):
		errors.append("invalid campaign chapter ID: %s" % chapter_id)
	if not _matches(next_chapter_id, "^chapter\\.[1-9][0-9]*$"):
		errors.append("invalid next campaign chapter ID: %s" % next_chapter_id)
	if _chapter_rank(next_chapter_id) != _chapter_rank(chapter_id) + 1:
		errors.append("campaign chapter transition must advance exactly once")
	if required_event_ids.is_empty():
		errors.append("campaign chapter requires at least one event")
	var seen_events := {}
	for event_id: StringName in required_event_ids:
		if not _matches(event_id, "^evt\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*$"):
			errors.append("invalid required campaign event: %s" % event_id)
		elif seen_events.has(event_id):
			errors.append("duplicate required campaign event: %s" % event_id)
		seen_events[event_id] = true
	if not _matches(reveal_id, "^reveal\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*$"):
		errors.append("invalid campaign reveal ID: %s" % reveal_id)
	if not _matches(reveal_flag_id, "^flag\\.campaign\\.reveal\\.[a-z0-9_]+$"):
		errors.append("invalid campaign reveal flag: %s" % reveal_flag_id)
	if not _matches(journal_entry_id, "^journal\\.campaign\\.chapter_[1-9][0-9]*$"):
		errors.append("invalid campaign Journal ID: %s" % journal_entry_id)
	if journal_title_key == &"" or journal_observation_key == &"":
		errors.append("campaign reveal Journal localization keys are required")
	for region_id: StringName in next_region_conditions:
		if not _matches(region_id, "^loc\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*$"):
			errors.append("invalid cross-region target: %s" % region_id)
		if not _matches(next_region_conditions[region_id], "^region\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*$"):
			errors.append("invalid cross-region condition for %s" % region_id)
	return errors


func _chapter_rank(value: StringName) -> int:
	return String(value).trim_prefix("chapter.").to_int()


func _matches(value: StringName, pattern: String) -> bool:
	return RegEx.create_from_string(pattern).search(String(value)) != null
