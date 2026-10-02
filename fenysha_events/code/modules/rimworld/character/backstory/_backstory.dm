/datum/rw_backstory
	abstract_type = /datum/rw_backstory
	var/id
	var/name = "Backstory"
	var/desc = "A colonist backstory."
	var/text_good
	var/text_bad
	var/slot = RW_BACKSTORY_CHILDHOOD
	var/list/skill_bonuses
	var/list/granted_traits

/datum/rw_backstory/proc/apply_to_prefs(datum/rimworld_preferences/prefs)
	return

/datum/rw_backstory/childhood
	abstract_type = /datum/rw_backstory/childhood
	slot = RW_BACKSTORY_CHILDHOOD

/datum/rw_backstory/adulthood
	abstract_type = /datum/rw_backstory/adulthood
	slot = RW_BACKSTORY_ADULTHOOD

/datum/rw_backstory/childhood/none
	id = "childhood_none"
	name = "None"
	desc = "No childhood selected."

/datum/rw_backstory/adulthood/none
	id = "adulthood_none"
	name = "None"
	desc = "No adulthood selected."
