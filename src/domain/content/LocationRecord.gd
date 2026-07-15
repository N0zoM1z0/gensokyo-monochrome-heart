class_name LocationRecord
extends RefCounted
## Typed map-region metadata with an integer logical-canvas position.

var id: StringName
var display_name_en: String
var display_name_ja: String
var bible_path: String
var map_position: Vector2i
var thesis: String
var launch_tier: StringName
var source_path: String


func _init(
	p_id: StringName,
	p_display_name_en: String,
	p_display_name_ja: String,
	p_bible_path: String,
	p_map_position: Vector2i,
	p_thesis: String,
	p_launch_tier: StringName,
	p_source_path: String = ""
) -> void:
	id = p_id
	display_name_en = p_display_name_en
	display_name_ja = p_display_name_ja
	bible_path = p_bible_path
	map_position = p_map_position
	thesis = p_thesis
	launch_tier = p_launch_tier
	source_path = p_source_path


func display_name(locale: StringName) -> String:
	return display_name_ja if locale == &"ja" and not display_name_ja.is_empty() else display_name_en
