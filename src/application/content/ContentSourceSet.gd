class_name ContentSourceSet
extends RefCounted
## Reviewable set of source paths, overridable by isolated failure fixtures.

var manifest_path: String = "res://content/indexes/design_content_index.json"
var characters_path: String = "res://content/characters/characters.json"
var locations_path: String = "res://content/locations/locations.json"
var events_path: String = "res://content/events/events.json"
var event_graph_path: String = "res://content/events/sample_event_empty_cushion.json"
var dialogue_path: String = "res://content/dialogue/dialogue_samples.json"
var localization_path: String = "res://content/localization/strings.csv"
var ui_localization_path: String = "res://content/localization/ui_strings.json"
var music_cues_path: String = "res://content/music/music_cues.csv"
var deferred_references_path: String = "res://content/indexes/deferred_references.json"
var character_schema_path: String = "res://schemas/character_index.schema.json"
var location_schema_path: String = "res://schemas/location_index.schema.json"
var event_schema_path: String = "res://schemas/event_index.schema.json"
var event_graph_schema_path: String = "res://schemas/event_graph.schema.json"
var dialogue_schema_path: String = "res://schemas/dialogue_index.schema.json"
var ui_localization_schema_path: String = "res://schemas/ui_localization.schema.json"
var enforce_manifest_counts: bool = true
var supplemental_character_paths: Array[String] = []
var supplemental_location_paths: Array[String] = []
var supplemental_event_paths: Array[String] = [
	"res://content/events/hkr_route_events.json",
]
var supplemental_event_graph_paths: Array[String] = [
	"res://content/events/hkr_day_nothing_happens.json",
	"res://content/events/hkr_offerings_without_owners.json",
	"res://content/events/hkr_shrine_not_guesthouse.json",
	"res://content/events/sdm_late_by_three_minutes.json",
	"res://content/events/mtn_tomorrows_headline.json",
]
var supplemental_dialogue_paths: Array[String] = [
	"res://content/dialogue/hkr_day_nothing_happens.json",
	"res://content/dialogue/hkr_offerings_without_owners.json",
	"res://content/dialogue/hkr_shrine_not_guesthouse.json",
	"res://content/dialogue/sdm_late_by_three_minutes.json",
	"res://content/dialogue/mtn_tomorrows_headline.json",
]
var supplemental_localization_paths: Array[String] = [
	"res://content/localization/hkr_day_nothing_happens.csv",
	"res://content/localization/hkr_offerings_without_owners.csv",
	"res://content/localization/hkr_shrine_not_guesthouse.csv",
	"res://content/localization/sdm_late_by_three_minutes.csv",
	"res://content/localization/mtn_tomorrows_headline.csv",
	"res://content/localization/ein_four_dawns.csv",
]
var supplemental_ui_localization_paths: Array[String] = []
var supplemental_music_cue_paths: Array[String] = []
var supplemental_deferred_reference_paths: Array[String] = [
	"res://content/indexes/hkr_route_deferred_references.json",
	"res://content/indexes/sdm_deferred_references.json",
	"res://content/indexes/mtn_deferred_references.json",
]
var expected_supplemental_event_count: int = 2
var expected_supplemental_dialogue_count: int = 60
var expected_supplemental_localization_count: int = 103


func content_paths() -> Array[String]:
	var paths: Array[String] = [
		manifest_path,
		characters_path,
		locations_path,
		events_path,
		event_graph_path,
		dialogue_path,
		localization_path,
		ui_localization_path,
		music_cues_path,
		deferred_references_path,
	]
	paths.append_array(supplemental_character_paths)
	paths.append_array(supplemental_location_paths)
	paths.append_array(supplemental_event_paths)
	paths.append_array(supplemental_event_graph_paths)
	paths.append_array(supplemental_dialogue_paths)
	paths.append_array(supplemental_localization_paths)
	paths.append_array(supplemental_ui_localization_paths)
	paths.append_array(supplemental_music_cue_paths)
	paths.append_array(supplemental_deferred_reference_paths)
	paths.sort()
	return paths
