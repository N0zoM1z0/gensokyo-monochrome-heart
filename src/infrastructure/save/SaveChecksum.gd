class_name SaveChecksum
extends RefCounted
## Integrity hash binds schema, profile, and canonical payload together.


static func compute(schema_version: int, profile_id: StringName, payload: Dictionary) -> String:
	return "sha256:%s" % CanonicalJson.sha256(
		{
			"schema_version": schema_version,
			"profile_id": String(profile_id),
			"payload": payload,
		}
	)


static func matches(
	checksum: String,
	schema_version: int,
	profile_id: StringName,
	payload: Dictionary
) -> bool:
	return checksum == compute(schema_version, profile_id, payload)
