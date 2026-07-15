class_name AtomicWriteResult
extends RefCounted
## File replacement result with explicit durable step diagnostics.

var error: Error = OK
var step: StringName = &"complete"
var message: String = ""


func is_success() -> bool:
	return error == OK
