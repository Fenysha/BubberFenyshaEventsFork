/datum/rw_xenogene/temperature/cold_weakness
	id = RW_XENOGENE_COLD_WEAKNESS
	name = "Cold weakness"
	desc = "More sensitive to cold."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	physiology_additive = list("cold_limit_mod" = 25)
	incompatibility_group = RW_XENOGENE_GROUP_COLD
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "cold_weakness"

/datum/rw_xenogene/temperature/cold_tolerant
	id = RW_XENOGENE_COLD_TOLERANT
	name = "Cold tolerant"
	desc = "More resistant to cold."
	complexity = 1
	metabolic_efficiency = -1
	physiology_additive = list("cold_limit_mod" = -40)
	incompatibility_group = RW_XENOGENE_GROUP_COLD
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "cold_tolerant"

/datum/rw_xenogene/temperature/cold_super_tolerant
	id = RW_XENOGENE_COLD_SUPER_TOLERANT
	name = "Cold super-tolerant"
	desc = "Greatly resistant to cold."
	complexity = 2
	metabolic_efficiency = -2
	physiology_additive = list("cold_limit_mod" = -80)
	gameplay_traits = list(TRAIT_RESISTCOLD)
	incompatibility_group = RW_XENOGENE_GROUP_COLD
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "cold_super_tolerant"

/datum/rw_xenogene/temperature/heat_weakness
	id = RW_XENOGENE_HEAT_WEAKNESS
	name = "Heat weakness"
	desc = "More sensitive to heat."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	physiology_additive = list("heat_limit_mod" = -25)
	incompatibility_group = RW_XENOGENE_GROUP_HEAT
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "heat_weakness"

/datum/rw_xenogene/temperature/heat_tolerant
	id = RW_XENOGENE_HEAT_TOLERANT
	name = "Heat tolerant"
	desc = "More resistant to heat."
	complexity = 1
	metabolic_efficiency = -1
	physiology_additive = list("heat_limit_mod" = 40)
	incompatibility_group = RW_XENOGENE_GROUP_HEAT
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "heat_tolerant"

/datum/rw_xenogene/temperature/heat_super_tolerant
	id = RW_XENOGENE_HEAT_SUPER_TOLERANT
	name = "Heat super-tolerant"
	desc = "Greatly resistant to heat."
	complexity = 2
	metabolic_efficiency = -2
	physiology_additive = list("heat_limit_mod" = 80)
	gameplay_traits = list(TRAIT_RESISTHEAT)
	incompatibility_group = RW_XENOGENE_GROUP_HEAT
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "heat_super_tolerant"
