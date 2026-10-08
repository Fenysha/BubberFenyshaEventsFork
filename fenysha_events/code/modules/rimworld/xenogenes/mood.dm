/datum/rw_xenogene/mood/very_unhappy
	id = RW_XENOGENE_VERY_UNHAPPY
	name = "Very unhappy"
	desc = "Baseline mood greatly reduced."
	complexity = 1
	metabolic_efficiency = 2
	negative = TRUE
	mood_offset = -12
	incompatibility_group = RW_XENOGENE_GROUP_MOOD

/datum/rw_xenogene/mood/unhappy
	id = RW_XENOGENE_UNHAPPY
	name = "Unhappy"
	desc = "Baseline mood reduced."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	mood_offset = -6
	incompatibility_group = RW_XENOGENE_GROUP_MOOD

/datum/rw_xenogene/mood/happy
	id = RW_XENOGENE_HAPPY
	name = "Happy"
	desc = "Baseline mood increased."
	complexity = 1
	metabolic_efficiency = -1
	mood_offset = 6
	incompatibility_group = RW_XENOGENE_GROUP_MOOD

/datum/rw_xenogene/mood/very_happy
	id = RW_XENOGENE_VERY_HAPPY
	name = "Very happy"
	desc = "Baseline mood greatly increased."
	complexity = 2
	metabolic_efficiency = -2
	mood_offset = 12
	incompatibility_group = RW_XENOGENE_GROUP_MOOD
