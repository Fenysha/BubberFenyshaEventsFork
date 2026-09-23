/datum/species
	/// Rimworld xenogenes that are inherently possessed by this species.
	/// These cannot be manually removed while this species is active.
	var/list/rw_innate_xenogenes = list()


/datum/species/on_species_gain(mob/living/carbon/human/human_who_gained_species, datum/species/old_species, pref_load, regenerate_icons = TRUE, replace_missing = TRUE)
	if(length(rw_innate_xenogenes))
		for(var/gene_id in rw_innate_xenogenes)
			human_who_gained_species.dna.add_rw_xenogene(
				gene_id,
				TRUE,
				RW_XENOGEN_SOURCE_INNATE
			)
	..()


/datum/species/on_species_loss(mob/living/carbon/human/human, datum/species/new_species, pref_load)
	if(length(rw_innate_xenogenes))
		for(var/gene_id in rw_innate_xenogenes)
			human.dna.remove_rw_xenogene(
				gene_id,
				RW_XENOGEN_SOURCE_INNATE
			)
	..()
