class_name SaveMigrator
extends RefCounted
## Ordered pure migration chain; unknown future saves are never downgraded.


func migrate(payload: Variant) -> SaveMigrationResult:
	var result := SaveMigrationResult.new()
	if not payload is Dictionary:
		result.errors.append("save payload must be an object before migration")
		return result
	var working: Dictionary = payload.duplicate(true)
	var version := int(working.get("schema_version", 0))
	result.source_version = version
	if version > GameState.CURRENT_SCHEMA_VERSION:
		result.payload = working
		result.target_version = version
		result.is_future_version = true
		result.errors.append(
			"save schema %d is newer than supported schema %d; open read-only diagnostic only"
			% [version, GameState.CURRENT_SCHEMA_VERSION]
		)
		return result
	if version < 1:
		result.errors.append("save payload has no supported schema version")
		return result
	var was_migrated := false
	while version < GameState.CURRENT_SCHEMA_VERSION:
		var step_result: SaveMigrationResult
		match version:
			1:
				step_result = SaveMigrationV1ToV2.new().migrate(working)
			_:
				result.errors.append("no migration step exists for schema %d" % version)
				return result
		if not step_result.is_success():
			result.errors.append_array(step_result.errors)
			return result
		working = step_result.payload
		version = step_result.target_version
		was_migrated = true
	result.payload = working
	result.target_version = version
	result.was_migrated = was_migrated
	return result
