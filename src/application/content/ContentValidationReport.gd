class_name ContentValidationReport
extends RefCounted
## Typed aggregate returned by foundation content validation.

var checks: int = 0
var errors: Array[String] = []
var warnings: Array[String] = []
var notes: Array[String] = []


func record_check() -> void:
	checks += 1


func add_error(message: String) -> void:
	errors.append(message)


func add_warning(message: String) -> void:
	warnings.append(message)


func add_note(message: String) -> void:
	notes.append(message)


func is_valid() -> bool:
	return errors.is_empty()


func merge(other: ContentValidationReport) -> void:
	checks += other.checks
	errors.append_array(other.errors)
	warnings.append_array(other.warnings)
	notes.append_array(other.notes)
