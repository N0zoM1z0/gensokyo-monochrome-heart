class_name RemoveInventoryItemCommand
extends GameCommand

var item_id: StringName
var count: int


func _init(p_item_id: StringName, p_count: int) -> void:
	super(&"state.remove_inventory_item")
	item_id = p_item_id
	count = p_count
