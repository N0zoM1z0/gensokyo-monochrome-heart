class_name BulletPatternLabResult
extends RefCounted
## Typed M11 result for a data-only bullet-pattern draft and simulation evidence.

var pattern_path: String
var definition: DanmakuPatternDefinition
var output: String
var errors: Array[String] = []


func is_valid() -> bool:
	return errors.is_empty() and definition != null


func human_readable() -> String:
	var pattern_id := definition.id if definition != null else &""
	var lines: PackedStringArray = [
		"BULLET PATTERN LAB pattern=%s path=%s errors=%d" % [pattern_id, pattern_path, errors.size()]
	]
	for error: String in errors:
		lines.append("ERROR %s" % error)
	return "\n".join(lines)
