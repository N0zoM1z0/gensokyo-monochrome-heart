class_name NamedTextFormatter
extends RefCounted
## Locale-neutral {name} formatting; positional substitutions are intentionally unsupported.

const OPEN_SENTINEL := "\ue000"
const CLOSE_SENTINEL := "\ue001"


func format(template: String, arguments: Dictionary = {}) -> NamedFormatResult:
	var result := NamedFormatResult.new()
	var working := template.replace("{{", OPEN_SENTINEL).replace("}}", CLOSE_SENTINEL)
	var expression := RegEx.create_from_string("\\{([a-z][a-z0-9_]*)\\}")
	var matches := expression.search_all(working)
	for index: int in range(matches.size() - 1, -1, -1):
		var matched := matches[index]
		var name := StringName(matched.get_string(1))
		var value: Variant = arguments.get(name, arguments.get(String(name), null))
		if value == null:
			result.errors.append("missing named localization argument: %s" % name)
			continue
		var start := matched.get_start(0)
		var finish := matched.get_end(0)
		working = working.substr(0, start) + str(value) + working.substr(finish)
	result.text = working.replace(OPEN_SENTINEL, "{").replace(CLOSE_SENTINEL, "}")
	result.errors.reverse()
	return result


func typed_arguments(arguments: Dictionary) -> Array[NamedTextArgument]:
	var names: Array[String] = []
	for raw_name: Variant in arguments:
		names.append(String(raw_name))
	names.sort()
	var result: Array[NamedTextArgument] = []
	for name: String in names:
		var value: Variant = arguments.get(StringName(name), arguments.get(name, ""))
		result.append(NamedTextArgument.new(StringName(name), str(value)))
	return result


func dictionary(arguments: Array[NamedTextArgument]) -> Dictionary:
	var result: Dictionary = {}
	for argument: NamedTextArgument in arguments:
		result[argument.name] = argument.value
	return result
