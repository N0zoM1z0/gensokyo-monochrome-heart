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
var supplemental_event_paths: Array[String] = []
var supplemental_dialogue_paths: Array[String] = []
var supplemental_localization_paths: Array[String] = []
var supplemental_ui_localization_paths: Array[String] = []
var supplemental_music_cue_paths: Array[String] = []
var supplemental_deferred_reference_paths: Array[String] = []


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
	paths.append_array(supplemental_dialogue_paths)
	paths.append_array(supplemental_localization_paths)
	paths.append_array(supplemental_ui_localization_paths)
	paths.append_array(supplemental_music_cue_paths)
	paths.append_array(supplemental_deferred_reference_paths)
	paths.sort()
	return paths
