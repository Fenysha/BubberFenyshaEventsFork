/datum/rw_xenogene
	abstract_type = /datum/rw_xenogene
	var/id
	var/name = "Xenogene"
	var/desc = "A xenogene stub."
	var/category = RW_XENOGENE_CATEGORY_COSMETIC
	/// Species ids this gene can paint. Empty = all RW base races.
	var/list/supported_species
	var/list/skill_bonuses

/datum/rw_xenogene/proc/is_supported(species_id)
	if(!length(supported_species))
		return TRUE
	return (species_id in supported_species)

/datum/rw_xenogene/proc/on_gain(mob/living/holder)
	return

/datum/rw_xenogene/proc/on_lose(mob/living/holder)
	return

/datum/rw_xenogene/proc/modify_skills(list/skill_levels)
	if(!skill_bonuses)
		return skill_levels
	for(var/skill_id in skill_bonuses)
		skill_levels[skill_id] = (skill_levels[skill_id] || 0) + skill_bonuses[skill_id]
	return skill_levels

/datum/rw_xenogene/cosmetic
	abstract_type = /datum/rw_xenogene/cosmetic
	category = RW_XENOGENE_CATEGORY_COSMETIC

/datum/rw_xenogene/stat
	abstract_type = /datum/rw_xenogene/stat
	category = RW_XENOGENE_CATEGORY_STAT

/datum/rw_xenogene/ability
	abstract_type = /datum/rw_xenogene/ability
	category = RW_XENOGENE_CATEGORY_ABILITY

/datum/rw_xenogene/cosmetic/vulp_ears
	id = RW_XENOGENE_VULP_EARS
	name = "Vulpkanin Ears"
	desc = "Cosmetic stub. Turns a human into something fox-shaped later."
	supported_species = list(SPECIES_HUMAN)
