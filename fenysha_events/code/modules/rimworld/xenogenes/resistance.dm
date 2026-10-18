/datum/rw_xenogene/resistance/tox_resistance
	id = RW_XENOGENE_TOX_RESISTANCE
	name = "Tox resistance"
	desc = "Reduced sensitivity to toxic buildup."
	complexity = 1
	metabolic_efficiency = -1
	physiology_multipliers = list("tox_taken_mod" = 0.45)
	incompatibility_group = RW_XENOGENE_GROUP_TOX
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "tox_resistance"

/datum/rw_xenogene/resistance/tox_immunity
	id = RW_XENOGENE_TOX_IMMUNITY
	name = "Tox immunity"
	desc = "Immune to toxic buildup."
	complexity = 2
	metabolic_efficiency = -2
	physiology_multipliers = list("tox_taken_mod" = 0)
	gameplay_traits = list(TRAIT_TOXIMMUNE)
	incompatibility_group = RW_XENOGENE_GROUP_TOX
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "tox_immunity"

/datum/rw_xenogene/resistance/mild_uv_sensitivity
	id = RW_XENOGENE_MILD_UV_SENSITIVITY
	name = "Mild UV sensitivity"
	desc = "Mildly harmed by sunlight."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	xenogen_flags = RW_XENOGEN_PROCESSING
	uv_burn = 0.4
	incompatibility_group = RW_XENOGENE_GROUP_UV
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "mild_uv_sensitivity"

/datum/rw_xenogene/resistance/intense_uv_sensitivity
	id = RW_XENOGENE_INTENSE_UV_SENSITIVITY
	name = "Intense UV sensitivity"
	desc = "Severely harmed by sunlight."
	complexity = 1
	metabolic_efficiency = 2
	negative = TRUE
	xenogen_flags = RW_XENOGEN_PROCESSING
	uv_burn = 1.2
	incompatibility_group = RW_XENOGENE_GROUP_UV
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "intense_uv_sensitivity"

/datum/rw_xenogene/resistance/fire_resistance
	id = RW_XENOGENE_FIRE_RESISTANCE
	name = "Fire resistance"
	desc = "Resistant to fire and heat damage from flames."
	complexity = 1
	metabolic_efficiency = -1
	physiology_multipliers = list("burn_taken_mod" = 0.45)
	gameplay_traits = list(TRAIT_RESISTHEAT)
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "fire_resistance"

/datum/rw_xenogene/resistance/fire_weakness
	id = RW_XENOGENE_FIRE_WEAKNESS
	name = "Fire weakness"
	desc = "More vulnerable to fire."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	physiology_multipliers = list("burn_taken_mod" = 1.7)
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "fire_weakness"

/datum/rw_xenogene/resistance/vacuum_resistant
	id = RW_XENOGENE_VACUUM_RESISTANT
	name = "Vacuum resistant"
	desc = "Resistant to vacuum exposure."
	complexity = 1
	metabolic_efficiency = -1
	gameplay_traits = list(TRAIT_RESISTLOWPRESSURE)
	ui_icon = RW_XENOGENE_ICONS
	icon_bg = "bg"
	icon_state = "vacuum_resistant"

/datum/rw_xenogene/resistance/on_life(seconds_per_tick, mob/living/new_holder)
	if(uv_burn <= 0)
		return
	var/turf/here = get_turf(new_holder)
	var/area/here_area = get_area(here)
	if(here_area?.outdoors && here?.get_lumcount() >= 0.25)
		new_holder.apply_damage(uv_burn * seconds_per_tick, BURN, BODY_ZONE_CHEST)
