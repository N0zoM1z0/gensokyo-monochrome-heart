class_name WorkbenchResult
extends RefCounted
## Typed report for M11 workbench discovery, inspection, and smoke launch.

var target: WorkbenchTarget
var output: String
var errors: Array[String] = []


func is_valid() -> bool:
	return errors.is_empty()


func human_readable() -> String:
	var target_id := target.id if target != null else &""
	var lines: PackedStringArray = ["M11 WORKBENCH target=%s errors=%d" % [target_id, errors.size()]]
	for error: String in errors:
		lines.append("ERROR %s" % error)
	return "\n".join(lines)
