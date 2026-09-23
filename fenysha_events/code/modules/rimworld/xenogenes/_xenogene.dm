/datum/rw_xenogene
	abstract_type = /datum/rw_xenogene

	var/id
	var/name = "Xenogene"
	var/desc = "A xenogene stub."

	var/category = RW_XENOGENE_CATEGORY_COSMETIC
	var/xenogen_flags = NONE

	/// Sources currently keeping this xenogene on its owner.
	var/xenogen_source_flags = NONE

	var/mob/living/holder

	/// Species ids this gene can affect.
	/// Empty = all RW species.
	var/list/supported_species

	var/list/skill_bonuses


/datum/rw_xenogene/proc/is_supported(species_id)
	SHOULD_CALL_PARENT(TRUE)

	if(!length(supported_species))
		return TRUE

	return species_id in supported_species


/datum/rw_xenogene/proc/is_innate()
	return !!(xenogen_source_flags & RW_XENOGEN_SOURCE_INNATE)


/datum/rw_xenogene/proc/is_acquired()
	return !!(xenogen_source_flags & RW_XENOGEN_SOURCE_ACQUIRED)


/datum/rw_xenogene/proc/create_instance(mob/living/new_holder, source_flags = RW_XENOGEN_SOURCE_ACQUIRED)
	SHOULD_CALL_PARENT(TRUE)

	var/datum/rw_xenogene/instance = new type

	instance.holder = new_holder
	instance.xenogen_source_flags = source_flags

	if(supported_species)
		instance.supported_species = supported_species.Copy()

	if(skill_bonuses)
		instance.skill_bonuses = skill_bonuses.Copy()

	return instance


/datum/rw_xenogene/proc/on_gain(mob/living/new_holder)
	SHOULD_CALL_PARENT(TRUE)

	holder = new_holder

	if(xenogen_flags & RW_XENOGEN_PROCESSING)
		START_PROCESSING(SSxenogenes, src)

	return


/datum/rw_xenogene/proc/on_life(seconds_per_tick, mob/living/new_holder)
	SHOULD_CALL_PARENT(FALSE)

	return PROCESS_KILL


/datum/rw_xenogene/proc/on_lose(mob/living/new_holder)
	SHOULD_CALL_PARENT(TRUE)

	STOP_PROCESSING(SSxenogenes, src)
	holder = null

	return


/datum/rw_xenogene/proc/modify_skills(list/skill_levels)
	if(!skill_bonuses)
		return skill_levels

	for(var/skill_id in skill_bonuses)
		skill_levels[skill_id] = (skill_levels[skill_id] || 0) + skill_bonuses[skill_id]

	return skill_levels


/datum/rw_xenogene/Destroy()
	STOP_PROCESSING(SSxenogenes, src)
	holder = null

	return ..()


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
