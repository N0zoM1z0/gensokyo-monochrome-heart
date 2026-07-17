class_name ProductionAdaptiveMusicPlayer
extends Node
## Synchronized three-stem playback for the five reviewed M16 music families.

signal music_state_changed(state_id: StringName)

const SILENT_DB := -80.0
const DEFAULT_BAR_SECONDS := 2.4
const STEM_ROLES: Array[StringName] = [&"place", &"person", &"incident"]
const FAMILY_DEFINITIONS := {
	&"hakurei_shrine": {
		"bpm": 100.0,
		"place": "res://assets/audio/production/music/hakurei_shrine_place.wav",
		"person": "res://assets/audio/production/music/hakurei_shrine_person.wav",
		"incident": "res://assets/audio/production/music/hakurei_shrine_incident.wav",
	},
	&"scarlet_devil_mansion": {
		"bpm": 90.0,
		"place": "res://assets/audio/production/music/scarlet_devil_mansion_place.wav",
		"person": "res://assets/audio/production/music/scarlet_devil_mansion_person.wav",
		"incident": "res://assets/audio/production/music/scarlet_devil_mansion_incident.wav",
	},
	&"youkai_mountain": {
		"bpm": 120.0,
		"place": "res://assets/audio/production/music/youkai_mountain_place.wav",
		"person": "res://assets/audio/production/music/youkai_mountain_person.wav",
		"incident": "res://assets/audio/production/music/youkai_mountain_incident.wav",
	},
	&"eientei_bamboo": {
		"bpm": 105.0,
		"place": "res://assets/audio/production/music/eientei_bamboo_place.wav",
		"person": "res://assets/audio/production/music/eientei_bamboo_person.wav",
		"incident": "res://assets/audio/production/music/eientei_bamboo_incident.wav",
	},
	&"hakugyokurou": {
		"bpm": 84.0,
		"place": "res://assets/audio/production/music/hakugyokurou_place.wav",
		"person": "res://assets/audio/production/music/hakugyokurou_person.wav",
		"incident": "res://assets/audio/production/music/hakugyokurou_incident.wav",
	},
}
const FAMILY_STATES := {
	&"hakurei_shrine": [
		&"mus_shrine_day", &"mus_reimu_private", &"mus_marisa_arrival",
		&"mus_shrine_duel", &"mus_border_crossing",
	],
	&"scarlet_devil_mansion": [
		&"mus_sdm_foyer", &"mus_meiling_gate", &"mus_library",
		&"mus_patchouli_route", &"mus_sakuya_clock", &"mus_sakuya_kitchen",
		&"mus_remilia_route", &"mus_flandre_event",
	],
	&"youkai_mountain": [
		&"mus_mountain_base", &"mus_nitori_workshop", &"mus_hina_event",
		&"mus_aya_chase", &"mus_aya_afterbeat",
	],
	&"eientei_bamboo": [
		&"mus_bamboo_forest", &"mus_tewi_shortcut", &"mus_reisen_wave",
		&"mus_eirin_lab", &"mus_eirin_route", &"mus_kaguya_errands",
		&"mus_kaguya_afterbeat", &"mus_mokou_firepath", &"mus_false_moon",
	],
	&"hakugyokurou": [
		&"mus_hakugyokurou", &"mus_youmu_training", &"mus_youmu_afterbeat",
		&"mus_yuyuko_banquet", &"mus_yuyuko_private", &"mus_yukari_private",
	],
}
const PERSON_STATES: Array[StringName] = [
	&"mus_reimu_private", &"mus_patchouli_route", &"mus_remilia_route",
	&"mus_aya_afterbeat", &"mus_eirin_route", &"mus_kaguya_afterbeat",
	&"mus_youmu_afterbeat", &"mus_yuyuko_private", &"mus_yukari_private",
]
const INCIDENT_STATES: Array[StringName] = [
	&"mus_border_crossing", &"mus_marisa_arrival", &"mus_shrine_duel",
	&"mus_meiling_gate", &"mus_sakuya_clock", &"mus_sakuya_kitchen",
	&"mus_flandre_event", &"mus_hina_event", &"mus_aya_chase",
	&"mus_reisen_wave", &"mus_mokou_firepath", &"mus_false_moon",
	&"mus_youmu_training",
]
const ROLE_OFFSETS := {
	&"place": {&"place": 0.0, &"person": -14.0, &"incident": -20.0},
	&"person": {&"place": -8.0, &"person": 0.0, &"incident": -13.0},
	&"incident": {&"place": -9.0, &"person": -7.0, &"incident": 0.0},
}

var current_state_id: StringName
var queued_state_id: StringName
var current_family_id: StringName
var bar_elapsed_seconds: float = 0.0
var transition_count: int = 0
var family_restart_count: int = 0
var is_muted: bool = false
var is_dialogue_ducked: bool = false
var is_mono_audio: bool = false
var is_low_dynamic_range: bool = false
var volume_db: float = AudioMixPolicy.MUSIC_DB

var _players: Dictionary[StringName, AudioStreamPlayer] = {}


func _ready() -> void:
	_ensure_players()
	_connect_audio_settings()
	_update_mix()
	set_process(true)


func _process(delta: float) -> void:
	_advance(maxf(0.0, delta))


func request_state(state_id: StringName) -> bool:
	if family_for_state(state_id) == &"":
		return false
	if current_state_id == &"":
		_apply_state(state_id)
	elif state_id == current_state_id:
		queued_state_id = &""
	else:
		queued_state_id = state_id
	return true


func set_music_muted(enabled: bool) -> void:
	is_muted = enabled
	_update_mix()


func set_dialogue_ducked(enabled: bool) -> void:
	is_dialogue_ducked = enabled
	_update_mix()


func set_audio_accessibility(mono_enabled: bool, low_dynamic_enabled: bool) -> void:
	is_mono_audio = mono_enabled
	is_low_dynamic_range = low_dynamic_enabled
	_update_mix()


func stop_music() -> void:
	for player: AudioStreamPlayer in _players.values():
		player.stop()
		player.stream = null
	current_state_id = &""
	queued_state_id = &""
	current_family_id = &""
	bar_elapsed_seconds = 0.0


func advance_for_test(delta: float) -> void:
	_advance(maxf(0.0, delta))


func current_bar_seconds() -> float:
	return bar_seconds_for_family(current_family_id)


func stem_path(role: StringName) -> String:
	if current_family_id == &"":
		return ""
	return String(FAMILY_DEFINITIONS[current_family_id].get(role, ""))


func stem_volume_db(role: StringName) -> float:
	_ensure_players()
	return _players[role].volume_db if _players.has(role) else SILENT_DB


static func family_for_state(state_id: StringName) -> StringName:
	for family_id: StringName in FAMILY_STATES:
		if state_id in FAMILY_STATES[family_id]:
			return family_id
	return &""


static func bar_seconds_for_family(family_id: StringName) -> float:
	if not FAMILY_DEFINITIONS.has(family_id):
		return DEFAULT_BAR_SECONDS
	return 240.0 / float(FAMILY_DEFINITIONS[family_id].get("bpm", 100.0))


static func mix_profile_for_state(state_id: StringName) -> StringName:
	if state_id in INCIDENT_STATES:
		return &"incident"
	if state_id in PERSON_STATES:
		return &"person"
	return &"place"


func _advance(delta: float) -> void:
	if current_state_id == &"":
		return
	bar_elapsed_seconds += delta
	var bar_seconds := current_bar_seconds()
	while bar_elapsed_seconds >= bar_seconds:
		bar_elapsed_seconds -= bar_seconds
		if queued_state_id != &"":
			var next_state := queued_state_id
			queued_state_id = &""
			_apply_state(next_state)
			break


func _apply_state(state_id: StringName) -> void:
	var next_family := family_for_state(state_id)
	if next_family == &"":
		return
	_ensure_players()
	var changes_family := current_family_id != next_family
	current_state_id = state_id
	current_family_id = next_family
	bar_elapsed_seconds = 0.0
	transition_count += 1
	if changes_family:
		family_restart_count += 1
		_load_family(next_family)
	_update_mix()
	music_state_changed.emit(state_id)


func _ensure_players() -> void:
	if not _players.is_empty():
		return
	for role: StringName in STEM_ROLES:
		var player := AudioStreamPlayer.new()
		player.name = StringName("%sStem" % String(role).capitalize())
		player.bus = &"Music"
		_players[role] = player
		add_child(player)


func _load_family(family_id: StringName) -> void:
	var definition: Dictionary = FAMILY_DEFINITIONS[family_id]
	var can_play := DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() != "Dummy"
	for role: StringName in STEM_ROLES:
		var player := _players[role]
		player.stop()
		player.stream = ResourceLoader.load(String(definition[role])) as AudioStream
		if can_play and player.stream != null:
			player.play(0.0)


func _update_mix() -> void:
	volume_db = SILENT_DB if is_muted else AudioMixPolicy.music_gain_db(
		is_dialogue_ducked,
		is_low_dynamic_range
	)
	if _players.is_empty():
		return
	var profile := mix_profile_for_state(current_state_id)
	var offsets: Dictionary = ROLE_OFFSETS[profile]
	for role: StringName in STEM_ROLES:
		_players[role].volume_db = SILENT_DB if is_muted else volume_db + AudioMixPolicy.music_stem_offset_db(
			float(offsets[role]),
			is_low_dynamic_range
		)


func _connect_audio_settings() -> void:
	var settings := get_node_or_null("/root/SettingsService")
	if settings == null:
		return
	set_audio_accessibility(settings.is_mono_audio, settings.is_low_dynamic_range)
	if not settings.audio_settings_changed.is_connected(_on_audio_settings_changed):
		settings.audio_settings_changed.connect(_on_audio_settings_changed)


func _on_audio_settings_changed() -> void:
	var settings := get_node_or_null("/root/SettingsService")
	if settings != null:
		set_audio_accessibility(settings.is_mono_audio, settings.is_low_dynamic_range)


func _exit_tree() -> void:
	stop_music()
	_players.clear()
