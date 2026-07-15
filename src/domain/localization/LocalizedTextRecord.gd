class_name LocalizedTextRecord
extends RefCounted
## One reviewed semantic UI key with first-class English and Japanese source text.

var key: StringName
var english: String
var japanese: String


func _init(p_key: StringName, p_english: String, p_japanese: String) -> void:
	key = p_key
	english = p_english
	japanese = p_japanese


func resolve(locale: StringName) -> String:
	return japanese if locale == &"ja" else english
