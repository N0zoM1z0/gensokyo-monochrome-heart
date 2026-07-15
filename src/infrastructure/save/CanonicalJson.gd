class_name CanonicalJson
extends RefCounted
## Stable compact JSON used for checksums and deep-equality fixtures.


static func stringify(value: Variant) -> String:
	match typeof(value):
		TYPE_DICTIONARY:
			var dictionary: Dictionary = value
			var keys: Array[String] = []
			for key: Variant in dictionary.keys():
				keys.append(String(key))
			keys.sort()
			var fields: PackedStringArray = []
			for key: String in keys:
				fields.append("%s:%s" % [JSON.stringify(key), stringify(dictionary[key])])
			return "{%s}" % ",".join(fields)
		TYPE_ARRAY:
			var values: PackedStringArray = []
			for item: Variant in value:
				values.append(stringify(item))
			return "[%s]" % ",".join(values)
		TYPE_STRING_NAME:
			return JSON.stringify(String(value))
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return JSON.stringify(value)
		_:
			push_error("CanonicalJson cannot encode %s" % type_string(typeof(value)))
			return "null"


static func sha256(value: Variant) -> String:
	return stringify(value).sha256_text()
