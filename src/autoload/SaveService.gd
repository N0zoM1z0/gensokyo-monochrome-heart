extends Node
## Narrow runtime gateway for safe manual saves, rolling checkpoints, and typed loads.

signal save_completed(result: SaveOperationResult)
signal save_failed(result: SaveOperationResult)
signal load_completed(result: SaveOperationResult)
signal load_failed(result: SaveOperationResult)

var _repository := SaveRepository.new()
var _kernel_override: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func configure_for_test(kernel: Node, root_path: String) -> void:
	_kernel_override = kernel
	_repository = SaveRepository.new(root_path)


func save_manual(
	slot_index: int,
	context: SaveCardContext = null,
	timestamp_override: String = ""
) -> SaveOperationResult:
	return _save_slot(SaveSlotRules.manual(slot_index), context, timestamp_override)


func autosave(
	reason: StringName,
	context: SaveCardContext = null,
	timestamp_override: String = ""
) -> SaveOperationResult:
	var slot_id := SaveSlotRules.autosave_for(reason)
	if slot_id == &"":
		return _finish_save(_failure(
			SaveOperationResult.Code.INVALID_SLOT,
			"unsafe or unknown autosave boundary: %s" % reason
		))
	return _save_slot(slot_id, context, timestamp_override)


func load_slot(profile_id: StringName, slot_id: StringName) -> SaveOperationResult:
	var result := _repository.load(profile_id, slot_id)
	if not result.is_success():
		load_failed.emit(result)
		return result
	var kernel := _kernel()
	if kernel == null or not kernel.has_method("replace_state"):
		result.code = SaveOperationResult.Code.INVALID_STATE
		result.message = "GameKernel is unavailable; loaded state was not activated"
		load_failed.emit(result)
		return result
	var accepted: Variant = kernel.call("replace_state", result.state, &"state.load")
	if not accepted is CommandResult or not accepted.is_success():
		result.code = SaveOperationResult.Code.INVALID_STATE
		result.message = "GameKernel rejected the validated loaded state"
		if accepted is CommandResult:
			result.diagnostics.append(accepted.message)
		load_failed.emit(result)
		return result
	load_completed.emit(result)
	return result


func list_cards(profile_id: StringName) -> Array[SaveCardMetadata]:
	return _repository.list_cards(profile_id)


func latest_story_card() -> SaveCardMetadata:
	var latest: SaveCardMetadata
	for profile_id: StringName in ProfileIdentityRules.STORY_PROFILE_IDS:
		for card: SaveCardMetadata in _repository.list_cards(profile_id):
			if latest == null or card.saved_utc > latest.saved_utc:
				latest = card
	return latest


func _save_slot(
	slot_id: StringName,
	context: SaveCardContext,
	timestamp_override: String
) -> SaveOperationResult:
	var kernel := _kernel()
	if kernel == null or not kernel.has_method("state_snapshot"):
		return _finish_save(_failure(
			SaveOperationResult.Code.INVALID_STATE,
			"GameKernel is unavailable"
		))
	var snapshot: Variant = kernel.call("state_snapshot")
	if not snapshot is GameState:
		return _finish_save(_failure(
			SaveOperationResult.Code.INVALID_STATE,
			"active GameState is missing"
		))
	return _finish_save(_repository.save(snapshot, slot_id, context, timestamp_override))


func _kernel() -> Node:
	return _kernel_override if _kernel_override != null else get_node_or_null("/root/GameKernel")


func _finish_save(result: SaveOperationResult) -> SaveOperationResult:
	if result.is_success():
		save_completed.emit(result)
	else:
		save_failed.emit(result)
	return result


func _failure(code: SaveOperationResult.Code, message: String) -> SaveOperationResult:
	return SaveOperationResult.new(code, message)
