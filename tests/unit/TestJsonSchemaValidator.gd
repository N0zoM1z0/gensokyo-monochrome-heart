class_name TestJsonSchemaValidator
extends RefCounted


func run() -> Array[String]:
	var failures: Array[String] = []
	var validator := JsonSchemaValidator.new()
	var schema := {
		"type": "object",
		"required": ["id", "values"],
		"properties": {
			"id": {"type": "string", "pattern": "^fixture\\."},
			"values": {"type": "array", "minItems": 1, "items": {"type": "integer", "minimum": 0}},
		},
		"additionalProperties": false,
	}
	var valid_errors := validator.validate({"id": "fixture.valid", "values": [0, 2]}, schema)
	if not valid_errors.is_empty():
		failures.append("valid schema fixture failed: %s" % "; ".join(valid_errors))
	var invalid_errors := validator.validate({"id": "wrong", "values": [-1], "extra": true}, schema)
	if invalid_errors.size() != 3:
		failures.append("invalid schema fixture expected 3 errors, got %d: %s" % [invalid_errors.size(), "; ".join(invalid_errors)])
	return failures
