class_name SaveCardMetadata
extends RefCounted
## Lightweight slot-list record that can load without parsing the story payload.

var slot_id: StringName
var profile_id: StringName
var chapter_id: StringName
var day: int
var time_slot: StringName
var location_id: StringName
var play_time_seconds: int
var visible_character_ids: Array[StringName] = []
var route_completion_ids: Array[StringName] = []
var accessibility_preset_id: StringName
var screenshot_path: String
var game_version: String
var save_schema_version: int
var saved_utc: String
