GLOBAL_LIST_EMPTY(all_rw_skills)
GLOBAL_LIST_EMPTY(all_rw_xenogenes)
GLOBAL_LIST_EMPTY(all_rw_backstories)
GLOBAL_LIST_EMPTY(all_rw_traits)
GLOBAL_LIST_EMPTY(all_rw_loadout)
GLOBAL_LIST_INIT(rw_base_species, list(
	/datum/species/human,
	/datum/species/lizard,
	/datum/species/avali,
))

SUBSYSTEM_DEF(rw_character)
	name = "Rimworld Character"
	ss_flags = SS_NO_FIRE

/datum/controller/subsystem/rw_character/Initialize()
	init_singletons()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/rw_character/proc/init_singletons()
	GLOB.all_rw_skills = list()
	for(var/path in subtypesof(/datum/rw_skill))
		var/datum/rw_skill/skill = new path
		if(!skill.id)
			qdel(skill)
			continue
		GLOB.all_rw_skills[skill.id] = skill

	GLOB.all_rw_xenogenes = list()
	for(var/path in subtypesof(/datum/rw_xenogene))
		var/datum/rw_xenogene/gene = new path
		if(!gene.id)
			qdel(gene)
			continue
		GLOB.all_rw_xenogenes[gene.id] = gene

	GLOB.all_rw_backstories = list()
	for(var/path in subtypesof(/datum/rw_backstory))
		var/datum/rw_backstory/story = new path
		if(!story.id)
			qdel(story)
			continue
		GLOB.all_rw_backstories[story.id] = story

	GLOB.all_rw_traits = list()
	for(var/path in subtypesof(/datum/rw_trait))
		var/datum/rw_trait/trait = new path
		if(!trait.id)
			qdel(trait)
			continue
		GLOB.all_rw_traits[trait.id] = trait

	GLOB.all_rw_loadout = list()
	for(var/path in subtypesof(/datum/rw_loadout_item))
		var/datum/rw_loadout_item/item = new path
		if(!item.id)
			qdel(item)
			continue
		GLOB.all_rw_loadout[item.id] = item
