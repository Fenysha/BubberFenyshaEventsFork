/datum/rw_trait
	abstract_type = /datum/rw_trait
	var/id
	var/name = "Trait"
	var/desc = "A colonist trait stub."
	/// Benefit line shown in the editor. Empty means the trait has no upside text.
	var/text_good
	/// Drawback line shown in the editor. Empty means the trait has no downside text.
	var/text_bad
	var/cost = 0
	var/positive = TRUE
	var/list/skill_bonuses

/datum/rw_trait/quick_shot
	id = "quick_shot"
	name = "Quick Shot"
	desc = "Stub positive trait. +1 Shooting."
	text_good = "You shoot better."
	text_bad = "That will not help you in a fight."
	cost = 200
	skill_bonuses = list(RW_SKILL_RANGED = 1)
