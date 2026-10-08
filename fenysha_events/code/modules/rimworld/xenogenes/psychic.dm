/datum/rw_xenogene/psychic/psychically_deaf
	id = RW_XENOGENE_PSYCHICALLY_DEAF
	name = "Psychically deaf"
	desc = "Completely immune to psychic effects, positive and negative."
	complexity = 1
	metabolic_efficiency = 1
	negative = TRUE
	sets_psychic_sensitivity = TRUE
	psychic_sensitivity = 0
	incompatibility_group = RW_XENOGENE_GROUP_PSYCHIC_SENSITIVITY

/datum/rw_xenogene/psychic/psychically_dull
	id = RW_XENOGENE_PSYCHICALLY_DULL
	name = "Psychically dull"
	desc = "Reduced psychic sensitivity."
	complexity = 1
	metabolic_efficiency = 0
	sets_psychic_sensitivity = TRUE
	psychic_sensitivity = 0.5
	incompatibility_group = RW_XENOGENE_GROUP_PSYCHIC_SENSITIVITY

/datum/rw_xenogene/psychic/psy_sensitive
	id = RW_XENOGENE_PSY_SENSITIVE
	name = "Psy-sensitive"
	desc = "Increased psychic sensitivity."
	complexity = 1
	metabolic_efficiency = -1
	sets_psychic_sensitivity = TRUE
	psychic_sensitivity = 1.5
	incompatibility_group = RW_XENOGENE_GROUP_PSYCHIC_SENSITIVITY

/datum/rw_xenogene/psychic/super_psy_sensitive
	id = RW_XENOGENE_SUPER_PSY_SENSITIVE
	name = "Super psy-sensitive"
	desc = "Greatly increased psychic sensitivity."
	complexity = 2
	metabolic_efficiency = -2
	sets_psychic_sensitivity = TRUE
	psychic_sensitivity = 2
	incompatibility_group = RW_XENOGENE_GROUP_PSYCHIC_SENSITIVITY

/datum/rw_xenogene/psychic/psychic_bonding
	id = RW_XENOGENE_PSYCHIC_BONDING
	name = "Psychic bonding"
	desc = "Bonds with the first person who stands beside you. Their closeness lifts your mood; distance drags it down. Psychic deafness blocks the feeling."
	complexity = 2
	metabolic_efficiency = 0
	xenogen_flags = RW_XENOGEN_PROCESSING
	bonds_psychically = TRUE
