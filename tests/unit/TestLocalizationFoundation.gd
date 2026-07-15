class_name TestLocalizationFoundation
extends RefCounted

const LOCALIZATION_SERVICE_SCRIPT := preload("res://src/autoload/LocalizationService.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var catalog := UiTextCatalog.new()
	if not catalog.load_default():
		failures.append("UI localization catalog failed: %s" % "; ".join(catalog.errors))
		return failures
	for required_key: StringName in [
		&"ui.title.new_profile",
		&"ui.options.language",
		&"ui.pause.resume",
		&"ui.accessibility.title",
	]:
		if not catalog.has_key(required_key):
			failures.append("UI localization lacks %s" % required_key)
		elif catalog.text(required_key, &"en").is_empty() or catalog.text(required_key, &"ja").is_empty():
			failures.append("UI localization is not bilingual for %s" % required_key)
	var keys := catalog.keys()
	if keys.size() != 81:
		failures.append("expected 81 merged localization keys, got %d" % keys.size())
	if keys != catalog.keys():
		failures.append("UI localization keys are not deterministic")

	var service := LOCALIZATION_SERVICE_SCRIPT.new()
	if not service.initialize():
		failures.append("LocalizationService failed to initialize")
	else:
		service.set_locale(&"ja", false)
		if service.locale != &"ja" or service.text(&"ui.common.confirm") != "決定":
			failures.append("live Japanese locale switch did not resolve the active catalog")
		service.set_locale(&"unsupported", false)
		if service.locale != &"en":
			failures.append("unsupported locale did not fall back to English")
	service.free()
	return failures
