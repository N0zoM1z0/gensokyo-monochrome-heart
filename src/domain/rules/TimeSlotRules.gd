class_name TimeSlotRules
extends RefCounted
## Four recoverable daily slots; crossing night starts a new day without failure pressure.

const SLOTS: Array[StringName] = [&"morning", &"day", &"dusk", &"night"]


static func advance(state: GameState, amount: int = 1) -> bool:
	if state == null or state.time_slot not in SLOTS or amount < 1 or amount > SLOTS.size():
		return false
	var slot_index := SLOTS.find(state.time_slot)
	for _step: int in range(amount):
		slot_index += 1
		if slot_index >= SLOTS.size():
			slot_index = 0
			state.day += 1
			state.inventory.selected_tea_blend_id = InventoryState.PLAIN_TEA_ID
	state.time_slot = SLOTS[slot_index]
	return true


static func is_valid(slot_id: StringName) -> bool:
	return slot_id in SLOTS
