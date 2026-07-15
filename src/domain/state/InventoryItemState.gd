class_name InventoryItemState
extends RefCounted
## Counted non-Keepsake inventory entry.

var item_id: StringName
var count: int = 0


func _init(p_item_id: StringName = &"", p_count: int = 0) -> void:
	item_id = p_item_id
	count = p_count


func duplicate_state() -> InventoryItemState:
	return InventoryItemState.new(item_id, count)
