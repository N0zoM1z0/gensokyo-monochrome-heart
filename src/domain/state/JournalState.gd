class_name JournalState
extends RefCounted
## Typed Journal index plus replay discovery state.

var entries: Dictionary[StringName, JournalEntryState] = {}
var replay_event_ids: Array[StringName] = []
var glossary_entry_ids: Array[StringName] = []


func duplicate_state() -> JournalState:
	var copy := JournalState.new()
	for entry_id: StringName in entries:
		copy.entries[entry_id] = entries[entry_id].duplicate_state()
	copy.replay_event_ids = replay_event_ids.duplicate()
	copy.glossary_entry_ids = glossary_entry_ids.duplicate()
	return copy
