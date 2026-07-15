class_name EventCommandCompileResult
extends RefCounted
## Typed effect compilation outcome before an event-node transaction begins.

var commands: Array[GameCommand] = []
var errors: Array[String] = []


func is_success() -> bool:
	return errors.is_empty()
