class_name EventNodeRecord
extends RefCounted
## Closed typed union for every node shape used by the reviewed starter graph.

var id: StringName
var type: StringName
var next_node_id: StringName
var music_state_id: StringName
var objective_key: StringName
var interactable_ids: Array[StringName] = []
var beat_id: StringName
var choice: ChoiceRecord
var effects: Array[EventEffectRecord] = []
var minigame_id: StringName
var target_band: StringName
var cups: int
var result_branches: Array[ModeResultBranchRecord] = []
var item_id: StringName
var journal_entry_id: StringName
var outcome: StringName


func _init(p_id: StringName, p_type: StringName) -> void:
	id = p_id
	type = p_type


func outgoing_node_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	if next_node_id != &"":
		result.append(next_node_id)
	if choice != null:
		for option: ChoiceOptionRecord in choice.options:
			result.append(option.next_node_id)
	for branch: ModeResultBranchRecord in result_branches:
		result.append(branch.next_node_id)
	result.sort_custom(_node_id_less)
	return result


func _node_id_less(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
