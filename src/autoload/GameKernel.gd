extends Node
## Sole runtime owner of the active typed GameState and its validated command flow.

signal profile_created(snapshot: GameState)
signal state_changed(snapshot: GameState, result: CommandResult, revision: int)
signal command_rejected(result: CommandResult)
signal state_cleared(previous_profile_id: StringName)

var _active_state: GameState
var _content_override: ContentRepository
var _dispatcher := GameCommandDispatcher.new()
var _revision: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func configure_content_for_test(repository: ContentRepository) -> void:
	_content_override = repository


func create_new_profile(
	profile_id: StringName,
	comfort_profile_id: StringName = &"accessibility.original"
) -> CommandResult:
	if not ProfileIdentityRules.is_valid_story_profile(profile_id):
		return _reject(CommandResult.failure(
			CommandResult.Code.INVALID_ARGUMENT,
			&"profile.create",
			"invalid story profile ID: %s" % profile_id
		))
	if comfort_profile_id not in ProtagonistState.COMFORT_PROFILE_IDS:
		return _reject(CommandResult.failure(
			CommandResult.Code.INVALID_ARGUMENT,
			&"profile.create",
			"invalid comfort profile: %s" % comfort_profile_id
		))
	var content := _content_repository()
	if content == null or content.report == null or not content.report.is_success():
		return _reject(CommandResult.failure(
			CommandResult.Code.NOT_FOUND,
			&"profile.create",
			"validated ContentDB snapshot is unavailable"
		))
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in content.all_characters():
		character_ids.append(character.id)
	var region_ids: Array[StringName] = []
	for location: LocationRecord in content.all_locations():
		region_ids.append(location.id)
	var candidate := GameStateFactory.create_new(profile_id, character_ids, region_ids)
	candidate.protagonist.comfort_profile_id = comfort_profile_id
	var errors := GameStateValidator.new().validate(candidate)
	if not errors.is_empty():
		return _reject(CommandResult.failure(
			CommandResult.Code.INVARIANT_FAILURE,
			&"profile.create",
			"new profile failed validation: %s" % "; ".join(errors)
		))
	_active_state = candidate
	_revision = 1
	var result := CommandResult.success(&"profile.create", "deterministic profile state created")
	profile_created.emit(state_snapshot())
	state_changed.emit(state_snapshot(), result, _revision)
	return result


func dispatch(command: GameCommand) -> CommandResult:
	var result := _dispatcher.dispatch(_active_state, command)
	if not result.is_success():
		return _reject(result)
	_revision += 1
	state_changed.emit(state_snapshot(), result, _revision)
	return result


func dispatch_transaction(commands: Array[GameCommand]) -> CommandResult:
	if _active_state == null:
		return _reject(CommandResult.failure(
			CommandResult.Code.NO_STATE,
			&"transaction.commit",
			"active GameState is missing"
		))
	if commands.is_empty():
		return _reject(CommandResult.failure(
			CommandResult.Code.INVALID_ARGUMENT,
			&"transaction.commit",
			"transaction requires at least one command"
		))
	var transaction := GameStateTransaction.new(_active_state)
	for command: GameCommand in commands:
		var effect_result := transaction.apply(command)
		if not effect_result.is_success():
			transaction.rollback()
			return _reject(effect_result)
	var result := transaction.commit()
	if not result.is_success():
		return _reject(result)
	_revision += 1
	state_changed.emit(state_snapshot(), result, _revision)
	return result


func replace_state(candidate: GameState, source_id: StringName = &"state.load") -> CommandResult:
	var errors := GameStateValidator.new().validate(candidate)
	if not errors.is_empty():
		return _reject(CommandResult.failure(
			CommandResult.Code.INVARIANT_FAILURE,
			source_id,
			"replacement state failed validation: %s" % "; ".join(errors)
		))
	_active_state = candidate.deep_copy()
	_revision += 1
	var result := CommandResult.success(source_id, "active state replaced")
	state_changed.emit(state_snapshot(), result, _revision)
	return result


func clear_state() -> void:
	var previous_profile_id := _active_state.profile_id if _active_state != null else &""
	_active_state = null
	_revision = 0
	if previous_profile_id != &"":
		state_cleared.emit(previous_profile_id)


func has_active_state() -> bool:
	return _active_state != null


func active_profile_id() -> StringName:
	return _active_state.profile_id if _active_state != null else &""


func state_snapshot() -> GameState:
	return _active_state.deep_copy() if _active_state != null else null


func revision() -> int:
	return _revision


func _content_repository() -> ContentRepository:
	if _content_override != null:
		return _content_override
	var content_db := get_node_or_null("/root/ContentDB")
	if content_db == null or not content_db.has_method("snapshot"):
		return null
	var snapshot: Variant = content_db.call("snapshot")
	return snapshot if snapshot is ContentRepository else null


func _reject(result: CommandResult) -> CommandResult:
	command_rejected.emit(result)
	return result
