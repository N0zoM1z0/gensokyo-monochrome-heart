class_name PixelAlignmentValidator
extends RefCounted
## Rejects fractional Control and Sprite2D positions in reviewable presentation scenes.

const EPSILON := 0.00001


func validate_tree(root: Node, source_name: String = "runtime tree") -> Array[String]:
	var errors: Array[String] = []
	_validate_node(root, root, source_name, errors)
	return errors


func _validate_node(node: Node, root: Node, source_name: String, errors: Array[String]) -> void:
	if node is Control:
		_validate_position(node.position, "Control", node, root, source_name, errors)
	elif node is Sprite2D:
		_validate_position(node.position, "Sprite2D", node, root, source_name, errors)
	for child: Node in node.get_children():
		_validate_node(child, root, source_name, errors)


func _validate_position(
	position: Vector2,
	node_type: String,
	node: Node,
	root: Node,
	source_name: String,
	errors: Array[String]
) -> void:
	if _is_integer(position.x) and _is_integer(position.y):
		return
	var relative_path := String(root.get_path_to(node))
	errors.append(
		"%s::%s %s position must use integer pixels, got (%.3f,%.3f)"
		% [source_name, relative_path, node_type, position.x, position.y]
	)


func _is_integer(value: float) -> bool:
	return absf(value - roundf(value)) <= EPSILON
