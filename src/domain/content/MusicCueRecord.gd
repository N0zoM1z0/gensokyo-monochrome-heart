class_name MusicCueRecord
extends RefCounted
## Typed row from the reviewed 89-cue music direction table.

var id: StringName
var section: StringName
var scene_or_system: String
var mood_function: String
var touhou_reference_en: String
var touhou_reference_ja: String
var source_work: String
var arrangement_brief: String
var loops: bool
var priority: StringName
var source_path: String


func _init(
	p_id: StringName,
	p_section: StringName,
	p_scene_or_system: String,
	p_mood_function: String,
	p_touhou_reference_en: String,
	p_touhou_reference_ja: String,
	p_source_work: String,
	p_arrangement_brief: String,
	p_loops: bool,
	p_priority: StringName,
	p_source_path: String = ""
) -> void:
	id = p_id
	section = p_section
	scene_or_system = p_scene_or_system
	mood_function = p_mood_function
	touhou_reference_en = p_touhou_reference_en
	touhou_reference_ja = p_touhou_reference_ja
	source_work = p_source_work
	arrangement_brief = p_arrangement_brief
	loops = p_loops
	priority = p_priority
	source_path = p_source_path
