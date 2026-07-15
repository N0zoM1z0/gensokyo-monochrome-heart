class_name TestSaveMigrations
extends RefCounted
## M03 pure migration chain, route-intent preservation, and future-version policy tests.

const V1_FIXTURE := "res://tests/fixtures/saves/v1_route_affinity_payload.json"


func run() -> Array[String]:
	var failures: Array[String] = []
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(V1_FIXTURE))
	if not source is Dictionary:
		return ["v1 route-affinity fixture is not valid JSON"]
	var opening := CanonicalJson.stringify(source)
	var migration := SaveMigrator.new().migrate(source)
	if not migration.is_success() or not migration.was_migrated:
		failures.append("v1->v2 migration failed: %s" % "; ".join(migration.errors))
		return failures
	if CanonicalJson.stringify(source) != opening:
		failures.append("migration mutated the source fixture")
	var decoded := GameStateCodec.new().decode(migration.payload)
	if not decoded.is_success():
		failures.append("migrated v2 payload failed typed decode: %s" % "; ".join(decoded.errors))
	else:
		var reimu := decoded.state.characters[&"char.reimu_hakurei"]
		if reimu.route_intent != &"friendship" or decoded.state.route_intent_id != &"route.hakurei.friendship":
			failures.append("v1->v2 migration did not preserve declared route intent")
		if reimu.relationship.trust != 2 or reimu.relationship.ease != 2 or reimu.relationship.respect != 2:
			failures.append("legacy affinity did not map to the documented five-facet seed")
		if reimu.relationship.spark != 0 or reimu.relationship.strain != 0:
			failures.append("friendship migration inferred romance or unresolved Strain")
	var invalid: Dictionary = source.duplicate(true)
	invalid.characters["char.reimu_hakurei"].erase("affinity")
	var invalid_result := SaveMigrator.new().migrate(invalid)
	if invalid_result.is_success() or not _contains(invalid_result.errors, "lacks legacy affinity"):
		failures.append("v1 migration accepted a character without legacy affinity")
	var future: Dictionary = source.duplicate(true)
	future.schema_version = 99
	var future_result := SaveMigrator.new().migrate(future)
	if not future_result.is_future_version or future_result.is_success() or future_result.payload.is_empty():
		failures.append("future save schema was not preserved for read-only diagnostics")
	return failures


func _contains(errors: Array[String], fragment: String) -> bool:
	for error: String in errors:
		if error.contains(fragment):
			return true
	return false
