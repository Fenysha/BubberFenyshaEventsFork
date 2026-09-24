/datum/species
	/// Short race-picker title. Falls back to name.
	var/rw_label
	/// Optional subtitle under the race-picker title.
	var/rw_subtitle
	/// Rimworld xenogenes that are inherently possessed by this species.
	/// These cannot be manually removed while this species is active.
	var/list/rw_innate_xenogenes = list()
	/// Default option values for innate xenogenes, keyed by gene id.
	var/list/rw_innate_xenogene_values = list()

/datum/species/human
	rw_label = "Human"
	rw_innate_xenogenes = list(
		RW_XENOGENE_HAIR,
		RW_XENOGENE_SMOOTH_SKIN,
		RW_XENOGENE_HUMAN_EYES,
		RW_XENOGENE_LEGS,
		RW_XENOGENE_BODY_SIZE,
	)
	rw_innate_xenogene_values = list(
		RW_XENOGENE_LEGS = NORMAL_LEGS,
		RW_XENOGENE_BODY_SIZE = RESIZE_DEFAULT_SIZE,
	)

/datum/species/lizard
	rw_label = "Tiziran"
	rw_subtitle = "Lizardperson"
	rw_innate_xenogenes = list(
		RW_XENOGENE_SCALED_SKIN,
		RW_XENOGENE_LIZARD_EYES,
		RW_XENOGENE_TAIL,
		RW_XENOGENE_SNOUT,
		RW_XENOGENE_LEGS,
		RW_XENOGENE_MUTANT_COLORS,
		RW_XENOGENE_COLD_BLOODED,
		RW_XENOGENE_BODY_SIZE,
	)
	rw_innate_xenogene_values = list(
		RW_XENOGENE_TAIL = "Smooth",
		RW_XENOGENE_SNOUT = "Sharp + Light",
		RW_XENOGENE_LEGS = DIGITIGRADE_LEGS,
		RW_XENOGENE_BODY_SIZE = RESIZE_DEFAULT_SIZE,
	)


/datum/species/on_species_gain(mob/living/carbon/human/human_who_gained_species, datum/species/old_species, pref_load, regenerate_icons = TRUE)
	if(length(rw_innate_xenogenes) && ishuman(human_who_gained_species) && human_who_gained_species.dna && !istype(human_who_gained_species, /mob/living/carbon/human/dummy))
		for(var/gene_id in rw_innate_xenogenes)
			var/option_value
			if(islist(rw_innate_xenogene_values))
				option_value = rw_innate_xenogene_values[gene_id]
			human_who_gained_species.dna.add_rw_xenogene(gene_id, option_value, TRUE, RW_XENOGEN_SOURCE_INNATE)
	return ..(human_who_gained_species, old_species, pref_load, regenerate_icons)


/datum/species/on_species_loss(mob/living/carbon/human/human, datum/species/new_species, pref_load)
	if(length(rw_innate_xenogenes) && ishuman(human) && human.dna && !istype(human, /mob/living/carbon/human/dummy))
		for(var/gene_id in rw_innate_xenogenes)
			human.dna.remove_rw_xenogene(gene_id, RW_XENOGEN_SOURCE_INNATE)
	return ..(human, new_species, pref_load)
