class_name NamedFormatResult
extends RefCounted
## Formatted localized text plus explicit missing-placeholder diagnostics.

var text: String
var errors: Array[String] = []


func is_success() -> bool:
	return errors.is_empty()
