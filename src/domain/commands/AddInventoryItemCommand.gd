class_name AddInventoryItemCommand
extends GameCommand

var item_id: StringName
var count: int


func _init(p_item_id: StringName, p_count: int) -> void:
	super(&"state.add_inventory_item")
	item_id = p_item_id
	count = p_count
