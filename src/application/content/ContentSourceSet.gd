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
	"res://content/events/mrs_route_events.json",
	"res://content/events/sdm_route_events.json",
]
var supplemental_event_graph_paths: Array[String] = [
	"res://content/events/hkr_day_nothing_happens.json",
	"res://content/events/hkr_offerings_without_owners.json",
	"res://content/events/hkr_shrine_not_guesthouse.json",
	"res://content/events/hkr_unasked_rescue.json",
	"res://content/events/hkr_perfectly_recorded_tea.json",
	"res://content/events/hkr_promise.json",
	"res://content/events/mrs_crash_landing.json",
	"res://content/events/mrs_field_notes.json",
	"res://content/events/mrs_shelf_marked_later.json",
	"res://content/events/mrs_talent_bad_conversation.json",
	"res://content/events/mrs_rescue_looks_like_race.json",
	"res://content/events/mrs_infinite_experiment.json",
	"res://content/events/mrs_promise.json",
	"res://content/events/sdm_late_by_three_minutes.json",
	"res://content/events/sdm_corridor_no_dust.json",
	"res://content/events/sdm_kitchen_after_midnight.json",
	"res://content/events/sdm_competence_not_consent.json",
	"res://content/events/sdm_favor_cannot_optimize.json",
	"res://content/events/sdm_missing_minute.json",
	"res://content/events/mtn_tomorrows_headline.json",
]
var supplemental_dialogue_paths: Array[String] = [
	"res://content/dialogue/hkr_day_nothing_happens.json",
	"res://content/dialogue/hkr_offerings_without_owners.json",
	"res://content/dialogue/hkr_shrine_not_guesthouse.json",
	"res://content/dialogue/hkr_unasked_rescue.json",
	"res://content/dialogue/hkr_perfectly_recorded_tea.json",
	"res://content/dialogue/hkr_promise.json",
	"res://content/dialogue/mrs_crash_landing.json",
	"res://content/dialogue/mrs_field_notes.json",
	"res://content/dialogue/mrs_shelf_marked_later.json",
	"res://content/dialogue/mrs_talent_bad_conversation.json",
	"res://content/dialogue/mrs_rescue_looks_like_race.json",
	"res://content/dialogue/mrs_infinite_experiment.json",
	"res://content/dialogue/mrs_promise.json",
	"res://content/dialogue/sdm_late_by_three_minutes.json",
	"res://content/dialogue/sdm_corridor_no_dust.json",
	"res://content/dialogue/sdm_kitchen_after_midnight.json",
	"res://content/dialogue/sdm_competence_not_consent.json",
	"res://content/dialogue/sdm_favor_cannot_optimize.json",
	"res://content/dialogue/sdm_missing_minute.json",
	"res://content/dialogue/mtn_tomorrows_headline.json",
]
var supplemental_localization_paths: Array[String] = [
	"res://content/localization/hkr_day_nothing_happens.csv",
	"res://content/localization/hkr_offerings_without_owners.csv",
	"res://content/localization/hkr_shrine_not_guesthouse.csv",
	"res://content/localization/hkr_unasked_rescue.csv",
	"res://content/localization/hkr_perfectly_recorded_tea.csv",
	"res://content/localization/hkr_promise.csv",
	"res://content/localization/mrs_crash_landing.csv",
	"res://content/localization/mrs_field_notes.csv",
	"res://content/localization/mrs_shelf_marked_later.csv",
	"res://content/localization/mrs_talent_bad_conversation.csv",
	"res://content/localization/mrs_rescue_looks_like_race.csv",
	"res://content/localization/mrs_infinite_experiment.csv",
	"res://content/localization/mrs_promise.csv",
	"res://content/localization/sdm_late_by_three_minutes.csv",
	"res://content/localization/sdm_corridor_no_dust.csv",
	"res://content/localization/sdm_kitchen_after_midnight.csv",
	"res://content/localization/sdm_competence_not_consent.csv",
	"res://content/localization/sdm_favor_cannot_optimize.csv",
	"res://content/localization/sdm_missing_minute.csv",
	"res://content/localization/mtn_tomorrows_headline.csv",
	"res://content/localization/ein_four_dawns.csv",
]
var supplemental_ui_localization_paths: Array[String] = []
var supplemental_music_cue_paths: Array[String] = []
var supplemental_deferred_reference_paths: Array[String] = [
	"res://content/indexes/hkr_route_deferred_references.json",
	"res://content/indexes/mrs_route_deferred_references.json",
	"res://content/indexes/sdm_deferred_references.json",
	"res://content/indexes/mtn_deferred_references.json",
]
var expected_supplemental_event_count: int = 17
var expected_supplemental_dialogue_count: int = 177
var expected_supplemental_localization_count: int = 340


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
