class_name DanmakuPatternDefinition
extends RefCounted
## Typed three-phase boundary encounter loaded from reviewable JSON data.

var schema_version: int = 1
var id: StringName
var title_key: StringName
var arena_width: int = 224
var arena_height: int = 152
var phases: Array[DanmakuPhaseDefinition] = []
var source_path: String
var data_hash: String


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if schema_version != 1:
		errors.append("unsupported danmaku pattern schema version: %d" % schema_version)
	if not String(id).begins_with("danmaku."):
		errors.append("danmaku pattern ID must begin with danmaku.: %s" % id)
	if title_key == &"":
		errors.append("danmaku pattern requires a localized title key")
	if arena_width < 160 or arena_height < 120:
		errors.append("danmaku arena is smaller than the supported playfield")
	if phases.size() != 3:
		errors.append("boundary-stain fixture requires exactly three phases")
	var ids := {}
	for phase: DanmakuPhaseDefinition in phases:
		if ids.has(phase.id):
			errors.append("duplicate danmaku phase ID: %s" % phase.id)
		ids[phase.id] = true
		for error: String in phase.validation_errors():
			errors.append(error)
	return errors


func phase(index: int) -> DanmakuPhaseDefinition:
	return phases[index] if index >= 0 and index < phases.size() else null


func emitter_signature() -> PackedStringArray:
	var result := PackedStringArray()
	for phase_definition: DanmakuPhaseDefinition in phases:
		for emitter: DanmakuEmitterDefinition in phase_definition.emitters:
			result.append("%s:%s:%d" % [phase_definition.id, emitter.pattern_type, emitter.family])
	return result
