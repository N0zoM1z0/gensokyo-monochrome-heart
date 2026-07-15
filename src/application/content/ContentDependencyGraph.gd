class_name ContentDependencyGraph
extends RefCounted
## Deterministic stable-ID graph built from typed records rather than raw JSON.

var _node_ids: Array[StringName] = []
var _edges: Array[ContentDependencyEdge] = []


func add_node(node_id: StringName) -> void:
	if node_id != &"" and node_id not in _node_ids:
		_node_ids.append(node_id)
		_node_ids.sort_custom(_node_less)


func add_edge(source_id: StringName, target_id: StringName, kind: StringName) -> void:
	if source_id == &"" or target_id == &"":
		return
	add_node(source_id)
	add_node(target_id)
	for edge: ContentDependencyEdge in _edges:
		if edge.source_id == source_id and edge.target_id == target_id and edge.kind == kind:
			return
	_edges.append(ContentDependencyEdge.new(source_id, target_id, kind))
	_edges.sort_custom(_edge_less)


func node_ids() -> Array[StringName]:
	return _node_ids.duplicate()


func edges() -> Array[ContentDependencyEdge]:
	return _edges.duplicate()


func dependencies_of(source_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	for edge: ContentDependencyEdge in _edges:
		if edge.source_id == source_id and edge.target_id not in result:
			result.append(edge.target_id)
	result.sort_custom(_node_less)
	return result


func dependents_of(target_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	for edge: ContentDependencyEdge in _edges:
		if edge.target_id == target_id and edge.source_id not in result:
			result.append(edge.source_id)
	result.sort_custom(_node_less)
	return result


func _edge_less(left: ContentDependencyEdge, right: ContentDependencyEdge) -> bool:
	return left.sort_key() < right.sort_key()


func _node_less(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
