class_name InventoryState
extends RefCounted
## Typed item, Keepsake, and Tea Blend collections for one profile.

const MAX_EQUIPPED_KEEPSAKES := 2
const PLAIN_TEA_ID: StringName = &"tea.plain_green"

var items: Dictionary[StringName, InventoryItemState] = {}
var keepsakes: Dictionary[StringName, KeepsakeState] = {}
var tea_blends: Dictionary[StringName, TeaBlendState] = {}
var equipped_keepsake_ids: Array[StringName] = []
var selected_tea_blend_id: StringName = PLAIN_TEA_ID


func duplicate_state() -> InventoryState:
	var copy := InventoryState.new()
	for item_id: StringName in items:
		copy.items[item_id] = items[item_id].duplicate_state()
	for keepsake_id: StringName in keepsakes:
		copy.keepsakes[keepsake_id] = keepsakes[keepsake_id].duplicate_state()
	for blend_id: StringName in tea_blends:
		copy.tea_blends[blend_id] = tea_blends[blend_id].duplicate_state()
	copy.equipped_keepsake_ids = equipped_keepsake_ids.duplicate()
	copy.selected_tea_blend_id = selected_tea_blend_id
	return copy
