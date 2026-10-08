/datum/rw_xenogene/resistance/tox_resistance
	id = RW_XENOGENE_TOX_RESISTANCE
	name = "Tox resistance"
	desc = "Reduced sensitivity to toxic buildup."
	complexity = 1
	metabolic_efficiency = -1
	tox_mult = 0.45
	incompatibility_group = RW_XENOGENE_GROUP_TOX

/datum/rw_xenogene/resistance/tox_immunity
	id = RW_XENOGENE_TOX_IMMUNITY
	name = "Tox immunity"
	desc = "Immune to toxic buildup."
	complexity = 2
	metabolic_efficiency = -2
	tox_mult = 0
	gameplay_traits = list(TRAIT_TOXIMMUNE)
	incompatibility_group = RW_XENOGENE_GROUP_TOX

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

/datum/rw_xenogene/resistance/fire_resistance
	id = RW_XENOGENE_FIRE_RESISTANCE
	name = "Fire resistance"
	desc = "Resistant to fire and heat damage from flames."
	complexity = 1
	metabolic_efficiency = -1
	burn_taken_mult = 0.45
	gameplay_traits = list(TRAIT_RESISTHEAT)

/datum/rw_xenogene/resistance/fire_weakness
	id = RW_XENOGENE_FIRE_WEAKNESS
	name = "Fire weakness"
	desc = "More vulnerable to fire."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	burn_taken_mult = 1.7

/datum/rw_xenogene/resistance/vacuum_resistant
	id = RW_XENOGENE_VACUUM_RESISTANT
	name = "Vacuum resistant"
	desc = "Resistant to vacuum exposure."
	complexity = 1
	metabolic_efficiency = -1
	gameplay_traits = list(TRAIT_RESISTLOWPRESSURE)
