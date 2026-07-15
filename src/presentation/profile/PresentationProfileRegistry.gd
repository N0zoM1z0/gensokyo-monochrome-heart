class_name PresentationProfileRegistry
extends RefCounted
## Resolves the four visual profiles while enforcing Profile A as the universal fallback.

const FALLBACK_ID: StringName = &"A"
const PROFILE_PATHS: Dictionary[StringName, String] = {
	&"A": "res://ui/theme/profiles/profile_a.tres",
	&"B": "res://ui/theme/profiles/profile_b.tres",
	&"C": "res://ui/theme/profiles/profile_c.tres",
	&"D": "res://ui/theme/profiles/profile_d.tres",
}


static func resolve(profile_id: StringName) -> PresentationProfile:
	var normalized := profile_id if PROFILE_PATHS.has(profile_id) else FALLBACK_ID
	var profile := ResourceLoader.load(PROFILE_PATHS[normalized]) as PresentationProfile
	assert(profile != null, "Presentation profile failed to load: %s" % normalized)
	assert(profile.validation_errors().is_empty(), "Invalid presentation profile: %s" % normalized)
	return profile


static func all_profiles() -> Array[PresentationProfile]:
	var profiles: Array[PresentationProfile] = []
	for profile_id: StringName in [&"A", &"B", &"C", &"D"]:
		profiles.append(resolve(profile_id))
	return profiles
