class_name UiScalePolicy
extends RefCounted
## Discrete accessibility scale contract for the fixed 320x180 composition.

const SUPPORTED_PERCENTAGES := [100, 125, 150]


static func normalize(percent: int) -> int:
	var nearest := 100
	var nearest_distance := absi(percent - nearest)
	for candidate: int in SUPPORTED_PERCENTAGES:
		var distance := absi(percent - candidate)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest


static func next(percent: int, direction: int) -> int:
	var normalized := normalize(percent)
	var index := SUPPORTED_PERCENTAGES.find(normalized)
	return SUPPORTED_PERCENTAGES[wrapi(index + signi(direction), 0, SUPPORTED_PERCENTAGES.size())]


static func pixels(base_size: int, percent: int) -> int:
	return maxi(1, ceili(base_size * normalize(percent) / 100.0))


static func is_reflow(percent: int) -> bool:
	return normalize(percent) > 100
