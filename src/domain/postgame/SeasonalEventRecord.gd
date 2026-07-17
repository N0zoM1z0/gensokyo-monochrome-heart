class_name SeasonalEventRecord
extends RefCounted
## Bilingual, continuity-scoped seed for reusable postgame seasonal scheduling.

var id: StringName
var season: StringName
var title_en: String
var title_ja: String
var event_hook: String
var music_cue_id: StringName
var continuity_scope: StringName
var relationship_progression: StringName


func title(locale: StringName) -> String:
	return title_ja if locale == &"ja" else title_en
