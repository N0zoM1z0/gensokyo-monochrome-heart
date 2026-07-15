class_name CharacterAuthoringService
extends RefCounted
## M11 catalog browser and strict validator for character-agent authored output.

const OUTPUT_SCHEMA_PATH := "res://schemas/character_agent_output.schema.json"
const REQUIRED_SECTIONS: Array[String] = [
	"## 1. Canon identity anchors",
	"## 2. Portrayal contract",
	"## 3. Voice model",
	"## 4. Relationship anchors",
	"## 5. Canon / fanon / original control",
	"## 6. Romance and trust progression",
	"## 7. Gameplay expression",
	"## 8. Agent runtime contract",
	"## 9. Original sample lines",
	"## 10. Source notes",
]
const STATE_KEYS: Array[String] = ["trust", "ease", "respect", "spark", "strain"]


func render_catalog() -> CharacterAuthoringResult:
	var result := CharacterAuthoringResult.new()
	var repository := _repository(result)
	if repository == null:
		return result
	var rows := PackedStringArray()
	var healthy := 0
	for character: CharacterRecord in repository.all_characters():
		var document_errors := _skills_document_errors(character)
		var status := "READY" if document_errors.is_empty() else "INVALID"
		if document_errors.is_empty():
			healthy += 1
		else:
			for error: String in document_errors:
				result.errors.append(error)
		rows.append("| `%s` | %s | %s | %s | %s | `%s` |" % [
			character.id,
			character.display_name_en,
			character.display_name_ja,
			character.route_depth,
			status,
			character.skills_document,
		])
	result.output = "\n".join(PackedStringArray([
		"# Character skills catalog",
		"",
		"- Characters: %d" % repository.all_characters().size(),
		"- Ready: %d" % healthy,
		"- Invalid: %d" % (repository.all_characters().size() - healthy),
		"",
		"| Character ID | English | Japanese | Route | Status | Skills document |",
		"| --- | --- | --- | --- | --- | --- |",
	]) + rows) + "\n"
	return result


func render_skill(character_id: StringName) -> CharacterAuthoringResult:
	var result := CharacterAuthoringResult.new()
	result.character_id = character_id
	var repository := _repository(result)
	if repository == null:
		return result
	var character := repository.character(character_id)
	if character == null:
		result.errors.append("unknown character ID: %s" % character_id)
		return result
	result.source_path = character.skills_document
	result.errors.append_array(_skills_document_errors(character))
	if result.errors.is_empty():
		result.output = FileAccess.get_file_as_string(character.skills_document)
	return result


func validate_agent_output(character_id: StringName, input_path: String) -> CharacterAuthoringResult:
	var result := CharacterAuthoringResult.new()
	result.character_id = character_id
	result.source_path = input_path
	var repository := _repository(result)
	if repository == null:
		return result
	if repository.character(character_id) == null:
		result.errors.append("unknown character ID: %s" % character_id)
	var instance_data: Variant = _load_json(input_path, result.errors)
	var schema_data: Variant = _load_json(OUTPUT_SCHEMA_PATH, result.errors)
	if not instance_data is Dictionary or not schema_data is Dictionary:
		return result
	var instance: Dictionary = instance_data
	var schema: Dictionary = schema_data
	for error: String in JsonSchemaValidator.new().validate(instance, schema):
		result.errors.append("schema %s: %s" % [input_path, error])
	_validate_semantics(instance, input_path, result)
	if result.errors.is_empty():
		var changed_facets := _changed_facets(instance.state_suggestion)
		result.output = (
			"VALID CHARACTER AGENT OUTPUT character=%s changed_facets=%s memory_tag=%s\n"
			% [character_id, ",".join(changed_facets) if not changed_facets.is_empty() else "none", instance.get("memory_tag", null)]
		)
	return result


func _repository(result: CharacterAuthoringResult) -> ContentRepository:
	var repository := ContentRepository.new()
	var report := repository.load_sources()
	if not report.is_success():
		result.errors.append("reviewed content catalog failed to load")
		return null
	return repository


func _skills_document_errors(character: CharacterRecord) -> Array[String]:
	var errors: Array[String] = []
	if character.skills_document.is_empty() or not FileAccess.file_exists(character.skills_document):
		errors.append("%s skills document is missing: %s" % [character.id, character.skills_document])
		return errors
	var contents := FileAccess.get_file_as_string(character.skills_document)
	if not contents.begins_with("# %s — Character Agent Skills" % character.display_name_en):
		errors.append("%s skills title does not match the character index" % character.id)
	for heading: String in REQUIRED_SECTIONS:
		if not contents.contains(heading):
			errors.append("%s skills document is missing section: %s" % [character.id, heading])
	return errors


func _validate_semantics(instance: Dictionary, path: String, result: CharacterAuthoringResult) -> void:
	if String(instance.get("intent", "")).strip_edges().is_empty():
		result.errors.append("semantic %s: intent cannot be whitespace" % path)
	if String(instance.get("nonverbal", "")).strip_edges().is_empty():
		result.errors.append("semantic %s: nonverbal cue cannot be empty" % path)
	var english := String(instance.get("spoken_line_en", "")).strip_edges()
	var japanese := String(instance.get("spoken_line_ja", "")).strip_edges()
	if english.is_empty() != japanese.is_empty():
		result.errors.append("semantic %s: spoken output must provide both EN and JA, or leave both empty" % path)
	var state: Variant = instance.get("state_suggestion", null)
	if state is Dictionary:
		var changed := _changed_facets(state)
		if changed.size() > 1:
			result.errors.append("semantic %s: at most one state facet may change, got %s" % [path, ", ".join(changed)])


func _changed_facets(state: Dictionary) -> PackedStringArray:
	var changed := PackedStringArray()
	for key: String in STATE_KEYS:
		if int(state.get(key, 0)) != 0:
			changed.append(key)
	return changed


func _load_json(path: String, errors: Array[String]) -> Variant:
	if not FileAccess.file_exists(path):
		errors.append("JSON file is missing: %s" % path)
		return null
	var json := JSON.new()
	var parse_error := json.parse(FileAccess.get_file_as_string(path))
	if parse_error != OK:
		errors.append("JSON parse failed %s:%d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data
