/datum/rw_xenogene/hemogen/hemogenic
	id = RW_XENOGENE_HEMOGENIC
	name = "Hemogenic"
	desc = "Produces and stores hemogen. Required for other hemogen genes."
	complexity = 1
	metabolic_efficiency = 0
	xenogen_flags = RW_XENOGEN_PROCESSING
	hemogen_regen = 0.002
	incompatibility_group = RW_XENOGENE_GROUP_HEMOGEN_BASE

/datum/rw_xenogene/hemogen/bloodfeeder
	id = RW_XENOGENE_BLOODFEEDER
	name = "Bloodfeeder"
	desc = "Retractable fangs extract hemogen from warm blood."
	complexity = 1
	metabolic_efficiency = 0
	ability_path = /datum/action/cooldown/rw_xenogene/bloodfeed

/datum/rw_xenogene/hemogen/coagulate
	id = RW_XENOGENE_COAGULATE
	name = "Coagulate"
	desc = "Spend hemogen to instantly stop bleeding on self or others."
	complexity = 1
	metabolic_efficiency = 0
	ability_path = /datum/action/cooldown/rw_xenogene/coagulate

/datum/rw_xenogene/hemogen/deathrest
	id = RW_XENOGENE_DEATHREST
	name = "Deathrest"
	desc = "Periodic deathrest needed. Gains powerful bonuses while deathresting."
	complexity = 1
	metabolic_efficiency = 0
	xenogen_flags = RW_XENOGEN_PROCESSING
	needs_deathrest = TRUE
	ability_path = /datum/action/cooldown/rw_xenogene/deathrest

/datum/rw_xenogene/hemogen/longjump_legs
	id = RW_XENOGENE_LONGJUMP_LEGS
	name = "Longjump legs"
	desc = "Spend hemogen to leap a long distance."
	complexity = 1
	metabolic_efficiency = 0
	ability_path = /datum/action/cooldown/rw_xenogene/longjump

/datum/rw_xenogene/hemogen/piercing_spine
	id = RW_XENOGENE_PIERCING_SPINE
	name = "Piercing spine"
	desc = "Spend hemogen to fire a deadly spine projectile."
	complexity = 1
	metabolic_efficiency = 0
	ability_path = /datum/action/cooldown/rw_xenogene/piercing_spine

/datum/rw_xenogene/hemogen/hemogen_drain
	id = RW_XENOGENE_HEMOGEN_DRAIN
	name = "Hemogen drain"
	desc = "Passively drains hemogen from nearby hemogenic pawns."
	complexity = 1
	metabolic_efficiency = 0
	negative = TRUE
	xenogen_flags = RW_XENOGEN_PROCESSING
	hemogen_drain_range = 4
