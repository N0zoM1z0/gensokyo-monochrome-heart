class_name SaveOperationResult
extends RefCounted
## Stable expected save/load outcome with recovery and migration evidence.

enum Code {
	OK,
	INVALID_SLOT,
	INVALID_STATE,
	NOT_FOUND,
	IO_ERROR,
	VERIFY_ERROR,
	PARSE_ERROR,
	SCHEMA_ERROR,
	CHECKSUM_ERROR,
	MIGRATION_ERROR,
	FUTURE_VERSION,
}

var code: Code
var message: String
var path: String
var state: GameState
var card: SaveCardMetadata
var was_recovered_from_backup: bool = false
var was_migrated: bool = false
var created_utc: String = ""
var saved_utc: String = ""
var diagnostics: Array[String] = []


func _init(p_code: Code = Code.OK, p_message: String = "") -> void:
	code = p_code
	message = p_message


func is_success() -> bool:
	return code == Code.OK
