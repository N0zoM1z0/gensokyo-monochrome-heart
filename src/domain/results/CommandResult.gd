class_name CommandResult
extends RefCounted
## Expected command outcome with a stable diagnostic code and no thrown control flow.

enum Code {
	OK,
	NO_STATE,
	INVALID_COMMAND,
	INVALID_ARGUMENT,
	NOT_FOUND,
	ALREADY_EXISTS,
	CAPACITY_REACHED,
	INVARIANT_FAILURE,
	TRANSACTION_FAILED,
	TRANSACTION_CLOSED,
}

var code: Code
var command_id: StringName
var message: String
var did_change: bool


func _init(p_code: Code, p_command_id: StringName, p_message: String, p_did_change: bool) -> void:
	code = p_code
	command_id = p_command_id
	message = p_message
	did_change = p_did_change


static func success(p_command_id: StringName, p_message: String = "state changed") -> CommandResult:
	return CommandResult.new(Code.OK, p_command_id, p_message, true)


static func failure(p_code: Code, p_command_id: StringName, p_message: String) -> CommandResult:
	return CommandResult.new(p_code, p_command_id, p_message, false)


func is_success() -> bool:
	return code == Code.OK
