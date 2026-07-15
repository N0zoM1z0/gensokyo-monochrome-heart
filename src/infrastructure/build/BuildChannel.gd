class_name BuildChannel
extends RefCounted
## Central build-channel policy. Story systems must not branch on build channels.

enum Kind {
	DEV,
	QA,
	DEMO,
	RELEASE,
}

const SETTING_NAME: StringName = &"gmh/build/channel"


static func current() -> Kind:
	for feature: StringName in [&"release", &"demo", &"qa", &"dev"]:
		if OS.has_feature(feature):
			return from_string(feature)
	return from_string(StringName(ProjectSettings.get_setting(SETTING_NAME, "dev")))


static func from_string(value: StringName) -> Kind:
	match value:
		&"qa":
			return Kind.QA
		&"demo":
			return Kind.DEMO
		&"release":
			return Kind.RELEASE
		_:
			return Kind.DEV


static func display_name(channel: Kind) -> StringName:
	match channel:
		Kind.QA:
			return &"qa"
		Kind.DEMO:
			return &"demo"
		Kind.RELEASE:
			return &"release"
		_:
			return &"dev"


static func allows_debug_tools(channel: Kind = current()) -> bool:
	return channel == Kind.DEV or channel == Kind.QA


static func allows_placeholders(channel: Kind = current()) -> bool:
	return channel != Kind.RELEASE


static func save_namespace(channel: Kind = current()) -> StringName:
	return StringName("gmh_%s" % display_name(channel))
