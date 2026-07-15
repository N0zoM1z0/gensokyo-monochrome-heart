class_name CharacterAuthoringResult
extends RefCounted
## Typed result shared by the M11 character skills browser and output validator.

var character_id: StringName
var source_path: String
var output: String
var errors: Array[String] = []
var warnings: Array[String] = []


func is_valid() -> bool:
	return errors.is_empty()


func human_readable() -> String:
	var lines: PackedStringArray = [
		"CHARACTER AUTHORING character=%s errors=%d warnings=%d source=%s"
		% [character_id, errors.size(), warnings.size(), source_path]
	]
	for error: String in errors:
		lines.append("ERROR %s" % error)
	for warning: String in warnings:
		lines.append("WARNING %s" % warning)
	return "\n".join(lines)
