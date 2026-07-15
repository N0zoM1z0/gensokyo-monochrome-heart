class_name SaveSlotRules
extends RefCounted
## Three manual slots and three rolling checkpoint autosaves.

const MANUAL_SLOTS: Array[StringName] = [&"manual_01", &"manual_02", &"manual_03"]
const AUTO_SLOTS: Array[StringName] = [&"auto_day", &"auto_event", &"auto_mode"]
const ALL_SLOTS: Array[StringName] = [
	&"manual_01", &"manual_02", &"manual_03", &"auto_day", &"auto_event", &"auto_mode",
]


static func manual(slot_index: int) -> StringName:
	return MANUAL_SLOTS[slot_index - 1] if slot_index >= 1 and slot_index <= MANUAL_SLOTS.size() else &""


static func autosave_for(reason: StringName) -> StringName:
	match reason:
		&"day_start":
			return &"auto_day"
		&"event_completion", &"event_checkpoint":
			return &"auto_event"
		&"before_mode", &"after_mode":
			return &"auto_mode"
		_:
			return &""


static func is_valid(slot_id: StringName) -> bool:
	return slot_id in ALL_SLOTS


static func filename(slot_id: StringName) -> String:
	return "%s.save" % slot_id if is_valid(slot_id) else ""


static func card_filename(slot_id: StringName) -> String:
	return "%s.card.json" % slot_id if is_valid(slot_id) else ""
