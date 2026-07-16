class_name ImpossibleErrandDefinition
extends RefCounted
## A self-contained negotiation trial plugged into the five-errand sequence.

var errand_id: StringName
var trial_kind: StringName
var treasure_key: StringName
var request_key: StringName
var rule_key: StringName
var options: Array[ImpossibleErrandOption] = []


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if not String(errand_id).begins_with("errand.ein."):
		errors.append("errand ID must begin with errand.ein.: %s" % errand_id)
	if trial_kind == &"" or treasure_key == &"" or request_key == &"" or rule_key == &"":
		errors.append("errand requires kind and localized treasure, request, and rule keys")
	if options.size() != 3:
		errors.append("errand requires literal, clever, and refuse options")
	else:
		var expected: Array[StringName] = [&"literal", &"clever", &"refuse"]
		for index: int in range(expected.size()):
			var option := options[index]
			if option == null or option.approach_id != expected[index]:
				errors.append("errand option %d must be %s" % [index, expected[index]])
			elif option.label_key == &"" or option.action_key == &"" or option.consequence_key == &"":
				errors.append("errand option %s is missing localized keys" % option.approach_id)
	return errors
