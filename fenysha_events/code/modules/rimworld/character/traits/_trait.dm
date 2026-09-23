/datum/rw_trait
	abstract_type = /datum/rw_trait
	var/id
	var/name = "Trait"
	var/desc = "A colonist trait stub."
	var/cost = 0
	var/positive = TRUE
	var/list/skill_bonuses

/datum/rw_trait/quick_shot
	id = "quick_shot"
	name = "Quick Shot"
	desc = "Stub positive trait. +1 Shooting."
	cost = 200
	skill_bonuses = list(RW_SKILL_RANGED = 1)
