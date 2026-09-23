/datum/rw_backstory
	abstract_type = /datum/rw_backstory
	var/id
	var/name = "Backstory"
	var/desc = "A colonist backstory stub."
	var/slot = RW_BACKSTORY_CHILDHOOD
	var/list/skill_bonuses
	var/list/granted_traits

/datum/rw_backstory/proc/apply_to_prefs(datum/rimworld_preferences/prefs)
	return
