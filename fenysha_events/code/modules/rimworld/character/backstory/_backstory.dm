/datum/rw_backstory
	abstract_type = /datum/rw_backstory
	var/id
	var/name = "Backstory"
	var/desc = "A colonist backstory stub."
	/// Benefit line shown in the editor. Empty means the story has no upside text.
	var/text_good
	/// Drawback line shown in the editor. Empty means the story has no downside text.
	var/text_bad
	var/slot = RW_BACKSTORY_CHILDHOOD
	var/list/skill_bonuses
	var/list/granted_traits

/datum/rw_backstory/proc/apply_to_prefs(datum/rimworld_preferences/prefs)
	return
