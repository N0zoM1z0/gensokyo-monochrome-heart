extends Node
## Preserves stable focus IDs across nested modal scopes.

var _prior_focus_stack: Array[StringName] = []


func push_prior_focus(focus_id: StringName) -> void:
	_prior_focus_stack.append(focus_id)


func pop_prior_focus() -> StringName:
	return _prior_focus_stack.pop_back() if not _prior_focus_stack.is_empty() else &""


func depth() -> int:
	return _prior_focus_stack.size()


func clear() -> void:
	_prior_focus_stack.clear()
