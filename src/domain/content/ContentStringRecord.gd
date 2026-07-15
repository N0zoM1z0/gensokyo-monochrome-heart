class_name ContentStringRecord
extends RefCounted
## Bilingual authored text plus its layout and provenance metadata.

var key: StringName
var context: StringName
var speaker: String
var english: String
var japanese: String
var maximum_width_px: int
var origin: StringName
var source_path: String


func _init(
	p_key: StringName,
	p_context: StringName,
	p_speaker: String,
	p_english: String,
	p_japanese: String,
	p_maximum_width_px: int,
	p_origin: StringName,
	p_source_path: String = ""
) -> void:
	key = p_key
	context = p_context
	speaker = p_speaker
	english = p_english
	japanese = p_japanese
	maximum_width_px = p_maximum_width_px
	origin = p_origin
	source_path = p_source_path


func resolve(locale: StringName) -> String:
	return japanese if locale == &"ja" else english
