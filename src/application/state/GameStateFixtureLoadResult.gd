class_name GameStateFixtureLoadResult
extends RefCounted
## Read-only developer fixture outcome with path-safe diagnostics.

enum Code {
	OK,
	NOT_FOUND,
	PARSE_ERROR,
	UNSUPPORTED_FORMAT,
	CHECKSUM_ERROR,
	MIGRATION_ERROR,
	FUTURE_VERSION,
	INVALID_STATE,
}

var code: Code = Code.OK
var source_label: String = "memory"
var state: GameState
var was_migrated: bool = false
var errors: Array[String] = []


func is_success() -> bool:
	return code == Code.OK and state != null
