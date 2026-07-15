class_name VerticalSliceTelemetry
extends RefCounted
## In-process acceptance evidence written only to the local user-data directory.

const SCHEMA_ID := "gmh-vertical-slice-telemetry-v1"
const DEFAULT_PATH := "user://telemetry/vertical_slice_latest.json"

var records: Array[AcceptanceTelemetryRecord] = []
var profile_id: StringName
var content_revision: StringName
var content_hash: String
var build_channel: StringName
var engine_version: String
var started_at_ms: int = 0
var completed: bool = false

var _active_phase_id: StringName
var _active_phase_started_at_ms: int = 0


func begin_session(
	p_profile_id: StringName,
	p_content_revision: StringName,
	p_content_hash: String,
	now_ms: int = -1
) -> void:
	records.clear()
	profile_id = p_profile_id
	content_revision = p_content_revision
	content_hash = p_content_hash
	build_channel = BuildChannel.display_name(BuildChannel.current())
	engine_version = String(Engine.get_version_info().get("string", "unknown"))
	started_at_ms = _now_ms(now_ms)
	completed = false
	_active_phase_id = &""
	_active_phase_started_at_ms = started_at_ms
	_append(&"session_start", &"boot", &"", 0, 0, false)


func enter_phase(phase_id: StringName, now_ms: int = -1, is_replay: bool = false) -> void:
	var timestamp := _now_ms(now_ms)
	if _active_phase_id != &"":
		exit_phase(_active_phase_id, timestamp, is_replay)
	_active_phase_id = phase_id
	_active_phase_started_at_ms = timestamp
	_append(&"phase_enter", phase_id, &"", 0, 0, is_replay)


func exit_phase(phase_id: StringName, now_ms: int = -1, is_replay: bool = false) -> void:
	if phase_id == &"" or phase_id != _active_phase_id:
		return
	var timestamp := _now_ms(now_ms)
	_append(
		&"phase_exit",
		phase_id,
		&"",
		maxi(0, timestamp - _active_phase_started_at_ms),
		0,
		is_replay
	)
	_active_phase_id = &""
	_active_phase_started_at_ms = timestamp


func record_mode_result(
	mode_id: StringName,
	result: ModeResult,
	elapsed_ms: int,
	is_replay: bool = false
) -> void:
	if result == null:
		return
	var attempts := 0
	if result.telemetry != null:
		attempts = result.telemetry.attempt_count
	_append(
		&"mode_result",
		mode_id,
		result.result_tag,
		maxi(0, elapsed_ms),
		attempts,
		is_replay
	)


func complete_session(now_ms: int = -1, is_replay: bool = false) -> void:
	var timestamp := _now_ms(now_ms)
	if _active_phase_id != &"":
		exit_phase(_active_phase_id, timestamp, is_replay)
	completed = true
	_append(
		&"session_complete",
		&"complete",
		&"complete",
		maxi(0, timestamp - started_at_ms),
		0,
		is_replay
	)


func to_data() -> Dictionary:
	var serialized_records: Array[Dictionary] = []
	for record: AcceptanceTelemetryRecord in records:
		serialized_records.append(record.to_data())
	return {
		"build_channel": String(build_channel),
		"completed": completed,
		"content_hash": content_hash,
		"content_revision": String(content_revision),
		"engine_version": engine_version,
		"profile_id": String(profile_id),
		"records": serialized_records,
		"schema": SCHEMA_ID,
	}


func write_local(path: String = DEFAULT_PATH) -> AtomicWriteResult:
	var payload := "%s\n" % CanonicalJson.stringify(to_data())
	return AtomicFileWriter.new().write_text(
		path,
		"%s.bak" % path,
		payload,
		_verify_document
	)


func _append(
	kind: StringName,
	phase_id: StringName,
	result_tag: StringName,
	elapsed_ms: int,
	attempt_count: int,
	is_replay: bool
) -> void:
	var record := AcceptanceTelemetryRecord.new()
	record.sequence = records.size()
	record.kind = kind
	record.phase_id = phase_id
	record.result_tag = result_tag
	record.elapsed_ms = elapsed_ms
	record.attempt_count = attempt_count
	record.is_replay = is_replay
	records.append(record)


func _verify_document(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return (
		parsed is Dictionary
		and parsed.get("schema", "") == SCHEMA_ID
		and parsed.get("records", null) is Array
	)


func _now_ms(override_ms: int) -> int:
	return override_ms if override_ms >= 0 else Time.get_ticks_msec()
