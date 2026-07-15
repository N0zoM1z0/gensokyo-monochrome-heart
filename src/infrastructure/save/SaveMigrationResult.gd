class_name SaveMigrationResult
extends RefCounted
## Pure migration result; future versions retain a read-only diagnostic payload.

var payload: Dictionary = {}
var source_version: int = 0
var target_version: int = 0
var was_migrated: bool = false
var is_future_version: bool = false
var errors: Array[String] = []


func is_success() -> bool:
	return errors.is_empty() and not payload.is_empty() and target_version == GameState.CURRENT_SCHEMA_VERSION
