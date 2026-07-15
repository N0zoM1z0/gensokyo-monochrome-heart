class_name SaveMigrationV1ToV2
extends RefCounted
## Expands legacy route affinity into five facets without changing declared route intent.


func migrate(source: Dictionary) -> SaveMigrationResult:
	var result := SaveMigrationResult.new()
	result.source_version = 1
	result.target_version = 2
	if int(source.get("schema_version", 0)) != 1:
		result.errors.append("v1 migration expected schema_version=1")
		return result
	var migrated := source.duplicate(true)
	var characters: Variant = migrated.get("characters", null)
	if not characters is Dictionary:
		result.errors.append("v1 payload lacks a characters object")
		return result
	for raw_id: Variant in characters:
		var record: Variant = characters[raw_id]
		if not record is Dictionary or not record.has("affinity"):
			result.errors.append("v1 character %s lacks legacy affinity" % raw_id)
			continue
		var affinity := clampi(int(record.affinity), RelationshipFacetRules.MINIMUM_VALUE, RelationshipFacetRules.MAXIMUM_VALUE)
		var declared_intent := StringName(record.get("route_intent", "undecided"))
		record.erase("affinity")
		record["relationship"] = {
			"trust": affinity,
			"ease": maxi(0, affinity),
			"respect": maxi(0, affinity),
			"spark": 1 if declared_intent == &"romance" and affinity > 0 else 0,
			"strain": maxi(0, -affinity),
		}
	if not result.errors.is_empty():
		return result
	migrated["schema_version"] = 2
	if migrated.has("legacy_route_intent_id"):
		migrated["route_intent_id"] = migrated.legacy_route_intent_id
		migrated.erase("legacy_route_intent_id")
	elif not migrated.has("route_intent_id"):
		migrated["route_intent_id"] = "route.return_to_gensokyo"
	if not migrated.has("route_completion_ids"):
		migrated["route_completion_ids"] = []
	result.payload = migrated
	result.was_migrated = true
	return result
