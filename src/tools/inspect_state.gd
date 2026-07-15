extends SceneTree
## CLI developer inspector for generated state, payload fixtures, and save envelopes.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var fixture_path := ""
	var profile_id: StringName = &"p01"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--fixture="):
			fixture_path = argument.trim_prefix("--fixture=")
		elif argument.begins_with("--profile="):
			profile_id = StringName(argument.trim_prefix("--profile="))
		else:
			printerr("STATE INSPECTOR FAILED: unknown argument %s" % argument)
			quit(2)
			return
	var state: GameState
	var source_label := "generated:%s" % profile_id
	var migrated := false
	if not fixture_path.is_empty():
		var loaded := GameStateFixtureLoader.new().load_path(fixture_path)
		source_label = loaded.source_label
		if not loaded.is_success():
			printerr("STATE INSPECTOR FAILED source=%s code=%d" % [loaded.source_label, loaded.code])
			for error: String in loaded.errors:
				printerr("ERROR %s" % error)
			quit(1)
			return
		state = loaded.state
		migrated = loaded.was_migrated
	else:
		state = _create_default_state(profile_id)
		if state == null:
			printerr("STATE INSPECTOR FAILED: could not create profile %s from ContentDB" % profile_id)
			quit(1)
			return
	var content_db := root.get_node_or_null("ContentDB")
	if content_db != null:
		print("CONTENT revision=%s hash=%s" % [content_db.content_revision(), content_db.content_hash()])
	print("FIXTURE migrated=%s" % ("yes" if migrated else "no"))
	var report := GameStateInspector.inspect(state, source_label)
	print(report.human_readable())
	quit(0 if report.is_valid else 1)


func _create_default_state(profile_id: StringName) -> GameState:
	if not ProfileIdentityRules.is_valid_story_profile(profile_id):
		return null
	var content_db := root.get_node_or_null("ContentDB")
	if content_db == null or not content_db.is_loaded():
		return null
	var repository: ContentRepository = content_db.snapshot()
	var character_ids: Array[StringName] = []
	for character: CharacterRecord in repository.all_characters():
		character_ids.append(character.id)
	var region_ids: Array[StringName] = []
	for location: LocationRecord in repository.all_locations():
		region_ids.append(location.id)
	return GameStateFactory.create_new(profile_id, character_ids, region_ids)
