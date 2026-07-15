class_name FlagState
extends RefCounted
## Restricted primitive flag value; arbitrary nested Variant data is forbidden.

enum Kind {
	BOOLEAN,
	INTEGER,
	STABLE_ID,
}

var flag_id: StringName
var kind: Kind = Kind.BOOLEAN
var boolean_value: bool = false
var integer_value: int = 0
var stable_id_value: StringName = &""


static func from_value(p_flag_id: StringName, value: Variant) -> FlagState:
	var result := FlagState.new()
	result.flag_id = p_flag_id
	match typeof(value):
		TYPE_BOOL:
			result.kind = Kind.BOOLEAN
			result.boolean_value = value
		TYPE_INT:
			result.kind = Kind.INTEGER
			result.integer_value = value
		TYPE_STRING, TYPE_STRING_NAME:
			result.kind = Kind.STABLE_ID
			result.stable_id_value = StringName(value)
		_:
			return null
	return result


func value() -> Variant:
	match kind:
		Kind.INTEGER:
			return integer_value
		Kind.STABLE_ID:
			return stable_id_value
		_:
			return boolean_value


func duplicate_state() -> FlagState:
	var copy := FlagState.new()
	copy.flag_id = flag_id
	copy.kind = kind
	copy.boolean_value = boolean_value
	copy.integer_value = integer_value
	copy.stable_id_value = stable_id_value
	return copy
