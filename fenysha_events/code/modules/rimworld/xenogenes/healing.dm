/datum/rw_xenogene/healing/weak_immunity
	id = RW_XENOGENE_WEAK_IMMUNITY
	name = "Weak immunity"
	desc = "Immunity gain speed reduced."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	physiology_multipliers = list("immunity_mod" = 0.55)
	incompatibility_group = RW_XENOGENE_GROUP_IMMUNITY
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "weak_immunity"

/datum/rw_xenogene/healing/strong_immunity
	id = RW_XENOGENE_STRONG_IMMUNITY
	name = "Strong immunity"
	desc = "Immunity gain speed increased."
	complexity = 1
	metabolic_efficiency = -1
	physiology_multipliers = list("immunity_mod" = 1.6)
	incompatibility_group = RW_XENOGENE_GROUP_IMMUNITY
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "strong_immunity"

/datum/rw_xenogene/healing/super_immunity
	id = RW_XENOGENE_SUPER_IMMUNITY
	name = "Super immunity"
	desc = "Immunity gain speed greatly increased."
	complexity = 2
	metabolic_efficiency = -2
	physiology_multipliers = list("immunity_mod" = 2.6)
	incompatibility_group = RW_XENOGENE_GROUP_IMMUNITY
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "super_immunity"

/datum/rw_xenogene/healing/slow_wound_healing
	id = RW_XENOGENE_SLOW_WOUND_HEALING
	name = "Slow wound healing"
	desc = "Wounds heal slower."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	physiology_multipliers = list("wound_heal_mod" = 0.5)
	incompatibility_group = RW_XENOGENE_GROUP_WOUND_HEALING
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "slow_wound_healing"

/datum/rw_xenogene/healing/fast_wound_healing
	id = RW_XENOGENE_FAST_WOUND_HEALING
	name = "Fast wound healing"
	desc = "Wounds heal faster."
	complexity = 1
	metabolic_efficiency = -1
	physiology_multipliers = list("wound_heal_mod" = 1.6)
	incompatibility_group = RW_XENOGENE_GROUP_WOUND_HEALING
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "fast_wound_healing"

/datum/rw_xenogene/healing/superfast_wound_healing
	id = RW_XENOGENE_SUPERFAST_WOUND_HEALING
	name = "Superfast wound healing"
	desc = "Wounds heal much faster."
	complexity = 2
	metabolic_efficiency = -2
	physiology_multipliers = list("wound_heal_mod" = 3)
	incompatibility_group = RW_XENOGENE_GROUP_WOUND_HEALING
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "superfast_wound_healing"

/datum/rw_xenogene/healing/superclotting
	id = RW_XENOGENE_SUPERCLOTTING
	name = "Superclotting"
	desc = "Bleeding stops extremely quickly."
	complexity = 1
	metabolic_efficiency = -1
	physiology_multipliers = list("bleed_rate_mod" = 0.15)
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "superfast_wound_healing"
