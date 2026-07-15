class_name ContentLoadReport
extends RefCounted
## Aggregated M02 report with stable stages, hash, counts, and source diagnostics.

var content_revision: StringName = &"unknown"
var content_hash: String = ""
var stages: Array[ContentStageResult] = []
var diagnostics: Array[ContentDiagnostic] = []
var character_count: int = 0
var location_count: int = 0
var event_count: int = 0
var dialogue_count: int = 0
var localization_count: int = 0
var music_cue_count: int = 0
var event_node_count: int = 0


func record_check(stage_id: StringName, amount: int = 1) -> void:
	_stage(stage_id).checks += amount


func add_error(
	stage_id: StringName,
	source: String,
	message: String,
	owner_id: StringName = &""
) -> void:
	diagnostics.append(ContentDiagnostic.new(ContentDiagnostic.ERROR, stage_id, source, message, owner_id))
	_stage(stage_id).errors += 1


func add_warning(
	stage_id: StringName,
	source: String,
	message: String,
	owner_id: StringName = &""
) -> void:
	diagnostics.append(ContentDiagnostic.new(ContentDiagnostic.WARNING, stage_id, source, message, owner_id))
	_stage(stage_id).warnings += 1


func add_note(stage_id: StringName, source: String, message: String) -> void:
	diagnostics.append(ContentDiagnostic.new(ContentDiagnostic.NOTE, stage_id, source, message))


func error_count() -> int:
	var result := 0
	for stage: ContentStageResult in stages:
		result += stage.errors
	return result


func warning_count() -> int:
	var result := 0
	for stage: ContentStageResult in stages:
		result += stage.warnings
	return result


func is_success() -> bool:
	return error_count() == 0


func summary_line() -> String:
	return (
		"ContentDB: revision=%s hash=%s characters=%d locations=%d events=%d beats=%d strings=%d cues=%d nodes=%d errors=%d warnings=%d"
		% [
			content_revision,
			content_hash,
			character_count,
			location_count,
			event_count,
			dialogue_count,
			localization_count,
			music_cue_count,
			event_node_count,
			error_count(),
			warning_count(),
		]
	)


func human_readable() -> String:
	var lines: PackedStringArray = [summary_line()]
	for stage: ContentStageResult in stages:
		lines.append(
			"STAGE %s checks=%d errors=%d warnings=%d"
			% [stage.id, stage.checks, stage.errors, stage.warnings]
		)
	for diagnostic: ContentDiagnostic in diagnostics:
		lines.append(diagnostic.format_line())
	return "\n".join(lines)


func _stage(stage_id: StringName) -> ContentStageResult:
	for stage: ContentStageResult in stages:
		if stage.id == stage_id:
			return stage
	var created := ContentStageResult.new(stage_id)
	stages.append(created)
	return created
