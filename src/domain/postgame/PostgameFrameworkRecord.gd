class_name PostgameFrameworkRecord
extends RefCounted
## Typed M15 catalog joining Dream Theatre, seasonal events, and Accord rules.

var id: StringName
var dream_theatre: DreamTheatreRecord
var seasonal_events: Array[SeasonalEventRecord] = []
var ensemble_accord: EnsembleAccordRulesRecord
var source_path: String


func seasonal_event(event_id: StringName) -> SeasonalEventRecord:
	for record: SeasonalEventRecord in seasonal_events:
		if record.id == event_id:
			return record
	return null


func events_for_season(season: StringName) -> Array[SeasonalEventRecord]:
	var result: Array[SeasonalEventRecord] = []
	for record: SeasonalEventRecord in seasonal_events:
		if record.season == season:
			result.append(record)
	result.sort_custom(func(left: SeasonalEventRecord, right: SeasonalEventRecord) -> bool: return String(left.id) < String(right.id))
	return result
