class_name CampaignChapterCatalog
extends RefCounted
## Reviewed M13 headline sequence and its route-independent chapter reveals.


static func build() -> Array[CampaignChapterDefinition]:
	return [
		_chapter(
			1,
			[&"evt.hkr.empty_cushion"],
			&"reveal.memory_objects_pull_at_boundary",
			&"loc.scarlet_devil_mansion",
			&"region.archive.minute_unwritten"
		),
		_chapter(
			2,
			[&"evt.sdm.late_by_three_minutes"],
			&"reveal.archive_preserves_repeatable_time",
			&"loc.youkai_mountain",
			&"region.archive.future_headline_visible"
		),
		_chapter(
			3,
			[&"evt.mtn.tomorrows_headline"],
			&"reveal.expected_future_writes_present",
			&"loc.eientei",
			&"region.archive.four_dawns_open"
		),
		_chapter(
			4,
			[&"evt.ein.four_dawns", &"evt.ein.five_impossibilities"],
			&"reveal.remembered_year_can_fossilize_world",
			&"loc.hakugyokurou",
			&"region.archive.petals_held"
		),
		_chapter(
			5,
			[&"evt.hgy.petal_on_hold"],
			&"reveal.forgetting_can_preserve_memory",
			&"loc.human_village",
			&"region.archive.public_hearing_called"
		),
	]


static func for_chapter(chapter_id: StringName) -> CampaignChapterDefinition:
	for definition: CampaignChapterDefinition in build():
		if definition.chapter_id == chapter_id:
			return definition
	return null


static func _chapter(
	chapter_number: int,
	required_events: Array[StringName],
	reveal_id: StringName,
	next_region_id: StringName,
	next_condition_id: StringName
) -> CampaignChapterDefinition:
	var definition := CampaignChapterDefinition.new()
	definition.chapter_id = StringName("chapter.%d" % chapter_number)
	definition.next_chapter_id = StringName("chapter.%d" % (chapter_number + 1))
	definition.required_event_ids = required_events.duplicate()
	definition.reveal_id = reveal_id
	definition.reveal_flag_id = StringName("flag.campaign.reveal.chapter_%d" % chapter_number)
	definition.journal_entry_id = StringName("journal.campaign.chapter_%d" % chapter_number)
	definition.journal_title_key = StringName("ui.journal.campaign.chapter_%d.title" % chapter_number)
	definition.journal_observation_key = StringName("ui.journal.campaign.chapter_%d.reveal" % chapter_number)
	definition.next_region_conditions = {next_region_id: next_condition_id}
	return definition
