class_name ContentDiagnostic
extends RefCounted
## One source-located human-readable content loading diagnostic.

const ERROR: StringName = &"error"
const WARNING: StringName = &"warning"
const NOTE: StringName = &"note"

var severity: StringName
var stage: StringName
var source: String
var owner_id: StringName
var message: String


func _init(
	p_severity: StringName,
	p_stage: StringName,
	p_source: String,
	p_message: String,
	p_owner_id: StringName = &""
) -> void:
	severity = p_severity
	stage = p_stage
	source = p_source
	message = p_message
	owner_id = p_owner_id


func format_line() -> String:
	var owner := " owner=%s" % owner_id if owner_id != &"" else ""
	return "%s [%s] %s%s: %s" % [String(severity).to_upper(), stage, source, owner, message]
