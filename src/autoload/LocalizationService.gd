extends Node
## Owns locale preference and publishes live UI reflow without changing mode state.

signal locale_changed(locale: StringName)

const CONFIG_PATH := "user://settings.cfg"
const VALID_LOCALES: Array[StringName] = [&"en", &"ja"]

var locale: StringName = &"en"
var has_selected_language: bool = false
var _catalog := UiTextCatalog.new()


func _ready() -> void:
	initialize()


func initialize() -> bool:
	var candidate := UiTextCatalog.new()
	if not candidate.load_default():
		for error: String in candidate.errors:
			push_error(error)
		return false
	_catalog = candidate
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		var stored_locale := StringName(config.get_value("localization", "locale", "en"))
		locale = stored_locale if stored_locale in VALID_LOCALES else &"en"
		has_selected_language = bool(config.get_value("localization", "selected", false))
	TranslationServer.set_locale(locale)
	return true


func reload_catalog() -> bool:
	var candidate := UiTextCatalog.new()
	if not candidate.load_default():
		for error: String in candidate.errors:
			push_error(error)
		return false
	_catalog = candidate
	locale_changed.emit(locale)
	return true


func set_locale(requested_locale: StringName, should_persist: bool = true) -> void:
	var normalized := requested_locale if requested_locale in VALID_LOCALES else &"en"
	if locale == normalized and has_selected_language:
		return
	locale = normalized
	has_selected_language = true
	TranslationServer.set_locale(locale)
	if should_persist:
		_save_preference()
	locale_changed.emit(locale)


func text(key: StringName) -> String:
	return _catalog.text(key, locale)


func text_for_locale(key: StringName, requested_locale: StringName) -> String:
	return _catalog.text(key, requested_locale)


func _save_preference() -> void:
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	config.set_value("localization", "locale", String(locale))
	config.set_value("localization", "selected", true)
	var error := config.save(CONFIG_PATH)
	if error != OK:
		push_error("Could not persist locale preference (error %d)" % error)
