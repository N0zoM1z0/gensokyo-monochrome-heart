class_name GameStateInspectionReport
extends RefCounted
## Stable developer-readable state report; never consumed by player presentation.

var source_label: String = "runtime"
var profile_id: StringName
var schema_version: int = 0
var is_valid: bool = false
var summary_lines: Array[String] = []
var hidden_facet_lines: Array[String] = []
var errors: Array[String] = []


func human_readable() -> String:
	var lines: Array[String] = [
		"GMH GAMESTATE INSPECTOR",
		"SOURCE %s" % source_label,
		"VALID %s" % ("yes" if is_valid else "no"),
	]
	lines.append_array(summary_lines)
	if not hidden_facet_lines.is_empty():
		lines.append("DEV-ONLY HIDDEN FACETS — NEVER PLAYER UI")
		lines.append_array(hidden_facet_lines)
	for error: String in errors:
		lines.append("ERROR %s" % error)
	return "\n".join(lines)
