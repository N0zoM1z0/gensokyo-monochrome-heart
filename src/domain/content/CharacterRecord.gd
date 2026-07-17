class_name CharacterRecord
extends RefCounted
## Immutable runtime-facing character metadata parsed from the reviewed index.

var id: StringName
var slug: StringName
var display_name_en: String
var display_name_ja: String
var faction_region: String
var route_depth: StringName
var route_scope_note: String
var canon_confidence: StringName
var skills_document: String
var tags: Array[StringName]
var presence_tier: StringName
var relationship_scope: StringName
var agency_anchor: String
var event_hooks: Array[String]
var companion_skill: CompanionSkillRecord
var danmaku_role: StringName
var source_path: String


func _init(
	p_id: StringName,
	p_slug: StringName,
	p_display_name_en: String,
	p_display_name_ja: String,
	p_faction_region: String,
	p_route_depth: StringName,
	p_route_scope_note: String,
	p_canon_confidence: StringName,
	p_skills_document: String,
	p_tags: Array[StringName],
	p_presence_tier: StringName,
	p_relationship_scope: StringName,
	p_agency_anchor: String,
	p_event_hooks: Array[String],
	p_companion_skill: CompanionSkillRecord,
	p_danmaku_role: StringName,
	p_source_path: String = ""
) -> void:
	id = p_id
	slug = p_slug
	display_name_en = p_display_name_en
	display_name_ja = p_display_name_ja
	faction_region = p_faction_region
	route_depth = p_route_depth
	route_scope_note = p_route_scope_note
	canon_confidence = p_canon_confidence
	skills_document = p_skills_document
	tags = p_tags.duplicate()
	presence_tier = p_presence_tier
	relationship_scope = p_relationship_scope
	agency_anchor = p_agency_anchor
	event_hooks = p_event_hooks.duplicate()
	companion_skill = p_companion_skill
	danmaku_role = p_danmaku_role
	source_path = p_source_path


func display_name(locale: StringName) -> String:
	return display_name_ja if locale == &"ja" and not display_name_ja.is_empty() else display_name_en
