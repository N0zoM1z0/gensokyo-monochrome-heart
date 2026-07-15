class_name GameStateTransaction
extends RefCounted
## Multi-command unit of work; the target changes only after a fully valid commit.

var results: Array[CommandResult] = []

var _target: GameState
var _working: GameState
var _dispatcher := GameCommandDispatcher.new()
var _has_failed: bool = false
var _is_closed: bool = false


func _init(target: GameState) -> void:
	_target = target
	_working = target.deep_copy() if target != null else null


func apply(command: GameCommand) -> CommandResult:
	if _is_closed:
		return CommandResult.failure(CommandResult.Code.TRANSACTION_CLOSED, &"transaction.apply", "transaction is closed")
	if _has_failed:
		return CommandResult.failure(CommandResult.Code.TRANSACTION_FAILED, &"transaction.apply", "transaction already contains a failed command")
	var result := _dispatcher.dispatch(_working, command)
	results.append(result)
	if not result.is_success():
		_has_failed = true
	return result


func commit() -> CommandResult:
	if _is_closed:
		return CommandResult.failure(CommandResult.Code.TRANSACTION_CLOSED, &"transaction.commit", "transaction is closed")
	_is_closed = true
	if _target == null or _working == null:
		return CommandResult.failure(CommandResult.Code.NO_STATE, &"transaction.commit", "transaction target is missing")
	if _has_failed:
		return CommandResult.failure(CommandResult.Code.TRANSACTION_FAILED, &"transaction.commit", "one or more commands failed; target was not changed")
	var errors := GameStateValidator.new().validate(_working)
	if not errors.is_empty():
		return CommandResult.failure(CommandResult.Code.INVARIANT_FAILURE, &"transaction.commit", "; ".join(errors))
	_target.copy_from(_working)
	return CommandResult.success(&"transaction.commit", "all commands committed")


func rollback() -> CommandResult:
	if _is_closed:
		return CommandResult.failure(CommandResult.Code.TRANSACTION_CLOSED, &"transaction.rollback", "transaction is closed")
	_is_closed = true
	return CommandResult.new(CommandResult.Code.OK, &"transaction.rollback", "transaction discarded", false)


func working_state() -> GameState:
	return _working.deep_copy() if _working != null else null


func has_failed() -> bool:
	return _has_failed


func is_closed() -> bool:
	return _is_closed
