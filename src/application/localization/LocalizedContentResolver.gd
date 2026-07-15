class_name LocalizedContentResolver
extends RefCounted
## Resolves reviewed content keys, then applies explicit named formatting.

var _content: ContentRepository
var _formatter := NamedTextFormatter.new()


func _init(content: ContentRepository = null) -> void:
	_content = content


func resolve(key: StringName, locale: StringName, arguments: Dictionary = {}) -> NamedFormatResult:
	if _content == null:
		var unavailable := NamedFormatResult.new()
		unavailable.text = "[%s]" % key
		unavailable.errors.append("ContentRepository is unavailable")
		return unavailable
	var record := _content.localized_string(key)
	if record == null:
		var missing := NamedFormatResult.new()
		missing.text = "[%s]" % key
		missing.errors.append("missing localization key: %s" % key)
		return missing
	return _formatter.format(record.resolve(locale), arguments)
