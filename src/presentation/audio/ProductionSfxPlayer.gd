class_name ProductionSfxPlayer
extends Node
## Production WAV resolver with per-family voice caps and oldest-voice stealing.

signal cue_played(cue_id: StringName, visual_key: StringName)

const ASSETS := {
	&"sfx.ambience.region_bed": {"path": "res://assets/audio/production/sfx/ambience_region_bed.wav", "family": &"ambience", "cap": 2, "priority": 10},
	&"sfx.bullet.group_loop": {"path": "res://assets/audio/production/sfx/bullet_group_loop.wav", "family": &"bullet_group", "cap": 1, "priority": 25},
	&"sfx.bullet.transient": {"path": "res://assets/audio/production/sfx/bullet_transient.wav", "family": &"bullet_transient", "cap": 4, "priority": 35},
	&"sfx.combat.impact": {"path": "res://assets/audio/production/sfx/combat_impact.wav", "family": &"impact", "cap": 4, "priority": 75},
	&"sfx.danmaku.graze": {"path": "res://assets/audio/production/sfx/danmaku_graze.wav", "family": &"graze", "cap": 4, "priority": 65},
	&"sfx.player.damage": {"path": "res://assets/audio/production/sfx/player_damage.wav", "family": &"player_critical", "cap": 3, "priority": 90},
	&"sfx.save.begin": {"path": "res://assets/audio/production/sfx/save_begin.wav", "family": &"save", "cap": 2, "priority": 55},
	&"sfx.save.end": {"path": "res://assets/audio/production/sfx/save_end.wav", "family": &"save", "cap": 2, "priority": 60},
	&"sfx.ui.cancel": {"path": "res://assets/audio/production/sfx/ui_cancel.wav", "family": &"ui_navigation", "cap": 3, "priority": 45},
	&"sfx.ui.confirm": {"path": "res://assets/audio/production/sfx/ui_confirm.wav", "family": &"ui_navigation", "cap": 3, "priority": 50},
	&"sfx.ui.focus": {"path": "res://assets/audio/production/sfx/ui_focus.wav", "family": &"ui_navigation", "cap": 3, "priority": 40},
	&"sfx.warning.threat": {"path": "res://assets/audio/production/sfx/warning_threat.wav", "family": &"warning", "cap": 2, "priority": 100},
}

var last_cue_id: StringName
var last_visual_key: StringName
var last_resolved_asset_id: StringName
var last_volume_db: float = AudioMixPolicy.ROLE_DB[AudioMixPolicy.Role.GAMEPLAY]
var steal_count: int = 0
var is_mono_audio: bool = false
var is_low_dynamic_range: bool = false

var _pools: Dictionary[StringName, Array] = {}
var _streams: Dictionary[StringName, AudioStream] = {}
var _voice_serials: Dictionary[int, int] = {}
var _voice_busy_until_msec: Dictionary[int, int] = {}
var _voice_assets: Dictionary[int, StringName] = {}
var _voice_roles: Dictionary[int, AudioMixPolicy.Role] = {}
var _serial: int = 0


func _ready() -> void:
	_connect_audio_settings()


func play_cue(cue: AudioCueIntent) -> void:
	if cue == null:
		return
	last_cue_id = cue.cue_id
	last_visual_key = cue.visual_key
	last_resolved_asset_id = resolve_asset_id(cue.cue_id)
	last_volume_db = AudioMixPolicy.gain_db(cue.role, last_resolved_asset_id, is_low_dynamic_range)
	var definition: Dictionary = ASSETS[last_resolved_asset_id]
	var family_id: StringName = definition.family
	if not _streams.has(last_resolved_asset_id):
		_streams[last_resolved_asset_id] = ResourceLoader.load(String(definition.path)) as AudioStream
	var voice := _select_voice(family_id, int(definition.cap))
	voice.stop()
	voice.stream = _streams[last_resolved_asset_id]
	voice.volume_db = last_volume_db
	_serial += 1
	var voice_id := voice.get_instance_id()
	_voice_serials[voice_id] = _serial
	var stream_seconds := maxf(0.05, voice.stream.get_length() if voice.stream != null else 0.05)
	_voice_busy_until_msec[voice_id] = Time.get_ticks_msec() + ceili(stream_seconds * 1000.0)
	_voice_assets[voice_id] = last_resolved_asset_id
	_voice_roles[voice_id] = cue.role
	if DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() != "Dummy" and voice.stream != null:
		voice.play()
	cue_played.emit(cue.cue_id, cue.visual_key)


func voice_count_for_family(family_id: StringName) -> int:
	return _pools.get(family_id, []).size()


func set_audio_accessibility(mono_enabled: bool, low_dynamic_enabled: bool) -> void:
	is_mono_audio = mono_enabled
	is_low_dynamic_range = low_dynamic_enabled
	for pool: Array in _pools.values():
		for voice: AudioStreamPlayer in pool:
			var voice_id := voice.get_instance_id()
			var asset_id: StringName = _voice_assets.get(voice_id, &"")
			var role: AudioMixPolicy.Role = _voice_roles.get(voice_id, AudioMixPolicy.Role.AUTO)
			if asset_id != &"":
				voice.volume_db = AudioMixPolicy.gain_db(role, asset_id, is_low_dynamic_range)
	if last_resolved_asset_id != &"":
		last_volume_db = AudioMixPolicy.gain_db(
			_voice_roles.get(_last_voice_id(), AudioMixPolicy.Role.AUTO),
			last_resolved_asset_id,
			is_low_dynamic_range
		)


static func asset_path(asset_id: StringName) -> String:
	return String(ASSETS[asset_id].path) if ASSETS.has(asset_id) else ""


static func resolve_asset_id(cue_id: StringName) -> StringName:
	if ASSETS.has(cue_id):
		return cue_id
	var cue := String(cue_id)
	if cue.contains("warning") or cue.contains("threat"):
		return &"sfx.warning.threat"
	if cue.contains("damage") or cue.contains("bomb") or cue.contains("spell_break"):
		return &"sfx.player.damage"
	if cue.contains("graze"):
		return &"sfx.danmaku.graze"
	if cue.contains("impact") or cue.contains("result") or cue.contains("momentum"):
		return &"sfx.combat.impact"
	if cue.contains("bullet") or cue.contains("shot") or cue.contains("projectile"):
		return &"sfx.bullet.transient"
	if cue.contains("cancel"):
		return &"sfx.ui.cancel"
	if cue.contains("confirm") or cue.contains("photo") or cue.contains("shutter"):
		return &"sfx.ui.confirm"
	if cue.begins_with("sfx.ui") or cue.contains("chime") or cue.contains("medicine"):
		return &"sfx.ui.focus"
	if cue.contains("save"):
		return &"sfx.save.end" if cue.contains("end") or cue.contains("complete") else &"sfx.save.begin"
	return &"sfx.ambience.region_bed"


func _select_voice(family_id: StringName, cap: int) -> AudioStreamPlayer:
	if not _pools.has(family_id):
		_pools[family_id] = []
	var pool: Array = _pools[family_id]
	var now_msec := Time.get_ticks_msec()
	for candidate: AudioStreamPlayer in pool:
		if not candidate.playing and int(_voice_busy_until_msec.get(candidate.get_instance_id(), 0)) <= now_msec:
			return candidate
	if pool.size() < cap:
		var created := AudioStreamPlayer.new()
		created.name = StringName("Sfx_%s_%d" % [family_id, pool.size()])
		created.bus = &"SFX"
		pool.append(created)
		add_child(created)
		return created
	var oldest: AudioStreamPlayer = pool[0]
	var oldest_serial := int(_voice_serials.get(oldest.get_instance_id(), -1))
	for candidate: AudioStreamPlayer in pool:
		var candidate_serial := int(_voice_serials.get(candidate.get_instance_id(), -1))
		if candidate_serial < oldest_serial:
			oldest = candidate
			oldest_serial = candidate_serial
	steal_count += 1
	return oldest


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


func _last_voice_id() -> int:
	var newest_id := 0
	var newest_serial := -1
	for voice_id: int in _voice_serials:
		var serial := _voice_serials[voice_id]
		if serial > newest_serial:
			newest_id = voice_id
			newest_serial = serial
	return newest_id


func _exit_tree() -> void:
	for pool: Array in _pools.values():
		for voice: AudioStreamPlayer in pool:
			voice.stop()
			voice.stream = null
	_pools.clear()
	_streams.clear()
	_voice_serials.clear()
	_voice_busy_until_msec.clear()
	_voice_assets.clear()
	_voice_roles.clear()
