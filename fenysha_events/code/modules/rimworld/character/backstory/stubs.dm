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

/datum/rw_backstory/childhood/colony_child
	id = "colony_child"
	name = "Colony Child"
	desc = "Grew up on a rimworld colony. +1 Shooting."
	skill_bonuses = list(RW_SKILL_RANGED = 1)

/datum/rw_backstory/adulthood/none
	id = "adulthood_none"
	name = "None"
	desc = "No adulthood selected."

/datum/rw_backstory/adulthood/hunter
	id = "hunter"
	name = "Hunter"
	desc = "Lived by the rifle. +2 Shooting."
	skill_bonuses = list(RW_SKILL_RANGED = 2)
