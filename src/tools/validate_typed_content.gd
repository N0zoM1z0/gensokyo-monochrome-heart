extends SceneTree
## Loads the complete authored package through the gameplay-facing typed boundary.


func _initialize() -> void:
	var sources := _source_set_for_arguments(OS.get_cmdline_user_args())
	var repository := ContentRepository.new()
	var report := repository.load_sources(sources)
	print(report.human_readable())
	quit(0 if report.is_success() else 1)


func _source_set_for_arguments(arguments: PackedStringArray) -> ContentSourceSet:
	var sources := ContentSourceSet.new()
	if "--fixture-invalid-id" in arguments:
		sources.supplemental_character_paths.append(
			"res://tests/fixtures/invalid/typed_content/invalid_character_id.json"
		)
	elif "--fixture-duplicate-id" in arguments:
		sources.supplemental_character_paths.append(
			"res://tests/fixtures/invalid/typed_content/duplicate_character_id.json"
		)
	elif "--fixture-missing-event-reference" in arguments:
		sources.supplemental_event_paths.append(
			"res://tests/fixtures/invalid/typed_content/missing_event_references.json"
		)
	elif "--fixture-missing-localization-reference" in arguments:
		sources.supplemental_dialogue_paths.append(
			"res://tests/fixtures/invalid/typed_content/missing_localization_reference.json"
		)
	elif "--fixture-missing-file" in arguments:
		sources.supplemental_character_paths.append(
			"res://tests/fixtures/invalid/typed_content/does_not_exist.json"
		)
	if sources.content_paths().size() > ContentSourceSet.new().content_paths().size():
		sources.enforce_manifest_counts = false
	return sources
