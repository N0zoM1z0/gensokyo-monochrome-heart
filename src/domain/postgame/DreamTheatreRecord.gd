class_name DreamTheatreRecord
extends RefCounted
## Explicit continuity and progression policy for the postgame dream stage.

var id: StringName
var location_id: StringName
var continuity_scope: StringName
var postgame_only: bool
var route_progression: bool
var fanon_ceiling: int
var label_en: String
var label_ja: String


func label(locale: StringName) -> String:
	return label_ja if locale == &"ja" else label_en
