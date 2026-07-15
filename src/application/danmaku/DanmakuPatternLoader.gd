class_name DanmakuPatternLoader
extends RefCounted
## Parses authored JSON into typed pattern records; arbitrary scripts are impossible.

const FAMILY_CODES := {
	"amulet": DanmakuBulletSpec.Family.AMULET,
	"offering": DanmakuBulletSpec.Family.OFFERING,
	"memory": DanmakuBulletSpec.Family.MEMORY,
}
const POLARITY_CODES := {
	"ink": DanmakuBulletSpec.Polarity.INK,
	"paper": DanmakuBulletSpec.Polarity.PAPER,
}

var errors: Array[String] = []


func load_path(path: String) -> DanmakuPatternDefinition:
	errors.clear()
	if not FileAccess.file_exists(path):
		errors.append("danmaku pattern file is missing: %s" % path)
		return null
	var text := FileAccess.get_file_as_string(path)
	var raw: Variant = JSON.parse_string(text)
	if not raw is Dictionary:
		errors.append("danmaku pattern root must be an object: %s" % path)
		return null
	var definition := _parse_definition(raw, path, text.sha256_text())
	errors.append_array(definition.validation_errors())
	return definition


func _parse_definition(raw: Dictionary, path: String, data_hash: String) -> DanmakuPatternDefinition:
	var definition := DanmakuPatternDefinition.new()
	definition.schema_version = int(raw.get("schema_version", 0))
	definition.id = StringName(raw.get("id", ""))
	definition.title_key = StringName(raw.get("title_key", ""))
	var arena: Variant = raw.get("arena", {})
	if arena is Dictionary:
		definition.arena_width = int(arena.get("width", 0))
		definition.arena_height = int(arena.get("height", 0))
	else:
		errors.append("danmaku arena must be an object")
	for phase_raw: Variant in raw.get("phases", []):
		if not phase_raw is Dictionary:
			errors.append("danmaku phase must be an object")
			continue
		definition.phases.append(_parse_phase(phase_raw))
	definition.source_path = path
	definition.data_hash = data_hash
	return definition


func _parse_phase(raw: Dictionary) -> DanmakuPhaseDefinition:
	var phase := DanmakuPhaseDefinition.new()
	phase.id = StringName(raw.get("id", ""))
	phase.title_key = StringName(raw.get("title_key", ""))
	phase.duration_ticks = int(raw.get("duration_ticks", 0))
	phase.boss_integrity = int(raw.get("boss_integrity", 0))
	phase.teaching_ticks = int(raw.get("teaching_ticks", 0))
	phase.transform_tick = int(raw.get("transform_tick", 0))
	phase.safe_lane = int(raw.get("safe_lane", -1))
	for emitter_raw: Variant in raw.get("emitters", []):
		if not emitter_raw is Dictionary:
			errors.append("danmaku emitter must be an object in %s" % phase.id)
			continue
		phase.emitters.append(_parse_emitter(emitter_raw))
	return phase


func _parse_emitter(raw: Dictionary) -> DanmakuEmitterDefinition:
	var emitter := DanmakuEmitterDefinition.new()
	emitter.id = StringName(raw.get("id", ""))
	emitter.pattern_type = StringName(raw.get("pattern", ""))
	emitter.start_tick = int(raw.get("start_tick", 0))
	emitter.interval_ticks = int(raw.get("interval_ticks", 0))
	emitter.volleys = int(raw.get("volleys", 0))
	emitter.slot_count = int(raw.get("slot_count", 0))
	emitter.origin_x = int(raw.get("origin_x", 112))
	emitter.origin_y = int(raw.get("origin_y", 16))
	emitter.speed_fp = roundi(float(raw.get("speed_pixels_per_tick", 1.0)) * 256.0)
	emitter.angle_millidegrees = int(raw.get("angle_millidegrees", 90000))
	emitter.telegraph_ticks = int(raw.get("telegraph_ticks", 0))
	emitter.lifetime_ticks = int(raw.get("lifetime_ticks", 600))
	var family_name := String(raw.get("family", ""))
	var polarity_name := String(raw.get("polarity", ""))
	if not FAMILY_CODES.has(family_name):
		errors.append("unknown danmaku bullet family: %s" % family_name)
	else:
		emitter.family = FAMILY_CODES[family_name]
	if not POLARITY_CODES.has(polarity_name):
		errors.append("unknown danmaku bullet polarity: %s" % polarity_name)
	else:
		emitter.polarity = POLARITY_CODES[polarity_name]
	emitter.safe_lane = int(raw.get("safe_lane", -1))
	return emitter
