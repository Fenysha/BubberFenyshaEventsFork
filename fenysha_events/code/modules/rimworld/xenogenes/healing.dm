/datum/rw_xenogene/healing/weak_immunity
	id = RW_XENOGENE_WEAK_IMMUNITY
	name = "Weak immunity"
	desc = "Immunity gain speed reduced."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	immunity_mult = 0.55
	incompatibility_group = RW_XENOGENE_GROUP_IMMUNITY

/datum/rw_xenogene/healing/strong_immunity
	id = RW_XENOGENE_STRONG_IMMUNITY
	name = "Strong immunity"
	desc = "Immunity gain speed increased."
	complexity = 1
	metabolic_efficiency = -1
	immunity_mult = 1.6
	incompatibility_group = RW_XENOGENE_GROUP_IMMUNITY

/datum/rw_xenogene/healing/super_immunity
	id = RW_XENOGENE_SUPER_IMMUNITY
	name = "Super immunity"
	desc = "Immunity gain speed greatly increased."
	complexity = 2
	metabolic_efficiency = -2
	immunity_mult = 2.6
	incompatibility_group = RW_XENOGENE_GROUP_IMMUNITY

/datum/rw_xenogene/healing/slow_wound_healing
	id = RW_XENOGENE_SLOW_WOUND_HEALING
	name = "Slow wound healing"
	desc = "Wounds heal slower."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	wound_heal_mult = 0.5
	incompatibility_group = RW_XENOGENE_GROUP_WOUND_HEALING

/datum/rw_xenogene/healing/fast_wound_healing
	id = RW_XENOGENE_FAST_WOUND_HEALING
	name = "Fast wound healing"
	desc = "Wounds heal faster."
	complexity = 1
	metabolic_efficiency = -1
	wound_heal_mult = 1.6
	incompatibility_group = RW_XENOGENE_GROUP_WOUND_HEALING

/datum/rw_xenogene/healing/superfast_wound_healing
	id = RW_XENOGENE_SUPERFAST_WOUND_HEALING
	name = "Superfast wound healing"
	desc = "Wounds heal much faster."
	complexity = 2
	metabolic_efficiency = -2
	wound_heal_mult = 3
	incompatibility_group = RW_XENOGENE_GROUP_WOUND_HEALING

/datum/rw_xenogene/healing/superclotting
	id = RW_XENOGENE_SUPERCLOTTING
	name = "Superclotting"
	desc = "Bleeding stops extremely quickly."
	complexity = 1
	metabolic_efficiency = -1
	bleed_mult = 0.15
