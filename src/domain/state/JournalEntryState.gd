class_name JournalEntryState
extends RefCounted
## One discovered, source-aware Journal record with no hidden numeric deltas.

var entry_id: StringName
var title_key: StringName
var entry_type: StringName = &"event"
var source_event_id: StringName
var discovered_day: int = 1
var observation_keys: Array[StringName] = []
var tags: Array[StringName] = []
var is_read: bool = false


func _init(p_entry_id: StringName = &"") -> void:
	entry_id = p_entry_id


func duplicate_state() -> JournalEntryState:
	var copy := JournalEntryState.new(entry_id)
	copy.title_key = title_key
	copy.entry_type = entry_type
	copy.source_event_id = source_event_id
	copy.discovered_day = discovered_day
	copy.observation_keys = observation_keys.duplicate()
	copy.tags = tags.duplicate()
	copy.is_read = is_read
	return copy
