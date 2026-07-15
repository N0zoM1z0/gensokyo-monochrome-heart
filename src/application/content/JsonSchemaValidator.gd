class_name JsonSchemaValidator
extends RefCounted
## Dependency-free validator for the JSON Schema subset used by starter contracts.


func validate(instance: Variant, schema: Dictionary, instance_path: String = "$") -> Array[String]:
	var errors: Array[String] = []
	_validate_value(instance, schema, instance_path, errors)
	return errors


func _validate_value(instance: Variant, schema: Dictionary, path: String, errors: Array[String]) -> void:
	if schema.has("type") and not _matches_type(instance, schema.type):
		errors.append("%s expected type %s, got %s" % [path, schema.type, type_string(typeof(instance))])
		return
	if schema.has("const") and instance != schema.const:
		errors.append("%s must equal %s" % [path, schema.const])
	if schema.has("enum") and instance not in schema.enum:
		errors.append("%s must be one of %s" % [path, schema.enum])
	match typeof(instance):
		TYPE_DICTIONARY:
			_validate_object(instance, schema, path, errors)
		TYPE_ARRAY:
			_validate_array(instance, schema, path, errors)
		TYPE_STRING, TYPE_STRING_NAME:
			_validate_string(String(instance), schema, path, errors)
		TYPE_INT, TYPE_FLOAT:
			_validate_number(instance, schema, path, errors)


func _matches_type(instance: Variant, expected: Variant) -> bool:
	if expected is Array:
		for candidate: Variant in expected:
			if _matches_single_type(instance, String(candidate)):
				return true
		return false
	return _matches_single_type(instance, String(expected))


func _matches_single_type(instance: Variant, expected: String) -> bool:
	match expected:
		"null":
			return instance == null
		"object":
			return instance is Dictionary
		"array":
			return instance is Array
		"string":
			return instance is String or instance is StringName
		"integer":
			if typeof(instance) == TYPE_INT:
				return true
			if typeof(instance) == TYPE_FLOAT:
				var value: float = instance
				return value == floor(value)
			return false
		"number":
			return typeof(instance) == TYPE_INT or typeof(instance) == TYPE_FLOAT
		"boolean":
			return typeof(instance) == TYPE_BOOL
		_:
			return false


func _validate_object(instance: Dictionary, schema: Dictionary, path: String, errors: Array[String]) -> void:
	if schema.has("minProperties") and instance.size() < int(schema.minProperties):
		errors.append("%s requires at least %d properties" % [path, schema.minProperties])
	var required: Variant = schema.get("required", [])
	if required is Array:
		for key: Variant in required:
			if not instance.has(key):
				errors.append("%s missing required property %s" % [path, key])
	var properties: Dictionary = schema.get("properties", {})
	var additional: Variant = schema.get("additionalProperties", true)
	for key: Variant in instance:
		var child_path := "%s.%s" % [path, key]
		if properties.has(key) and properties[key] is Dictionary:
			_validate_value(instance[key], properties[key], child_path, errors)
		elif additional is bool and not additional:
			errors.append("%s contains an unsupported property" % child_path)
		elif additional is Dictionary:
			_validate_value(instance[key], additional, child_path, errors)


func _validate_array(instance: Array, schema: Dictionary, path: String, errors: Array[String]) -> void:
	if schema.has("minItems") and instance.size() < int(schema.minItems):
		errors.append("%s requires at least %d items" % [path, schema.minItems])
	if schema.has("maxItems") and instance.size() > int(schema.maxItems):
		errors.append("%s allows at most %d items" % [path, schema.maxItems])
	var prefix_items: Variant = schema.get("prefixItems", [])
	if prefix_items is Array:
		for index: int in mini(instance.size(), prefix_items.size()):
			if prefix_items[index] is Dictionary:
				_validate_value(instance[index], prefix_items[index], "%s[%d]" % [path, index], errors)
	var item_schema: Variant = schema.get("items", null)
	if item_schema is Dictionary:
		for index: int in instance.size():
			_validate_value(instance[index], item_schema, "%s[%d]" % [path, index], errors)


func _validate_string(instance: String, schema: Dictionary, path: String, errors: Array[String]) -> void:
	if schema.has("minLength") and instance.length() < int(schema.minLength):
		errors.append("%s requires at least %d characters" % [path, schema.minLength])
	if schema.has("maxLength") and instance.length() > int(schema.maxLength):
		errors.append("%s allows at most %d characters" % [path, schema.maxLength])
	if schema.has("pattern"):
		var expression := RegEx.create_from_string(String(schema.pattern))
		if expression.search(instance) == null:
			errors.append("%s does not match pattern %s" % [path, schema.pattern])


func _validate_number(instance: Variant, schema: Dictionary, path: String, errors: Array[String]) -> void:
	var value := float(instance)
	if schema.has("minimum") and value < float(schema.minimum):
		errors.append("%s must be >= %s" % [path, schema.minimum])
	if schema.has("maximum") and value > float(schema.maximum):
		errors.append("%s must be <= %s" % [path, schema.maximum])
	if schema.has("exclusiveMinimum") and value <= float(schema.exclusiveMinimum):
		errors.append("%s must be > %s" % [path, schema.exclusiveMinimum])
